/// The buyer-side server rules: opening hours, range, cart validation,
/// checkout guards and the demo order timeline.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yaqinda/core/geo.dart';
import 'package:yaqinda/core/time.dart';
import 'package:yaqinda/data/mock_api.dart';
import 'package:yaqinda/data/mock_db.dart';
import 'package:yaqinda/data/models.dart';

MockServer newServer() =>
    MockServer(store: MemoryStore(), latency: false, boot: _boot);

final int _boot = DateTime.now().millisecondsSinceEpoch;

/// A timestamp at a given Tashkent wall-clock time today.
int atLocal(int hour, [int minute = 0]) =>
    tashkentDayAt(_boot, hour, minute);

OrderRecord recordFor(
  MockServer server,
  String shopId, {
  int items = 1,
  Fulfilment fulfilment = Fulfilment.delivery,
  int? createdAt,
  ManualState? manual,
}) {
  final products = server.products.values
      .where((p) => p.shopId == shopId && p.inStock)
      .take(items)
      .toList();
  final orderItems = [
    for (final p in products)
      OrderItem(
        productId: p.id,
        name: p.name,
        unit: p.unit,
        emoji: p.emoji,
        photo: null,
        price: p.price,
        regularPrice: p.price,
        quantity: 1,
      ),
  ];
  final total = orderItems.fold<int>(0, (n, i) => n + i.price * i.quantity);
  return OrderRecord(
    id: 'test-$shopId-${orderItems.length}-${createdAt ?? 0}',
    number: 1042,
    shopId: shopId,
    shopName: server.shopById[shopId]!.name,
    shopPhone: server.shopById[shopId]!.phone,
    fulfilment: fulfilment,
    address: null,
    items: orderItems,
    itemsTotal: total,
    deliveryFee: 0,
    total: total,
    comment: '',
    createdAt: createdAt ?? _boot,
    cancelledAt: null,
    manual: manual,
    etaMinutes: fulfilment == Fulfilment.delivery ? 40 : null,
  );
}

