/// The shop-side API of the mock server — a port of `shop/mockShopApi.ts`.
///
/// It works on the same [MockServer] instance as the buyer API, so an order
/// placed in the buyer screens shows up here and every change made here is
/// visible to buyers straight away.
library;

import 'dart:math';

import '../core/format.dart';
import '../core/ids.dart';
import '../core/search.dart';
import '../core/time.dart';
import 'mock_api.dart';
import 'mock_db.dart';
import 'models.dart';
import 'seed.dart';

const String demoShopId = 'baraka';
const int maxActivePromos = 20;

/// How long a promotion started from the "Bugun / 3 kun / 1 hafta" chips runs.
enum PromoDuration { today, threeDays, oneWeek }

class MockShopApi {
  MockShopApi(this.server);

  final MockServer server;
  final Random _rnd = Random();

  MockDb get _db => server.db;

  Future<void> _wait() =>
      server.delay(server.latency ? 90 + _rnd.nextInt(90) : 0);

  // ------------------------------------------------------- which shop is in

  String activeShopId() {
    try {
      final v = server.store.read(activeShopKey);
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // Fall through to the demo shop.
    }
    return demoShopId;
  }

  void setActiveShop(String id) {
    try {
      server.store.write(activeShopKey, id);
    } catch (_) {
      // Not being able to remember the choice is not fatal for a demo.
    }
  }

  // ------------------------------------------------------- app start

  /// Marks the shop app as the driver of orders and, once, creates a few
  /// orders from other customers so the panel is not empty at a demo.
  Future<bool> openShopApp() async {
    await _wait();
    var dirty = false;
    if (!_db.shopManual) {
      _db.shopManual = true;
      dirty = true;
    }
    if (!_db.demoSeeded) {
      _db.demoSeeded = true;
      dirty = true;
      _seedForeignOrders();
    }
    if (dirty) server.saveDb();
    return true;
  }

  void _seedForeignOrders() {
    final now = server.nowMs();
    final stocked = server.products.values
        .where((p) => p.shopId == demoShopId && p.inStock)
        .toList();

    List<ProductRecord> pick(List<String> ids, int n) {
      final chosen = <ProductRecord>[];
      for (final c in ids) {
        for (final p in stocked) {
          if (p.catalogId == c) {
            chosen.add(p);
            break;
          }
        }
      }
      for (final p in stocked) {
        if (chosen.length < n && !chosen.contains(p)) chosen.add(p);
      }
      return chosen.length > n ? chosen.sublist(0, n) : chosen;
    }

    final shop = server.shopById[demoShopId]!;

    OrderRecord make(
      String buyer,
      String phone,
      List<String> ids,
      List<int> qty,
      Fulfilment fulfilment,
      int ageMs,
      OrderStatus status, [
      String comment = '',
    ]) {
      final picked = pick(ids, qty.length);
      final items = <OrderItem>[];
      for (var i = 0; i < picked.length; i++) {
        final p = picked[i];
        items.add(OrderItem(
          productId: p.id,
          name: p.name,
          unit: p.unit,
          emoji: p.emoji,
          photo: photos[p.catalogId],
          price: p.price,
          regularPrice: p.price,
          quantity: qty[i],
        ));
      }
      final itemsTotal = items.fold<int>(0, (n, i) => n + i.price * i.quantity);
      final fee = fulfilment == Fulfilment.delivery ? shop.deliveryFee : 0;
      final createdAt = now - ageMs;
      final history = <StatusStamp>[StatusStamp(OrderStatus.isNew, createdAt)];
      if (status == OrderStatus.onTheWay) {
        history.addAll([
          StatusStamp(OrderStatus.accepted, createdAt + 60000),
          StatusStamp(OrderStatus.preparing, createdAt + 240000),
          StatusStamp(OrderStatus.onTheWay, createdAt + 600000),
        ]);
      }
      return OrderRecord(
        id: uuid(),
        number: _db.nextNumber++,
        shopId: demoShopId,
        shopName: shop.name,
        shopPhone: shop.phone,
        buyerName: buyer,
        buyerPhone: phone,
        foreign: true,
        fulfilment: fulfilment,
        address: fulfilment == Fulfilment.delivery
            ? const AddressSnapshot(
                label: AddressLabel.home,
                district: 'Chilonzor',
                street: 'Chilonzor-9, 7-uy',
                apartment: '18',
                landmark: 'dorixona yonida',
              )
            : null,
        items: items,
        itemsTotal: itemsTotal,
        deliveryFee: fee,
        total: itemsTotal + fee,
        comment: comment,
        createdAt: createdAt,
        cancelledAt: null,
        etaMinutes: fulfilment == Fulfilment.delivery ? 25 : null,
        manual: ManualState(status: status, history: history),
      );
    }

    _db.orders.insertAll(0, [
      make('Azizbek', '+998 90 123 45 67', ['patir', 'sut-1l'], [2, 1],
          Fulfilment.delivery, 15 * 60000 - 1, OrderStatus.onTheWay),
      make('Sardor', '+998 93 456 78 90', ['non', 'kefir', 'tuxum'], [2, 1, 1],
          Fulfilment.pickup, 60000, OrderStatus.isNew),
      make('Dilnoza', '+998 91 234 56 78', ['tuxum', 'makaron', 'sut-1l'],
          [1, 3, 1], Fulfilment.delivery, 3 * 60000, OrderStatus.isNew,
          'Domofon ishlamaydi, qoʻngʻiroq qiling'),
    ]);
    // The "on the way" one must not expire like a new order.
    for (final o in _db.orders) {
      if (o.manual?.status == OrderStatus.onTheWay) {
        o.createdAt = now - 15 * 60000;
      }
    }
  }

