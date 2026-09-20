/// The buyer-side mock server — a port of `api/mockApi.ts`.
///
/// It enforces the same server-side rules as the real API would (price, stock,
/// open state, minimum order, idempotency, rate limits, cancel-only-while-new),
/// so the screens are built against real behaviour. The shop-side API
/// (`mock_shop_api.dart`) works on the same instance, which is how an order
/// placed by the buyer shows up for the shop and back again.
library;

import 'dart:math';

import '../core/format.dart';
import '../core/geo.dart';
import '../core/ids.dart';
import '../core/search.dart';
import '../core/time.dart';
import 'mock_db.dart';
import 'models.dart';
import 'prng.dart';
import 'seed.dart';

/// Demo timeline in ms since creation. A real shop takes minutes; here a whole
/// order plays out in about 80 seconds so every status can be seen.
class Timeline {
  static const int decide = 10000;
  static const int preparing = 25000;
  static const int dispatch = 50000;
  static const int complete = 80000;
}

const String rejectReasonDemo = 'Mahsulot tugagan';

/// The buyer has 5 minutes to answer a partial-fulfilment request (TZ 5.3).
const int confirmMs = 5 * 60000;

/// An unanswered new order expires after 10 minutes (TZ 7).
const int expireMs = 10 * 60000;

const double pickupOnlyRadiusKm = 3;

class OpenState {
  const OpenState(this.isOpen, this.opensLabel);
  final bool isOpen;
  final String? opensLabel;
}