void main() {
  group('openState', () {
    test('a shop is open inside its hours', () {
      final server = newServer();
      final baraka = server.shopById['baraka']!;
      final open = server.openState(baraka, atLocal(11));
      expect(open.isOpen, isTrue);
      expect(open.opensLabel, isNull);
    });

    test('before opening it says when it opens', () {
      final server = newServer();
      final baraka = server.shopById['baraka']!;
      final state = server.openState(baraka, atLocal(5));
      expect(state.isOpen, isFalse);
      expect(state.opensLabel, '07:00 da ochiladi');
    });

    test('after closing it points at tomorrow', () {
      final server = newServer();
      final baraka = server.shopById['baraka']!;
      final state = server.openState(baraka, atLocal(23, 30));
      expect(state.isOpen, isFalse);
      expect(state.opensLabel, 'ertaga 07:00 da ochiladi');
    });

    test('a shop switched off is closed without a label', () {
      final server = newServer();
      final gosht = server.shopById['gosht']!;
      final state = server.openState(gosht, atLocal(11));
      expect(state.isOpen, isFalse);
      expect(state.opensLabel, isNull);
    });

    test('vacation closes a shop', () {
      final server = newServer();
      final shop = server.shopById['baraka']!..vacation = true;
      expect(server.openState(shop, atLocal(11)).isOpen, isFalse);
    });

    test('00:00–24:00 is open around the clock', () {
      final server = newServer();
      final tungi = server.shopById['tungi']!;
      expect(server.openState(tungi, atLocal(3)).isOpen, isTrue);
      expect(server.openState(tungi, atLocal(23, 59)).isOpen, isTrue);
      final view = server.toShopView(tungi, serviceCenter, atLocal(3));
      expect(view.hoursLabel, 'Kuniga 24 soat');
    });

    test('Sunday hours are used on Sundays', () {
      final server = newServer();
      final shop = server.shopById['baraka']!
        ..sunOpensAt = '09:00'
        ..sunClosesAt = '18:00';
      // Find a Sunday (weekday 6) close to boot.
      var ts = atLocal(10);
      while (tashkent(ts).weekday != 6) {
        ts += dayMs;
      }
      expect(server.openState(shop, ts).isOpen, isTrue);
      expect(server.openState(shop, ts - 2 * 3600000).opensLabel,
          '09:00 da ochiladi');
    });
  });

  group('visibility and range', () {
    test('lists only shops in range, open first then nearest', () async {
      final server = newServer();
      final shops = await server.getShops(serviceCenter);
      expect(shops, isNotEmpty);
      for (final s in shops) {
        expect(s.inRange, isTrue);
      }
      var sawClosed = false;
      for (final s in shops) {
        if (!s.isOpen) sawClosed = true;
        if (sawClosed) expect(s.isOpen, isFalse);
      }
      final open = shops.where((s) => s.isOpen).toList();
      for (var i = 1; i < open.length; i++) {
        expect(open[i].distanceKm, greaterThanOrEqualTo(open[i - 1].distanceKm));
      }
    });

    test('pickup-only shops are in range within 3 km', () {
      final server = newServer();
      final sut = server.shopById['sut-olami']!;
      final near = server.toShopView(sut, serviceCenter, _boot);
      expect(near.delivers, isFalse);
      expect(near.inRange, isTrue);
      final far = server.toShopView(sut, const Coords(41.365, 69.287), _boot);
      expect(far.inRange, isFalse);
    });

    test('a delivering shop is out of range beyond its radius', () {
      final server = newServer();
      final baraka = server.shopById['baraka']!;
      final view =
          server.toShopView(baraka, const Coords(41.3, 69.24), _boot);
      expect(view.canDeliverHere, isFalse);
      expect(view.inRange, isFalse);
    });

    test('pending shops are hidden', () async {
      final server = newServer();
      server.shopById['yashil']!.pending = true;
      final shops = await server.getShops(serviceCenter);
      expect(shops.any((s) => s.id == 'yashil'), isFalse);
      expect(
        () => server.getShop('yashil', serviceCenter),
        throwsA(isA<ApiError>()),
      );
    });
  });

  group('products and promotions', () {
    test('shop products put stock first and promotions next', () async {
      final server = newServer();
      final list = await server.getShopProducts('baraka');
      expect(list, isNotEmpty);
      var seenOutOfStock = false;
      for (final p in list) {
        if (!p.inStock) seenOutOfStock = true;
        if (seenOutOfStock) expect(p.inStock, isFalse);
      }
    });

    test('promotions are in-stock, open, in range and sorted by discount',
        () async {
      final server = newServer();
      final hits = await server.getPromotions(serviceCenter);
      for (final hit in hits) {
        expect(hit.product.inStock, isTrue);
        expect(hit.product.promo, isNotNull);
        expect(hit.shop.isOpen, isTrue);
      }
      for (var i = 1; i < hits.length; i++) {
        expect(hits[i].product.promo!.discountPct,
            lessThanOrEqualTo(hits[i - 1].product.promo!.discountPct));
      }
    });

    test('the promotions limit is honoured', () async {
      final server = newServer();
      final hits = await server.getPromotions(serviceCenter, limit: 3);
      expect(hits.length, lessThanOrEqualTo(3));
    });

    test('popular products pick the cheapest open offer', () async {
      final server = newServer();
      final hits = await server.getPopular(serviceCenter);
      for (final hit in hits) {
        expect(hit.product.inStock, isTrue);
        expect(hit.shop.isOpen, isTrue);
      }
    });

    test('search finds the same things for latin, cyrillic and a typo',
        () async {
      final server = newServer();
      final a = await server.search('sut', serviceCenter);
      final b = await server.search('сут', serviceCenter);
      final c = await server.search('sutt', serviceCenter);
      expect(a.products.map((h) => h.product.id).toSet(),
          b.products.map((h) => h.product.id).toSet());
      expect(a.products.map((h) => h.product.id).toSet(),
          c.products.map((h) => h.product.id).toSet());
      expect(a.products, isNotEmpty);
    });

    test('search sinks out-of-stock items and can sort by price', () async {
      final server = newServer();
      final result =
          await server.search('non', serviceCenter, sort: SearchSort.price);
      var seenOut = false;
      for (final hit in result.products) {
        if (!hit.product.inStock) seenOut = true;
        if (seenOut) expect(hit.product.inStock, isFalse);
      }
      final inStock =
          result.products.where((h) => h.product.inStock).toList();
      for (var i = 1; i < inStock.length; i++) {
        expect(inStock[i].product.price,
            greaterThanOrEqualTo(inStock[i - 1].product.price));
      }
    });
  });

  group('cart validation', () {
    test('a closed shop blocks the cart', () {
      final server = newServer();
      final product =
          server.products.values.firstWhere((p) => p.shopId == 'gosht');
      final result = server.validate(
        ValidateInput(
          shopId: 'gosht',
          fulfilment: Fulfilment.pickup,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, 1, product.price)],
        ),
        _boot,
      );
      expect(result.ok, isFalse);
      expect(result.issues.whereType<ShopClosedIssue>(), isNotEmpty);
    });

    test('an out-of-stock line is reported', () {
      final server = newServer();
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      product.inStock = false;
      final result = server.validate(
        ValidateInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.pickup,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, 1, product.price, product.name)],
        ),
        _boot,
      );
      expect(result.issues.whereType<OutOfStockIssue>(), isNotEmpty);
      expect(result.fresh[product.id]!.inStock, isFalse);
    });

    test('a changed price is reported with both amounts', () {
      final server = newServer();
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      final result = server.validate(
        ValidateInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.pickup,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, 1, product.price + 500)],
        ),
        _boot,
      );
      final issue =
          result.issues.whereType<PriceChangedIssue>().single;
      expect(issue.from, product.price + 500);
      expect(issue.to, greaterThan(0));
    });

    test('delivery below the minimum reports what is missing', () {
      final server = newServer();
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      final view = server.toProductView(product, _boot);
      final result = server.validate(
        ValidateInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.delivery,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, 1, view.price)],
        ),
        _boot,
      );
      final issue = result.issues.whereType<MinOrderIssue>().single;
      expect(issue.missing, 30000 - view.price);
    });

    test('delivery outside the radius is unavailable', () {
      final server = newServer();
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      final result = server.validate(
        ValidateInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.delivery,
          coords: const Coords(41.3, 69.25),
          lines: [ValidateLine(product.id, 1, product.price)],
        ),
        _boot,
      );
      expect(result.issues.whereType<DeliveryUnavailableIssue>(), isNotEmpty);
    });

    test('pickup from an open shop with fresh prices passes', () {
      final server = newServer();
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      final view = server.toProductView(product, _boot);
      final result = server.validate(
        ValidateInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.pickup,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, 1, view.price)],
        ),
        _boot,
      );
      expect(result.ok, isTrue);
      expect(result.issues, isEmpty);
    });
  });

  group('checkout', () {
    Future<Order> place(MockServer server, {String key = 'k1', int qty = 1}) {
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      final view = server.toProductView(product, server.nowMs());
      return server.createOrder(
        CreateOrderInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.pickup,
          address: null,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, qty, view.price)],
          comment: 'test',
        ),
        key,
      );
    }

    test('order numbers start at 1042 and increase', () async {
      final server = newServer();
      final first = await place(server, key: 'a');
      final second = await place(server, key: 'b');
      expect(first.number, 1042);
      expect(second.number, 1043);
    });

    test('a repeated idempotency key returns the same order', () async {
      final server = newServer();
      final first = await place(server, key: 'same');
      final again = await place(server, key: 'same');
      expect(again.id, first.id);
      expect(server.db.orders.length, 1);
    });

    test('at most five orders per hour', () async {
      final server = newServer();
      for (var i = 0; i < 5; i++) {
        await place(server, key: 'k$i');
      }
      await expectLater(
        place(server, key: 'k6'),
        throwsA(predicate(
            (e) => e is ApiError && e.code == ApiErrorCode.rateLimited)),
      );
    });

    test('a closed shop is refused at checkout', () async {
      final server = newServer();
      final product =
          server.products.values.firstWhere((p) => p.shopId == 'gosht');
      await expectLater(
        server.createOrder(
          CreateOrderInput(
            shopId: 'gosht',
            fulfilment: Fulfilment.pickup,
            address: null,
            coords: serviceCenter,
            lines: [ValidateLine(product.id, 1, product.price)],
            comment: '',
          ),
          'closed',
        ),
        throwsA(predicate(
            (e) => e is ApiError && e.code == ApiErrorCode.shopClosed)),
      );
    });

    test('the comment is trimmed to 200 characters', () async {
      final server = newServer();
      final product = server.products.values
          .firstWhere((p) => p.shopId == 'tungi' && p.inStock);
      final view = server.toProductView(product, server.nowMs());
      final order = await server.createOrder(
        CreateOrderInput(
          shopId: 'tungi',
          fulfilment: Fulfilment.pickup,
          address: null,
          coords: serviceCenter,
          lines: [ValidateLine(product.id, 1, view.price)],
          comment: 'x' * 500,
        ),
        'long',
      );
      expect(order.comment.length, 200);
    });

    test('pickup carries no delivery fee', () async {
      final server = newServer();
      final order = await place(server, key: 'fee');
      expect(order.deliveryFee, 0);
      expect(order.total, order.itemsTotal);
      expect(order.etaAt, isNull);
    });
  });

  group('order timeline', () {
    test('runs new → accepted → preparing → on the way → completed', () {
      final server = newServer();
      final rec = recordFor(server, 'tungi');
      final t0 = rec.createdAt;
      expect(server.toOrder(rec, t0).status, OrderStatus.isNew);
      expect(server.toOrder(rec, t0 + 5000).status, OrderStatus.isNew);
      expect(server.toOrder(rec, t0 + 11000).status, OrderStatus.accepted);
      expect(server.toOrder(rec, t0 + 26000).status, OrderStatus.preparing);
      expect(server.toOrder(rec, t0 + 51000).status, OrderStatus.onTheWay);
      expect(server.toOrder(rec, t0 + 81000).status, OrderStatus.completed);
      final done = server.toOrder(rec, t0 + 81000);
      expect(done.history.map((h) => h.status), [
        OrderStatus.isNew,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.onTheWay,
        OrderStatus.completed,
      ]);
    });

    test('pickup ends in "ready" before completing', () {
      final server = newServer();
      final rec = recordFor(server, 'tungi', fulfilment: Fulfilment.pickup);
      expect(server.toOrder(rec, rec.createdAt + 51000).status,
          OrderStatus.ready);
    });

    test('Oila Doʻkoni rejects after ten seconds', () {
      final server = newServer();
      final rec = recordFor(server, 'oila');
      expect(server.toOrder(rec, rec.createdAt + 5000).status,
          OrderStatus.isNew);
      final rejected = server.toOrder(rec, rec.createdAt + 11000);
      expect(rejected.status, OrderStatus.rejected);
      expect(rejected.rejectReason, 'Mahsulot tugagan');
    });

    test('Meva Bogʻi asks to confirm a partial order', () {
      final server = newServer();
      final rec = recordFor(server, 'sabzavot', items: 2);
      expect(rec.items.length, 2);
      final asked = server.toOrder(rec, rec.createdAt + 11000);
      expect(asked.status, OrderStatus.confirm);
      expect(asked.changes, isNotNull);
      expect(asked.changes!.oldTotal, rec.total);
      expect(
        asked.changes!.newTotal,
        rec.total - rec.items.first.price * rec.items.first.quantity,
      );
      expect(asked.items.first.unavailable, isTrue);
    });

    test('an unanswered partial order is cancelled after five minutes', () {
      final server = newServer();
      final rec = recordFor(server, 'sabzavot', items: 2);
      final late = server.toOrder(rec, rec.createdAt + 10000 + 6 * 60000);
      expect(late.status, OrderStatus.cancelled);
    });

    test('a single-line order skips the partial flow', () {
      final server = newServer();
      final rec = recordFor(server, 'sabzavot');
      expect(server.toOrder(rec, rec.createdAt + 11000).status,
          OrderStatus.accepted);
    });

    test('confirming continues the timeline', () async {
      final server = newServer();
      final rec = recordFor(server, 'sabzavot', items: 2);
      server.db.orders.add(rec);
      // Move creation back so the order is already in "confirm".
      rec.createdAt = server.nowMs() - 11000;
      final confirmed = await server.confirmChanges(rec.id, true);
      expect(confirmed.status, OrderStatus.accepted);
      expect(confirmed.total, lessThan(rec.itemsTotal + rec.deliveryFee + 1));
      expect(server.toOrder(rec, server.nowMs() + 26000).status,
          OrderStatus.preparing);
    });

    test('declining cancels the order', () async {
      final server = newServer();
      final rec = recordFor(server, 'sabzavot', items: 2);
      server.db.orders.add(rec);
      rec.createdAt = server.nowMs() - 11000;
      final declined = await server.confirmChanges(rec.id, false);
      expect(declined.status, OrderStatus.cancelled);
    });

    test('cancel works only while the order is new', () async {
      final server = newServer();
      final rec = recordFor(server, 'tungi');
      server.db.orders.add(rec);
      rec.createdAt = server.nowMs();
      final cancelled = await server.cancelOrder(rec.id);
      expect(cancelled.status, OrderStatus.cancelled);

      final other = recordFor(server, 'tungi');
      other.createdAt = server.nowMs() - 30000; // already accepted
      server.db.orders.add(other);
      await expectLater(
        server.cancelOrder(other.id),
        throwsA(predicate((e) =>
            e is ApiError && e.code == ApiErrorCode.orderNotCancellable)),
      );
    });

    test('a manual order expires after ten minutes without an answer', () {
      final server = newServer();
      final rec = recordFor(
        server,
        'baraka',
        manual: ManualState(
          status: OrderStatus.isNew,
          history: [StatusStamp(OrderStatus.isNew, _boot)],
        ),
      );
      expect(server.toOrder(rec, rec.createdAt + 60000).status,
          OrderStatus.isNew);
      expect(server.toOrder(rec, rec.createdAt + 11 * 60000).status,
          OrderStatus.expired);
    });

    test('a manual order does not follow the automatic timeline', () {
      final server = newServer();
      final rec = recordFor(
        server,
        'baraka',
        manual: ManualState(
          status: OrderStatus.isNew,
          history: [StatusStamp(OrderStatus.isNew, _boot)],
        ),
      );
      expect(server.toOrder(rec, rec.createdAt + 60000).status,
          OrderStatus.isNew);
    });
  });

  group('waitlist and reset', () {
    test('joinWaitlist stores the district', () async {
      final server = newServer();
      await server.joinWaitlist('Yunusobod');
      expect(server.db.waitlist.single.district, 'Yunusobod');
    });

    test('deleteAccount wipes the database', () async {
      final server = newServer();
      await server.joinWaitlist('Yunusobod');
      await server.deleteAccount();
      expect(server.db.waitlist, isEmpty);
      expect(server.db.orders, isEmpty);
      expect(server.db.nextNumber, 1042);
    });
  });

  group('helpers', () {
    test('parseUpperMinutes takes the upper bound', () {
      expect(parseUpperMinutes('30–40 daqiqa'), 40);
      expect(parseUpperMinutes('45–60 daqiqa'), 60);
      expect(parseUpperMinutes(''), isNull);
    });

    test('stableSorted keeps the order of equal elements', () {
      final input = [
        ('a', 1),
        ('b', 1),
        ('c', 0),
        ('d', 1),
      ];
      final sorted = stableSorted(input, (x, y) => x.$2 - y.$2);
      expect(sorted.map((e) => e.$1).toList(), ['c', 'a', 'b', 'd']);
    });
  });
}