  // ------------------------------------------------------- orders

  Future<List<Order>> listOrders(String shopId) async {
    await _wait();
    final now = server.nowMs();
    final mine = _db.orders
        .where((o) => o.shopId == shopId)
        .map((o) => server.toOrder(o, now));
    return stableSorted(mine, (a, b) => b.createdAt - a.createdAt);
  }

  Future<Order> actOnOrder(String id, OrderAction action) async {
    await _wait();
    OrderRecord? rec;
    for (final o in _db.orders) {
      if (o.id == id) {
        rec = o;
        break;
      }
    }
    if (rec == null) {
      throw ApiError(ApiErrorCode.notFound, 'Buyurtma topilmadi');
    }
    final now = server.nowMs();
    final cur = server.toOrder(rec, now);
    final m = rec.manual ??=
        ManualState(status: cur.status, history: List.of(cur.history));

    ApiError stale() =>
        ApiError(ApiErrorCode.badTransition, 'Buyurtma holati oʻzgargan, yangilang');

    void to(OrderStatus status) {
      m.status = status;
      m.history.add(StatusStamp(status, now));
    }

    switch (action) {
      case AcceptAction():
        if (cur.status != OrderStatus.isNew) throw stale();
        to(OrderStatus.accepted);
      case PackAction():
        if (cur.status != OrderStatus.accepted) throw stale();
        to(OrderStatus.preparing);
      case DispatchAction():
        if (cur.status != OrderStatus.preparing) throw stale();
        to(rec.fulfilment == Fulfilment.delivery
            ? OrderStatus.onTheWay
            : OrderStatus.ready);
      case CompleteAction():
        if (cur.status != OrderStatus.onTheWay &&
            cur.status != OrderStatus.ready) {
          throw stale();
        }
        to(OrderStatus.completed);
      case RejectAction(reason: final reason):
        if (cur.status != OrderStatus.isNew) throw stale();
        m.rejectReason = reason;
        to(OrderStatus.rejected);
      case AvailabilityAction(available: final available):
        if (cur.status != OrderStatus.isNew) throw stale();
        m.availability = available;
        m.deadline = now + confirmMs;
        to(OrderStatus.confirm);
    }
    server.saveDb();
    return server.toOrder(rec, now);
  }

  // ------------------------------------------------------- products

  ShopProduct _toShopProduct(ProductRecord p, int now) {
    final promo = server.activePromo(p.id, now);
    return ShopProduct(
      id: p.id,
      name: p.name,
      unit: p.unit,
      categoryId: p.categoryId,
      emoji: p.emoji,
      photo: photos[p.catalogId],
      price: p.price,
      inStock: p.inStock,
      promo: promo == null
          ? null
          : ShopPromoInfo(promo.promoPrice, promo.endsAt,
              discountPct(p.price, promo.promoPrice)),
    );
  }