/// A merge sort that keeps the order of equal elements, like `Array.sort` in
/// modern JavaScript. `List.sort` gives no such guarantee.
List<T> stableSorted<T>(Iterable<T> input, int Function(T a, T b) compare) {
  final list = input.toList();
  final indexed = List<MapEntry<int, T>>.generate(
      list.length, (i) => MapEntry(i, list[i]));
  indexed.sort((a, b) {
    final c = compare(a.value, b.value);
    return c != 0 ? c : a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}

class MockServer {
  MockServer({
    KeyValueStore? store,
    this.latency = true,
    int? boot,
  }) : store = store ?? MemoryStore() {
    _buildSeed(boot ?? nowMs());
    db = decodeDb(this.store.read(dbKey));
    syncOverlay();
  }

  final KeyValueStore store;

  /// Tests switch the simulated network latency off.
  final bool latency;

  final Map<String, ProductRecord> products = {};
  final List<PromoRecord> promos = [];

  /// Promotions of the seed data; shop-made promotions live in the database.
  final List<PromoRecord> seedPromos = [];

  final List<SeedShop> shops = [];
  final Map<String, SeedShop> shopById = {};
  final Map<String, ShopLook> shopLook = {};

  late MockDb db;

  final Random _rnd = Random();

  int nowMs() => DateTime.now().millisecondsSinceEpoch;

  // ------------------------------------------------------------ seed

  void _buildSeed(int boot) {
    shops
      ..clear()
      ..addAll(buildSeedShops());
    shopById
      ..clear()
      ..addEntries(shops.map((s) => MapEntry(s.id, s)));
    shopLook
      ..clear()
      ..addAll(shopLookSeed);

    for (var si = 0; si < shops.length; si++) {
      final shop = shops[si];
      final r = mulberry32(1000 + si * 97);
      for (final c in catalog) {
        if (!shop.categories.contains(c.categoryId)) continue;
        final always = c.id == 'sut-1l' || c.id == 'non';
        if (!always && r() > 0.8) continue;
        final price = roundTo(
          c.basePrice * (0.92 + r() * 0.2),
          c.basePrice >= 20000 ? 1000 : 500,
        );
        final inStock = always ? true : r() > 0.1;
        final rec = ProductRecord(
          id: '${shop.id}:${c.id}',
          shopId: shop.id,
          catalogId: c.id,
          name: c.name,
          unit: c.unit,
          categoryId: c.categoryId,
          emoji: c.emoji,
          description: c.description,
          inStock: inStock,
          price: price,
        );
        products[rec.id] = rec;
        if (inStock && r() < 0.24) {
          final rounded = roundTo(price * (0.7 + r() * 0.2), 100);
          final promoPrice = min(price - 100, rounded);
          final d = r();
          int endsAt;
          if (d < 0.4) {
            endsAt = tashkentDayAt(boot, 23);
            if (endsAt - boot < 3600000) endsAt = boot + 3 * 3600000;
          } else if (d < 0.7) {
            endsAt = boot + 3 * 24 * 3600000;
          } else {
            endsAt = boot + 7 * 24 * 3600000;
          }
          final promo = PromoRecord(
            productId: rec.id,
            promoPrice: promoPrice,
            startsAt: boot - 3600000,
            endsAt: endsAt,
          );
          promos.add(promo);
          seedPromos.add(promo);
        }
      }
    }
  }

  // ------------------------------------------------------------ database

  void saveDb() {
    try {
      store.write(dbKey, encodeDb(db));
    } catch (_) {
      // Quota or a missing plugin: the in-memory copy is still correct.
    }
  }

  /// Wipes the mock server's data (used when the account is deleted).
  void resetMockDb() {
    db = MockDb();
    store.remove(activeShopKey);
    saveDb();
    // Rebuild the seed so shop edits (stock, prices, new shops) are gone too.
    products.clear();
    promos.clear();
    seedPromos.clear();
    _buildSeed(nowMs());
  }

  /// Applies what the shop app stored in the shared database (stock, prices,
  /// promotions, settings, new shops).
  void syncOverlay() {
    for (final n in db.newShops) {
      if (!shopById.containsKey(n.shop.id)) {
        shops.add(n.shop);
        shopById[n.shop.id] = n.shop;
        shopLook[n.shop.id] = n.look;
      }
    }
    db.overlay.forEach((id, o) {
      final shop = shopById[id];
      if (shop == null) return;
      final v = o.values;
      if (v['manualOpen'] is bool) shop.manualOpen = v['manualOpen'] as bool;
      if (v['delivers'] is bool) shop.delivers = v['delivers'] as bool;
      if (v['deliveryFee'] is num) {
        shop.deliveryFee = (v['deliveryFee'] as num).toInt();
      }
      if (v['minOrder'] is num) shop.minOrder = (v['minOrder'] as num).toInt();
      if (v['deliveryRadiusM'] is num) {
        shop.deliveryRadiusM = (v['deliveryRadiusM'] as num).toInt();
      }
      if (v['deliveryTimeText'] is String) {
        shop.deliveryTimeText = v['deliveryTimeText'] as String;
      }
      if (v['opensAt'] is String) shop.opensAt = v['opensAt'] as String;
      if (v['closesAt'] is String) shop.closesAt = v['closesAt'] as String;
      if (v.containsKey('sunOpensAt')) shop.sunOpensAt = v['sunOpensAt'] as String?;
      if (v.containsKey('sunClosesAt')) {
        shop.sunClosesAt = v['sunClosesAt'] as String?;
      }
      if (v['vacation'] is bool) shop.vacation = v['vacation'] as bool;
      if (v['categories'] is List) {
        shop.categories = List<String>.from(v['categories'] as List);
      }
      if (v['pending'] is bool) shop.pending = v['pending'] as bool;
    });
    for (final p in db.extra) {
      products.putIfAbsent(p.id, () => p.copy());
    }
    db.productOv.forEach((id, o) {
      final p = products[id];
      if (p == null) return;
      if (o.price != null) p.price = o.price!;
      if (o.inStock != null) p.inStock = o.inStock!;
    });
    final ended = db.promoEnded.toSet();
    final adds = db.promoAdds;
    final replaced = adds.map((a) => a.productId).toSet();
    promos
      ..clear()
      ..addAll(seedPromos.where(
          (p) => !ended.contains(p.productId) && !replaced.contains(p.productId)))
      ..addAll(adds);
  }

  List<SeedShop> visibleShops() => shops.where((s) => !s.pending).toList();

  bool isManualShop(String id) =>
      db.shopManual && (id == 'baraka' || id.startsWith('n-'));

  Future<void> delay([int? ms]) async {
    syncOverlay();
    if (!latency) return;
    await Future<void>.delayed(
      Duration(milliseconds: ms ?? (120 + _rnd.nextInt(180))),
    );
  }

  // ------------------------------------------------------------ views

  PromoRecord? activePromo(String productId, int now) {
    for (final p in promos) {
      if (p.productId == productId && p.startsAt <= now && now < p.endsAt) {
        return p;
      }
    }
    return null;
  }

  ProductView toProductView(ProductRecord p, int now) {
    final promo = activePromo(p.id, now);
    return ProductView(
      id: p.id,
      shopId: p.shopId,
      name: p.name,
      unit: p.unit,
      categoryId: p.categoryId,
      emoji: p.emoji,
      description: p.description,
      inStock: p.inStock,
      photo: photos[p.catalogId],
      regularPrice: p.price,
      price: promo != null ? promo.promoPrice : p.price,
      promo: promo == null
          ? null
          : PromoInfo(
              promoPrice: promo.promoPrice,
              regularPrice: p.price,
              discountPct: discountPct(p.price, promo.promoPrice),
              endsAt: promo.endsAt,
            ),
    );
  }

  OpenState openState(SeedShop shop, int now) {
    final tt = tashkent(now);
    final opensAt =
        tt.weekday == 6 && shop.sunOpensAt != null ? shop.sunOpensAt! : shop.opensAt;
    final closesAt = tt.weekday == 6 && shop.sunClosesAt != null
        ? shop.sunClosesAt!
        : shop.closesAt;
    final open = parseHHMM(opensAt);
    final close = parseHHMM(closesAt);
    if (!shop.manualOpen || shop.vacation) return const OpenState(false, null);
    if (tt.minutes >= open && tt.minutes < close) {
      return const OpenState(true, null);
    }
    if (tt.minutes < open) return OpenState(false, '$opensAt da ochiladi');
    return OpenState(false, 'ertaga ${shop.opensAt} da ochiladi');
  }

  int activePromoCount(String shopId, int now) {
    var n = 0;
    for (final promo in promos) {
      final p = products[promo.productId];
      if (p != null &&
          p.shopId == shopId &&
          p.inStock &&
          promo.startsAt <= now &&
          now < promo.endsAt) {
        n++;
      }
    }
    return n;
  }

  ShopView toShopView(SeedShop shop, Coords from, int now) {
    final state = openState(shop, now);
    final exactKm = haversineKm(from, Coords(shop.lat, shop.lng));
    final canDeliverHere = shop.delivers && exactKm * 1000 <= shop.deliveryRadiusM;
    final inRange =
        shop.delivers ? canDeliverHere : exactKm <= pickupOnlyRadiusKm;
    final allDay = shop.opensAt == '00:00' && shop.closesAt == '24:00';
    final look = shopLook[shop.id];
    return ShopView(
      id: shop.id,
      name: shop.name,
      type: shop.type,
      emoji: shop.emoji,
      lat: shop.lat,
      lng: shop.lng,
      delivers: shop.delivers,
      deliveryFee: shop.deliveryFee,
      minOrder: shop.minOrder,
      deliveryRadiusM: shop.deliveryRadiusM,
      deliveryTimeText: shop.deliveryTimeText,
      categories: shop.categories,
      hoursLabel: allDay ? 'Kuniga 24 soat' : '${shop.opensAt}–${shop.closesAt}',
      address: look?.address ?? '',
      logoBg: look?.bg ?? '#0E7A4A',
      icon: look?.icon ?? 'store',
      photo: look?.photo,
      isOpen: state.isOpen,
      opensLabel: state.opensLabel,
      distanceKm: distanceKm(from, Coords(shop.lat, shop.lng)),
      inRange: inRange,
      canDeliverHere: canDeliverHere,
      promoCount: activePromoCount(shop.id, now),
    );
  }

  ShopSummary summary(ShopView v) =>
      ShopSummary(v.id, v.name, v.distanceKm, v.isOpen);

  /// Open shops first, then nearest.
  int byOpenThenDistance(ShopView a, ShopView b) {
    if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
    return a.distanceKm.compareTo(b.distanceKm);
  }

  // ------------------------------------------------------------ orders

  Order manualToOrder(OrderRecord rec, int now) {
    final m = rec.manual!;
    var status = m.status;
    final history = List<StatusStamp>.from(m.history);
    if (status == OrderStatus.isNew && rec.cancelledAt != null) {
      status = OrderStatus.cancelled;
      history.add(StatusStamp(OrderStatus.cancelled, rec.cancelledAt!));
    } else if (status == OrderStatus.isNew &&
        now - rec.createdAt >= expireMs) {
      status = OrderStatus.expired;
      history.add(StatusStamp(OrderStatus.expired, rec.createdAt + expireMs));
    } else if (status == OrderStatus.confirm &&
        m.deadline != null &&
        now > m.deadline!) {
      status = OrderStatus.cancelled;
      history.add(StatusStamp(OrderStatus.cancelled, m.deadline!));
    }

    var items = rec.items;
    OrderChanges? changes;
    if (status == OrderStatus.confirm) {
      items = rec.items.map((i) {
        final q = m.availability?[i.productId] ?? i.quantity;
        return i.copyWith(quantity: q, unavailable: q == 0);
      }).toList();
      final kept = items.fold<int>(0, (n, i) => n + i.price * i.quantity);
      changes = OrderChanges(
          rec.total, kept + rec.deliveryFee, m.deadline ?? now);
    }

    final look = shopLook[rec.shopId];
    var acceptedAt = rec.createdAt;
    for (final h in history) {
      if (h.status == OrderStatus.accepted) {
        acceptedAt = h.at;
        break;
      }
    }
    final eta = rec.etaMinutes;
    return Order(
      id: rec.id,
      number: rec.number,
      buyerName: rec.buyerName,
      buyerPhone: rec.buyerPhone,
      shopId: rec.shopId,
      shopName: rec.shopName,
      shopPhone: rec.shopPhone,
      status: status,
      rejectReason: m.rejectReason,
      shopEmoji: shopById[rec.shopId]?.emoji ?? '🛒',
      shopLogoBg: look?.bg ?? '#0E7A4A',
      shopPhoto: look?.photo,
      shopAddress: look?.address ?? '',
      etaAt: (eta != null && eta != 0) ? acceptedAt + eta * 60000 : null,
      history: history,
      changes: changes,
      fulfilment: rec.fulfilment,
      address: rec.address,
      items: items,
      itemsTotal: rec.itemsTotal,
      deliveryFee: rec.deliveryFee,
      total: rec.total,
      comment: rec.comment,
      createdAt: rec.createdAt,
    );
  }

  Order toOrder(OrderRecord rec, int now) {
    if (rec.manual != null) return manualToOrder(rec, now);
    final seed = shopById[rec.shopId];
    final rejects = seed?.rejectsOrders == true;
    final partial = seed?.partialOrders == true && rec.items.length >= 2;
    // After the buyer confirms, the normal timeline continues as if the shop
    // had just accepted.
    final t0 = rec.confirmedAt != null
        ? rec.confirmedAt! - Timeline.decide
        : rec.createdAt;
    final elapsed = now - t0;
    final askAt = rec.createdAt + Timeline.decide;
    OrderStatus status;
    String? rejectReason;
    OrderChanges? changes;
    final history = <StatusStamp>[StatusStamp(OrderStatus.isNew, rec.createdAt)];
    final first = rec.items.isNotEmpty ? rec.items.first : null;

    if (rec.cancelledAt != null) {
      status = OrderStatus.cancelled;
      history.add(StatusStamp(OrderStatus.cancelled, rec.cancelledAt!));
    } else if (partial && rec.confirmedAt == null && now >= askAt) {
      history.add(StatusStamp(OrderStatus.confirm, askAt));
      if (now < askAt + confirmMs) {
        status = OrderStatus.confirm;
        changes = OrderChanges(
          rec.total,
          rec.total - (first == null ? 0 : first.price * first.quantity),
          askAt + confirmMs,
        );
      } else {
        status = OrderStatus.cancelled; // no answer in time
        history.add(StatusStamp(OrderStatus.cancelled, askAt + confirmMs));
      }
    } else if (elapsed < Timeline.decide) {
      status = OrderStatus.isNew;
    } else if (rejects) {
      status = OrderStatus.rejected;
      rejectReason = rejectReasonDemo;
      history.add(
          StatusStamp(OrderStatus.rejected, rec.createdAt + Timeline.decide));
    } else {
      final last = rec.fulfilment == Fulfilment.delivery
          ? OrderStatus.onTheWay
          : OrderStatus.ready;
      if (partial) history.add(StatusStamp(OrderStatus.confirm, askAt));
      history.add(StatusStamp(OrderStatus.accepted, t0 + Timeline.decide));
      status = OrderStatus.accepted;
      if (elapsed >= Timeline.preparing) {
        history.add(StatusStamp(OrderStatus.preparing, t0 + Timeline.preparing));
        status = OrderStatus.preparing;
      }
      if (elapsed >= Timeline.dispatch) {
        history.add(StatusStamp(last, t0 + Timeline.dispatch));
        status = last;
      }
      if (elapsed >= Timeline.complete) {
        history.add(StatusStamp(OrderStatus.completed, t0 + Timeline.complete));
        status = OrderStatus.completed;
      }
    }

    final flag =
        partial && (status == OrderStatus.confirm || rec.confirmedAt != null);
    final items = flag
        ? [
            for (var i = 0; i < rec.items.length; i++)
              i == 0 ? rec.items[i].copyWith(unavailable: true) : rec.items[i],
          ]
        : rec.items;
    final look = shopLook[rec.shopId];
    final eta = rec.etaMinutes;
    return Order(
      id: rec.id,
      number: rec.number,
      buyerName: rec.buyerName,
      buyerPhone: rec.buyerPhone,
      shopId: rec.shopId,
      shopName: rec.shopName,
      shopPhone: rec.shopPhone,
      status: status,
      rejectReason: rejectReason,
      shopEmoji: seed?.emoji ?? '🛒',
      shopLogoBg: look?.bg ?? '#0E7A4A',
      shopPhoto: look?.photo,
      shopAddress: look?.address ?? '',
      etaAt: (eta != null && eta != 0) ? t0 + eta * 60000 : null,
      history: history,
      changes: changes,
      fulfilment: rec.fulfilment,
      address: rec.address,
      items: items,
      itemsTotal: rec.itemsTotal,
      deliveryFee: rec.deliveryFee,
      total: rec.total,
      comment: rec.comment,
      createdAt: rec.createdAt,
    );
  }

  // ------------------------------------------------------------ validation

  CartValidation validate(ValidateInput input, int now) {
    final shop = shopById[input.shopId];
    if (shop == null) {
      throw ApiError(ApiErrorCode.notFound, 'Doʻkon topilmadi');
    }
    final view = toShopView(shop, input.coords, now);
    final issues = <CartIssue>[];
    final fresh = <String, FreshLine>{};

    if (!view.isOpen) issues.add(ShopClosedIssue(view.opensLabel));

    var itemsTotal = 0;
    for (final line in input.lines) {
      final rec = products[line.productId];
      if (rec == null || rec.shopId != shop.id || !rec.inStock) {
        issues.add(OutOfStockIssue(
            line.productId, line.name ?? rec?.name ?? 'Mahsulot'));
        fresh[line.productId] =
            FreshLine(line.priceAtAdd, line.priceAtAdd, false);
        continue;
      }
      final pv = toProductView(rec, now);
      fresh[rec.id] = FreshLine(pv.price, pv.regularPrice, true);
      if (pv.price != line.priceAtAdd) {
        issues.add(PriceChangedIssue(
            rec.id, rec.name, line.priceAtAdd, pv.price));
      }
      itemsTotal += pv.price * line.quantity;
    }

    if (input.fulfilment == Fulfilment.delivery) {
      if (!view.canDeliverHere) {
        issues.add(const DeliveryUnavailableIssue());
      } else if (itemsTotal < shop.minOrder) {
        issues.add(MinOrderIssue(shop.minOrder - itemsTotal));
      }
    }

    return CartValidation(issues.isEmpty, issues, fresh);
  }

  // ------------------------------------------------------------ buyer API

  Future<List<Category>> getCategories() async {
    await delay(40);
    return categories;
  }

  /// `GET /shops` — open first, then by distance; only shops in range.
  Future<List<ShopView>> getShops(Coords from) async {
    await delay();
    final now = nowMs();
    final views = visibleShops()
        .map((s) => toShopView(s, from, now))
        .where((s) => s.inRange);
    return stableSorted(views, byOpenThenDistance);
  }

  /// `GET /shops/{id}`
  Future<ShopView> getShop(String id, Coords from) async {
    await delay();
    final shop = shopById[id];
    if (shop == null || shop.pending) {
      throw ApiError(ApiErrorCode.notFound, 'Doʻkon topilmadi');
    }
    return toShopView(shop, from, nowMs());
  }

  /// `GET /shops/{id}/products` — in stock first, promotions first within.
  Future<List<ProductView>> getShopProducts(String id,
      {String? categoryId}) async {
    await delay();
    final now = nowMs();
    final views = products.values
        .where((p) =>
            p.shopId == id && (categoryId == null || p.categoryId == categoryId))
        .map((p) => toProductView(p, now));
    return stableSorted(views, (a, b) {
      if (a.inStock != b.inStock) return a.inStock ? -1 : 1;
      if ((a.promo != null) != (b.promo != null)) return a.promo != null ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  Future<List<ProductView>> getProducts(List<String> ids) async {
    await delay();
    final now = nowMs();
    final out = <ProductView>[];
    for (final id in ids) {
      final p = products[id];
      if (p != null) out.add(toProductView(p, now));
    }
    return out;
  }

  /// `GET /promotions` — active promotions of open shops in range, in stock
  /// only, biggest discount first.
  Future<List<ProductHit>> getPromotions(Coords from,
      {String? category, int? limit}) async {
    await delay();
    final now = nowMs();
    final shopViews = <String, ShopView>{
      for (final s in visibleShops()) s.id: toShopView(s, from, now),
    };
    final hits = <ProductHit>[];
    for (final promo in promos) {
      final rec = products[promo.productId];
      if (rec == null ||
          !rec.inStock ||
          (category != null && rec.categoryId != category)) {
        continue;
      }
      final shop = shopViews[rec.shopId];
      if (shop == null || !shop.inRange || !shop.isOpen) continue;
      final pv = toProductView(rec, now);
      if (pv.promo == null) continue;
      hits.add(ProductHit(pv, summary(shop)));
    }
    final sorted = stableSorted(hits,
        (a, b) => b.product.promo!.discountPct - a.product.promo!.discountPct);
    return limit != null && sorted.length > limit
        ? sorted.sublist(0, limit)
        : sorted;
  }

  /// `GET /search`
  Future<SearchResult> search(String q, Coords from,
      {SearchSort sort = SearchSort.distance}) async {
    await delay();
    final now = nowMs();
    final views = visibleShops()
        .map((s) => toShopView(s, from, now))
        .where((s) => s.inRange)
        .toList();
    final byId = {for (final v in views) v.id: v};

    final shopScored = <MapEntry<ShopView, int>>[];
    for (final v in views) {
      final score = matchScore(q, '${v.name} ${v.type}');
      if (score != null) shopScored.add(MapEntry(v, score));
    }
    final shopHits = stableSorted(shopScored, (a, b) {
      final c = a.value - b.value;
      return c != 0 ? c : byOpenThenDistance(a.key, b.key);
    }).map((e) => e.key).toList();

    final scored = <MapEntry<ProductHit, int>>[];
    for (final rec in products.values) {
      final shop = byId[rec.shopId];
      if (shop == null) continue;
      final cat = categoryName(rec.categoryId);
      final direct = matchScore(q, rec.name);
      final score = direct ?? (matchScore(q, cat) != null ? 3 : null);
      if (score == null) continue;
      scored.add(MapEntry(ProductHit(toProductView(rec, now), summary(shop)),
          score));
    }
    final productHits = stableSorted(scored, (a, b) {
      // Out-of-stock items sink; then apply the requested sort, relevance
      // breaks ties.
      final pa = a.key.product;
      final pb = b.key.product;
      if (pa.inStock != pb.inStock) return pa.inStock ? -1 : 1;
      switch (sort) {
        case SearchSort.price:
          final c = pa.price - pb.price;
          return c != 0 ? c : a.value - b.value;
        case SearchSort.discount:
          final c = (pb.promo?.discountPct ?? 0) - (pa.promo?.discountPct ?? 0);
          return c != 0 ? c : a.value - b.value;
        case SearchSort.distance:
          final c = a.key.shop.distanceKm.compareTo(b.key.shop.distanceKm);
          return c != 0 ? c : a.value - b.value;
      }
    }).map((e) => e.key).toList();

    return SearchResult(shopHits, productHits);
  }

  /// `POST /cart/validate`
  Future<CartValidation> validateCart(ValidateInput input) async {
    await delay();
    return validate(input, nowMs());
  }

  /// `POST /orders` — requires an idempotency key; a repeated key returns the
  /// same order.
  Future<Order> createOrder(
      CreateOrderInput input, String idempotencyKey) async {
    await delay(latency ? 300 + _rnd.nextInt(300) : 0);
    final now = nowMs();

    final existing = db.idempotency[idempotencyKey];
    if (existing != null) {
      for (final rec in db.orders) {
        if (rec.id == existing) return toOrder(rec, now);
      }
    }

    final recentHour =
        db.orders.where((o) => now - o.createdAt < 3600000).length;
    if (recentHour >= 5) {
      throw ApiError(ApiErrorCode.rateLimited,
          'Bir soatda 5 tadan ortiq buyurtma berib boʻlmaydi. Keyinroq urinib koʻring');
    }

    final orders30 = db.orders
        .map((o) => toOrder(o, now))
        .where((o) => now - o.createdAt < 30 * 24 * 3600000)
        .toList();
    final strikes = orders30
        .where((o) =>
            o.fulfilment == Fulfilment.pickup &&
            (o.status == OrderStatus.cancelled ||
                o.status == OrderStatus.expired))
        .length;
    if (strikes >= 3 && orders30.any((o) => o.isActive)) {
      throw ApiError(ApiErrorCode.activeOrderLimit,
          'Avvalgi buyurtmangiz yakunlangach yangisini bera olasiz');
    }

    final check = validate(
      ValidateInput(
        shopId: input.shopId,
        fulfilment: input.fulfilment,
        coords: input.coords,
        lines: input.lines,
      ),
      now,
    );
    if (!check.ok) {
      final first = check.issues.first;
      final ApiErrorCode code;
      final String message;
      if (first is ShopClosedIssue) {
        code = ApiErrorCode.shopClosed;
        message = 'Doʻkon hozir yopiq';
      } else if (first is MinOrderIssue) {
        code = ApiErrorCode.minOrderNotMet;
        message = 'Eng kam buyurtma summasiga yetmadi';
      } else if (first is DeliveryUnavailableIssue) {
        code = ApiErrorCode.deliveryUnavailable;
        message = 'Bu manzilga yetkazib berilmaydi';
      } else {
        // out_of_stock and price_changed both mean "the cart moved on".
        code = ApiErrorCode.cartChanged;
        message = 'Savatdagi mahsulotlar yoki narxlar oʻzgargan';
      }
      throw ApiError(code, message, check.issues);
    }

    final shop = shopById[input.shopId]!;
    final items = <OrderItem>[];
    for (final l in input.lines) {
      final rec = products[l.productId]!;
      final pv = toProductView(rec, now);
      items.add(OrderItem(
        productId: rec.id,
        name: rec.name,
        unit: rec.unit,
        emoji: rec.emoji,
        photo: pv.photo,
        price: pv.price,
        regularPrice: pv.regularPrice,
        quantity: l.quantity,
      ));
    }
    final itemsTotal = items.fold<int>(0, (s, i) => s + i.price * i.quantity);
    final deliveryFee =
        input.fulfilment == Fulfilment.delivery ? shop.deliveryFee : 0;
    final address = input.fulfilment == Fulfilment.delivery && input.address != null
        ? AddressSnapshot.of(input.address!)
        : null;
    final comment = input.comment.trim();

    final rec = OrderRecord(
      id: uuid(),
      number: db.nextNumber++,
      shopId: shop.id,
      shopName: shop.name,
      shopPhone: shop.phone,
      buyerName: input.buyerName,
      buyerPhone: input.buyerPhone,
      manual: isManualShop(shop.id)
          ? ManualState(
              status: OrderStatus.isNew,
              history: [StatusStamp(OrderStatus.isNew, now)],
            )
          : null,
      fulfilment: input.fulfilment,
      address: address,
      items: items,
      itemsTotal: itemsTotal,
      deliveryFee: deliveryFee,
      total: itemsTotal + deliveryFee,
      comment: comment.length > 200 ? comment.substring(0, 200) : comment,
      createdAt: now,
      cancelledAt: null,
      etaMinutes: input.fulfilment == Fulfilment.delivery
          ? parseUpperMinutes(shop.deliveryTimeText)
          : null,
    );
    db.orders.insert(0, rec);
    db.idempotency[idempotencyKey] = rec.id;
    saveDb();
    return toOrder(rec, now);
  }

  /// `GET /orders` — active first, then newest first.
  Future<List<Order>> listOrders() async {
    await delay(100);
    final now = nowMs();
    final list =
        db.orders.where((o) => !o.foreign).map((o) => toOrder(o, now));
    return stableSorted(list, (a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.createdAt - a.createdAt;
    });
  }

  /// Products of one category from every shop in range (open and closed),
  /// nearest first.
  Future<List<ProductHit>> getCategoryProducts(
      String categoryId, Coords from) async {
    await delay();
    final now = nowMs();
    final shopViews = <String, ShopView>{
      for (final s in visibleShops()) s.id: toShopView(s, from, now),
    };
    final hits = <ProductHit>[];
    for (final rec in products.values) {
      if (rec.categoryId != categoryId) continue;
      final shop = shopViews[rec.shopId];
      if (shop != null && shop.inRange) {
        hits.add(ProductHit(toProductView(rec, now), summary(shop)));
      }
    }
    return stableSorted(hits, (a, b) {
      final c = a.shop.distanceKm.compareTo(b.shop.distanceKm);
      return c != 0 ? c : a.product.price - b.product.price;
    });
  }

  /// `GET /orders/{id}`
  Future<Order> getOrder(String id) async {
    await delay(100);
    for (final rec in db.orders) {
      if (rec.id == id) return toOrder(rec, nowMs());
    }
    throw ApiError(ApiErrorCode.notFound, 'Buyurtma topilmadi');
  }

  /// Popular goods: for each well-known product the cheapest in-stock offer of
  /// an open shop in range.
  Future<List<ProductHit>> getPopular(Coords from) async {
    await delay();
    final now = nowMs();
    final shopViews = <String, ShopView>{
      for (final s in visibleShops()) s.id: toShopView(s, from, now),
    };
    final hits = <ProductHit>[];
    for (final catalogId in popularIds) {
      ProductHit? best;
      for (final rec in products.values) {
        if (rec.catalogId != catalogId || !rec.inStock) continue;
        final shop = shopViews[rec.shopId];
        if (shop == null || !shop.inRange || !shop.isOpen) continue;
        final pv = toProductView(rec, now);
        if (best == null || pv.price < best.product.price) {
          best = ProductHit(pv, summary(shop));
        }
      }
      if (best != null) hits.add(best);
    }
    return hits;
  }

  /// `POST /orders/{id}/confirm-changes` — accept the new total or decline
  /// (which cancels the order).
  Future<Order> confirmChanges(String id, bool accept) async {
    await delay();
    final rec = _findOrder(id);
    final now = nowMs();
    if (toOrder(rec, now).status != OrderStatus.confirm) {
      throw ApiError(
          ApiErrorCode.orderNotCancellable, 'Buyurtma holati oʻzgargan');
    }
    final m = rec.manual;
    if (m != null) {
      if (accept) {
        rec.items = rec.items
            .map((i) =>
                i.copyWith(quantity: m.availability?[i.productId] ?? i.quantity))
            .where((i) => i.quantity > 0)
            .toList();
        rec.itemsTotal =
            rec.items.fold<int>(0, (n, i) => n + i.price * i.quantity);
        rec.total = rec.itemsTotal + rec.deliveryFee;
        m.status = OrderStatus.accepted;
        m.history.add(StatusStamp(OrderStatus.accepted, now));
      } else {
        m.status = OrderStatus.cancelled;
        m.history.add(StatusStamp(OrderStatus.cancelled, now));
      }
      saveDb();
      return toOrder(rec, now);
    }
    if (accept) {
      final first = rec.items.first;
      final gone = first.price * first.quantity;
      rec.items = [
        for (var i = 0; i < rec.items.length; i++)
          i == 0 ? rec.items[i].copyWith(unavailable: true) : rec.items[i],
      ];
      rec.itemsTotal -= gone;
      rec.total -= gone;
      rec.confirmedAt = now;
    } else {
      rec.cancelledAt = now;
    }
    saveDb();
    return toOrder(rec, now);
  }

  /// `POST /orders/{id}/cancel` — allowed only while the order is still `new`.
  Future<Order> cancelOrder(String id) async {
    await delay();
    final rec = _findOrder(id);
    final now = nowMs();
    if (toOrder(rec, now).status != OrderStatus.isNew) {
      throw ApiError(ApiErrorCode.orderNotCancellable,
          'Doʻkon buyurtmani koʻrib chiqdi, endi bekor qilib boʻlmaydi');
    }
    rec.cancelledAt = now;
    saveDb();
    return toOrder(rec, now);
  }

  OrderRecord _findOrder(String id) {
    for (final rec in db.orders) {
      if (rec.id == id) return rec;
    }
    throw ApiError(ApiErrorCode.notFound, 'Buyurtma topilmadi');
  }

  /// `DELETE /me`: the mock wipes its own database.
  Future<void> deleteAccount() async {
    resetMockDb();
  }

  /// `POST /users/onboard`: nothing to send in the mock.
  Future<void> onboard() async {
    await delay(40);
  }

  /// Waitlist for districts outside the service area.
  Future<void> joinWaitlist(String district) async {
    await delay();
    db.waitlist.add(WaitlistEntry(district, nowMs()));
    saveDb();
  }
}

/// `30–40 daqiqa` → 40.
int? parseUpperMinutes(String text) {
  final matches = RegExp(r'\d+').allMatches(text).toList();
  if (matches.isEmpty) return null;
  return int.tryParse(matches.last.group(0)!);
}