  Future<List<ShopProduct>> listProducts(String shopId) async {
    await _wait();
    final now = server.nowMs();
    final mine = server.products.values
        .where((p) => p.shopId == shopId)
        .map((p) => _toShopProduct(p, now));
    return stableSorted(
        mine, (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _patchProduct(String id, {int? price, bool? inStock}) {
    final cur = _db.productOv[id] ?? ProductOverride();
    if (price != null) cur.price = price;
    if (inStock != null) cur.inStock = inStock;
    _db.productOv[id] = cur;
    server.saveDb();
    server.syncOverlay();
  }

  Future<void> setStock(String id, bool inStock) async {
    await _wait();
    _patchProduct(id, inStock: inStock);
  }

  Future<void> setPrice(String id, int price) async {
    await _wait();
    _patchProduct(id, price: price);
  }

  Future<List<CatalogHit>> searchCatalog(String shopId, String q) async {
    await _wait();
    final nq = normalize(q);
    final have = server.products.values
        .where((p) => p.shopId == shopId)
        .map((p) => p.catalogId)
        .toSet();
    return catalog
        .where((c) =>
            nq.isEmpty ||
            normalize(c.name).contains(nq) ||
            normalize(categoryName(c.categoryId)).contains(nq))
        .map((c) => CatalogHit(
              id: c.id,
              name: c.name,
              unit: c.unit,
              categoryId: c.categoryId,
              emoji: c.emoji,
              photo: photos[c.id],
              basePrice: c.basePrice,
              has: have.contains(c.id),
            ))
        .toList();
  }

  void _addRecord(ProductRecord rec) {
    _db.extra = [..._db.extra.where((p) => p.id != rec.id), rec];
    server.products[rec.id] = rec.copy();
    server.saveDb();
  }

  Future<void> addFromCatalog(
      String shopId, String catalogId, int price) async {
    await _wait();
    CatalogItem? c;
    for (final x in catalog) {
      if (x.id == catalogId) {
        c = x;
        break;
      }
    }
    if (c == null) {
      throw ApiError(ApiErrorCode.notFound, 'Katalogda topilmadi');
    }
    _addRecord(ProductRecord(
      id: '$shopId:${c.id}',
      shopId: shopId,
      catalogId: c.id,
      name: c.name,
      unit: c.unit,
      categoryId: c.categoryId,
      emoji: c.emoji,
      description: c.description,
      inStock: true,
      price: price,
    ));
  }

  Future<void> createCustom(
    String shopId, {
    required String name,
    required Unit unit,
    required String categoryId,
    required int price,
  }) async {
    await _wait();
    var emoji = '📦';
    for (final c in catalog) {
      if (c.categoryId == categoryId) {
        emoji = c.emoji;
        break;
      }
    }
    _addRecord(ProductRecord(
      id: '$shopId:${shortId('x-')}',
      shopId: shopId,
      catalogId: 'custom',
      name: name.trim(),
      unit: unit,
      categoryId: categoryId,
      emoji: emoji,
      description: '',
      inStock: true,
      price: price,
    ));
  }

  // ------------------------------------------------------- promotions

  Future<void> createPromo(String productId, int promoPrice, int endsAt) async {
    await _wait();
    final p = server.products[productId];
    if (p == null) {
      throw ApiError(ApiErrorCode.notFound, 'Mahsulot topilmadi');
    }
    if (promoPrice >= p.price) {
      throw ApiError(ApiErrorCode.validation,
          'Aksiya narxi odatiy narxdan past boʻlishi kerak');
    }
    final now = server.nowMs();
    final others =
        _db.promoAdds.where((a) => a.productId != productId).toList();
    final activeOthers = server.products.values
        .where((x) =>
            x.shopId == p.shopId &&
            x.id != productId &&
            server.activePromo(x.id, now) != null)
        .length;
    if (activeOthers >= maxActivePromos) {
      throw ApiError(ApiErrorCode.promoLimit,
          'Bir vaqtda $maxActivePromos tadan ortiq aksiya boʻlmaydi');
    }
    _db.promoAdds = [
      ...others,
      PromoRecord(
        productId: productId,
        promoPrice: promoPrice,
        startsAt: now - 1000,
        endsAt: endsAt,
      ),
    ];
    _db.promoEnded = _db.promoEnded.where((id) => id != productId).toList();
    server.saveDb();
    server.syncOverlay();
  }

  Future<void> endPromo(String productId) async {
    await _wait();
    _db.promoAdds =
        _db.promoAdds.where((a) => a.productId != productId).toList();
    _db.promoEnded = {..._db.promoEnded, productId}.toList();
    server.saveDb();
    server.syncOverlay();
  }

  /// End of a promotion for the "Bugun / 3 kun / 1 hafta" choices.
  int promoEnd(PromoDuration kind, [int? nowOverride]) {
    final now = nowOverride ?? server.nowMs();
    final end = tashkentDayAt(now, 23);
    if (kind == PromoDuration.today) {
      return end - now < 3600000 ? now + 3 * 3600000 : end;
    }
    return now + (kind == PromoDuration.threeDays ? 3 : 7) * 24 * 3600000;
  }

  // ------------------------------------------------------- dashboard

  Future<ShopStats> getStats(String shopId) async {
    await _wait();
    final now = server.nowMs();
    final day = tashkent(now).dayIndex;
    final mine = _db.orders
        .where((o) => o.shopId == shopId)
        .map((o) => server.toOrder(o, now))
        .toList();
    final today = mine
        .where((o) =>
            tashkent(o.createdAt).dayIndex == day &&
            o.status != OrderStatus.rejected &&
            o.status != OrderStatus.expired &&
            o.status != OrderStatus.cancelled)
        .toList();
    final revenue = today.fold<int>(0, (n, o) => n + o.total);
    // Yesterday's numbers are demo figures for the seeded shop.
    final demo = shopId == demoShopId;
    final yOrders = demo ? 11 : 0;
    final yRevenue = demo ? 1120000 : 0;
    final shopProducts =
        server.products.values.where((p) => p.shopId == shopId).toList();
    final promoList = shopProducts
        .map((p) => _toShopProduct(p, now))
        .where((p) => p.promo != null && p.inStock)
        .toList();
    promoList.sort((a, b) => b.promo!.pct - a.promo!.pct);
    final waiting =
        mine.where((o) => o.status == OrderStatus.isNew).toList();
    final orders = today.length + (demo ? 12 : 0);
    return ShopStats(
      orders: orders,
      ordersDelta: orders - yOrders,
      revenue: revenue + (demo ? 1240000 : 0),
      revenueDeltaPct: yRevenue != 0
          ? ((revenue + 1240000 - yRevenue) / yRevenue * 100).round()
          : 0,
      views: demo ? 312 + today.length * 4 : 0,
      activePromos: promoList.length,
      bestPromo: promoList.isEmpty
          ? null
          : promoList.first.name.replaceAll(RegExp(r', .*'), ''),
      soldOut: shopProducts.where((p) => !p.inStock).length,
      waiting: waiting.length,
      oldestWaitingAt: waiting.isEmpty
          ? null
          : waiting.map((o) => o.createdAt).reduce((a, b) => a < b ? a : b),
      yesterdayOrders: yOrders,
    );
  }

  // ------------------------------------------------------- settings

  Future<ShopSettingsData> getSettings(String shopId) async {
    await _wait();
    final s = server.shopById[shopId];
    if (s == null) {
      throw ApiError(ApiErrorCode.notFound, 'Doʻkon topilmadi');
    }
    final look = server.shopLook[shopId];
    final overlayPending = _db.overlay[shopId]?.values['pending'];
    return ShopSettingsData(
      id: s.id,
      name: s.name,
      phone: s.phone,
      address: look?.address ?? '',
      photo: look?.photo,
      pending: overlayPending == false ? false : s.pending,
      manualOpen: s.manualOpen,
      vacation: s.vacation,
      delivers: s.delivers,
      deliveryFee: s.deliveryFee,
      minOrder: s.minOrder,
      deliveryRadiusM: s.deliveryRadiusM,
      deliveryTimeText: s.deliveryTimeText,
      opensAt: s.opensAt,
      closesAt: s.closesAt,
      sunOpensAt: s.sunOpensAt ?? s.opensAt,
      sunClosesAt: s.sunClosesAt ?? s.closesAt,
      sunDifferent: s.sunOpensAt != null,
      categories: s.categories,
    );
  }

  Future<void> saveSettings(
    String shopId, {
    String? name,
    String? phone,
    bool? manualOpen,
    bool? vacation,
    bool? delivers,
    int? deliveryFee,
    int? minOrder,
    int? deliveryRadiusM,
    String? deliveryTimeText,
    String? opensAt,
    String? closesAt,
    String? sunOpensAt,
    String? sunClosesAt,
    bool? sunDifferent,
    List<String>? categories,
  }) async {
    await _wait();
    final ov = Map<String, dynamic>.from(_db.overlay[shopId]?.values ?? {});
    void put(String key, Object? value) {
      if (value != null) ov[key] = value;
    }

    put('manualOpen', manualOpen);
    put('vacation', vacation);
    put('delivers', delivers);
    put('deliveryFee', deliveryFee);
    put('minOrder', minOrder);
    put('deliveryRadiusM', deliveryRadiusM);
    put('deliveryTimeText', deliveryTimeText);
    put('opensAt', opensAt);
    put('closesAt', closesAt);
    put('categories', categories);
    if (sunDifferent == false) {
      ov['sunOpensAt'] = null;
      ov['sunClosesAt'] = null;
    } else if (sunDifferent == true) {
      put('sunOpensAt', sunOpensAt);
      put('sunClosesAt', sunClosesAt);
    }
    _db.overlay[shopId] = ShopOverlay(ov);

    // Name and phone are not overlay fields: they live on the shop record.
    final s = server.shopById[shopId];
    if (s != null) {
      if (name != null && name.isNotEmpty) s.name = name;
      if (phone != null && phone.isNotEmpty) s.phone = phone;
      if (sunDifferent == false) {
        s.sunOpensAt = null;
        s.sunClosesAt = null;
      }
    }
    for (final reg in _db.newShops) {
      if (reg.shop.id == shopId) {
        if (name != null && name.isNotEmpty) reg.shop.name = name;
        if (phone != null && phone.isNotEmpty) reg.shop.phone = phone;
      }
    }
    server.saveDb();
    server.syncOverlay();
  }

  /// Creates a shop in "pending" status: invisible to buyers until an admin
  /// approves it.
  Future<String> registerShop(Registration r) async {
    await _wait();
    final id = shortId('n-');
    final jitter = (_rnd.nextDouble() - 0.5) * 0.006;
    final shop = SeedShop(
      id: id,
      name: r.name.trim(),
      type: 'Doʻkon',
      emoji: '🏪',
      phone: r.phone,
      lat: 41.2756 + jitter,
      lng: 69.2043 + jitter,
      delivers: r.delivers,
      deliveryFee: r.deliveryFee,
      minOrder: r.minOrder,
      deliveryRadiusM: r.deliveryRadiusM,
      deliveryTimeText: r.delivers ? '20–35 daqiqa' : '',
      opensAt: r.opensAt,
      closesAt: r.closesAt,
      manualOpen: true,
      categories: r.categories.isNotEmpty ? r.categories : ['bakaleya'],
      pending: true,
      sunOpensAt: r.sunDifferent ? r.sunOpensAt : null,
      sunClosesAt: r.sunDifferent ? r.sunClosesAt : null,
    );
    _db.newShops = [
      ..._db.newShops,
      NewShop(
        shop,
        ShopLook(
          address: r.address,
          bg: '#12a05a',
          icon: 'store',
          photo: r.photo,
        ),
      ),
    ];
    server.saveDb();
    server.syncOverlay();
    setActiveShop(id);
    return id;
  }

  /// Demo helper: what an admin would do in the admin panel.
  Future<void> approveShop(String shopId) async {
    await _wait();
    for (final reg in _db.newShops) {
      if (reg.shop.id == shopId) reg.shop.pending = false;
    }
    final ov = Map<String, dynamic>.from(_db.overlay[shopId]?.values ?? {});
    ov['pending'] = false;
    _db.overlay[shopId] = ShopOverlay(ov);
    server.saveDb();
    server.syncOverlay();
  }

  // ------------------------------------------------------- staff

  Future<List<Staff>> listStaff() async {
    await _wait();
    return _db.staff ??
        const [
          Staff('s0', 'Karim aka', 'Egasi (siz)', owner: true),
          Staff('s1', 'Jasur', 'Sotuvchi'),
          Staff('s2', 'Sardor', 'Kuryer'),
        ];
  }

  Future<void> removeStaff(String id) async {
    final list = await listStaff();
    _db.staff = list.where((s) => s.id != id).toList();
    server.saveDb();
  }

  /// Staff invitation link (24 hours, one use); the mock only makes up a code.
  Future<Invite> createInvite(String role) async {
    await _wait();
    final code = (_rnd.nextDouble() * 1e9).toInt().toRadixString(36);
    return Invite(
      't.me/YaqindaDokonBot?start=inv$code',
      server.nowMs() + 24 * 3600000,
    );
  }

  /// The shops of the signed-in user. The demo has a single shop, plus any the
  /// owner registered in this session.
  Future<List<ShopSummary>> myShops() async {
    await _wait();
    return _db.newShops
        .map((n) => ShopSummary(n.shop.id, n.shop.name, 0, !n.shop.pending))
        .toList();
  }
}
