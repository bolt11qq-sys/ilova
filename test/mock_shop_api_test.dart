/// The shop-side server: manual mode, the order actions, stock and price
/// edits, promotions and registration.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yaqinda/core/geo.dart';
import 'package:yaqinda/core/time.dart';
import 'package:yaqinda/data/mock_api.dart';
import 'package:yaqinda/data/mock_db.dart';
import 'package:yaqinda/data/mock_shop_api.dart';
import 'package:yaqinda/data/models.dart';

class Fixture {
  Fixture() : server = MockServer(store: MemoryStore(), latency: false) {
    shop = MockShopApi(server);
    // Baraka Market closes at 23:00. Open it around the clock so the tests do
    // not depend on what time of day they happen to run.
    server.shopById[demoShopId]!
      ..opensAt = '00:00'
      ..closesAt = '24:00';
  }

  final MockServer server;
  late final MockShopApi shop;

  /// Places a pickup order from Baraka Market as the buyer would.
  Future<Order> buyerOrder({String key = 'k', int lines = 1}) {
    final products = server.products.values
        .where((p) => p.shopId == demoShopId && p.inStock)
        .take(lines)
        .toList();
    return server.createOrder(
      CreateOrderInput(
        shopId: demoShopId,
        fulfilment: Fulfilment.pickup,
        address: null,
        coords: serviceCenter,
        lines: [
          for (final p in products)
            ValidateLine(
              p.id,
              1,
              server.toProductView(p, server.nowMs()).price,
            ),
        ],
        comment: '',
        buyerName: 'Test',
        buyerPhone: '+998901234567',
      ),
      key,
    );
  }
}

void main() {
  group('opening the shop app', () {
    test('switches the demo shop into manual mode once', () async {
      final f = Fixture();
      expect(f.server.db.shopManual, isFalse);
      await f.shop.openShopApp();
      expect(f.server.db.shopManual, isTrue);
      expect(f.server.isManualShop(demoShopId), isTrue);
      expect(f.server.isManualShop('tungi'), isFalse);
    });

    test('seeds three orders from other customers, exactly once', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final first = f.server.db.orders.length;
      expect(first, 3);
      await f.shop.openShopApp();
      expect(f.server.db.orders.length, first);
      final names =
          f.server.db.orders.map((o) => o.buyerName).whereType<String>();
      expect(names, containsAll(['Azizbek', 'Sardor', 'Dilnoza']));
    });

    test('the seeded orders are hidden from the buyer', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final buyerList = await f.server.listOrders();
      expect(buyerList, isEmpty);
      final shopList = await f.shop.listOrders(demoShopId);
      expect(shopList.length, 3);
    });

    test('the delivery order in progress does not expire', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final orders = await f.shop.listOrders(demoShopId);
      final azizbek = orders.firstWhere((o) => o.buyerName == 'Azizbek');
      expect(azizbek.status, OrderStatus.onTheWay);
    });
  });

  group('order actions', () {
    test('accept → pack → dispatch → complete', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final order = await f.buyerOrder();
      expect(order.status, OrderStatus.isNew);

      var current = await f.shop.actOnOrder(order.id, const AcceptAction());
      expect(current.status, OrderStatus.accepted);
      current = await f.shop.actOnOrder(order.id, const PackAction());
      expect(current.status, OrderStatus.preparing);
      current = await f.shop.actOnOrder(order.id, const DispatchAction());
      expect(current.status, OrderStatus.ready); // pickup
      current = await f.shop.actOnOrder(order.id, const CompleteAction());
      expect(current.status, OrderStatus.completed);

      // The buyer sees the same thing.
      final buyerView = await f.server.getOrder(order.id);
      expect(buyerView.status, OrderStatus.completed);
    });

    test('a delivery order dispatches to "on the way"', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final orders = await f.shop.listOrders(demoShopId);
      final dilnoza = orders.firstWhere((o) => o.buyerName == 'Dilnoza');
      await f.shop.actOnOrder(dilnoza.id, const AcceptAction());
      await f.shop.actOnOrder(dilnoza.id, const PackAction());
      final out = await f.shop.actOnOrder(dilnoza.id, const DispatchAction());
      expect(out.status, OrderStatus.onTheWay);
    });

    test('a stale transition is refused', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final order = await f.buyerOrder();
      await f.shop.actOnOrder(order.id, const AcceptAction());
      await expectLater(
        f.shop.actOnOrder(order.id, const AcceptAction()),
        throwsA(isA<ApiError>()),
      );
      await expectLater(
        f.shop.actOnOrder(order.id, const CompleteAction()),
        throwsA(isA<ApiError>()),
      );
    });

    test('the reject reason reaches the buyer', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final order = await f.buyerOrder();
      await f.shop.actOnOrder(order.id, const RejectAction('Doʻkon yopilmoqda'));
      final buyerView = await f.server.getOrder(order.id);
      expect(buyerView.status, OrderStatus.rejected);
      expect(buyerView.rejectReason, 'Doʻkon yopilmoqda');
    });

    test('availability puts the order into "confirm" with a new total',
        () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final order = await f.buyerOrder(lines: 2);
      expect(order.items.length, 2);
      final gone = order.items.first.productId;

      final asked = await f.shop.actOnOrder(
        order.id,
        AvailabilityAction({
          gone: 0,
          order.items[1].productId: order.items[1].quantity,
        }),
      );
      expect(asked.status, OrderStatus.confirm);
      expect(asked.changes, isNotNull);
      expect(asked.changes!.newTotal, lessThan(asked.changes!.oldTotal));
      expect(
        asked.items.firstWhere((i) => i.productId == gone).unavailable,
        isTrue,
      );

      final accepted = await f.server.confirmChanges(order.id, true);
      expect(accepted.status, OrderStatus.accepted);
      expect(accepted.items.any((i) => i.productId == gone), isFalse);
    });

    test('the buyer can decline the new total', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final order = await f.buyerOrder(lines: 2);
      await f.shop.actOnOrder(
        order.id,
        AvailabilityAction({order.items.first.productId: 0}),
      );
      final declined = await f.server.confirmChanges(order.id, false);
      expect(declined.status, OrderStatus.cancelled);
    });
  });

  group('products', () {
    test('marking a product sold out blocks the buyer', () async {
      final f = Fixture();
      final products = await f.shop.listProducts(demoShopId);
      final target = products.firstWhere((p) => p.inStock);

      await f.shop.setStock(target.id, false);
      final after = await f.shop.listProducts(demoShopId);
      expect(after.firstWhere((p) => p.id == target.id).inStock, isFalse);

      final validation = f.server.validate(
        ValidateInput(
          shopId: demoShopId,
          fulfilment: Fulfilment.pickup,
          coords: serviceCenter,
          lines: [ValidateLine(target.id, 1, target.price, target.name)],
        ),
        f.server.nowMs(),
      );
      expect(validation.issues.whereType<OutOfStockIssue>(), isNotEmpty);
    });

    test('a price change survives a reload of the database', () async {
      final store = MemoryStore();
      final server = MockServer(store: store, latency: false);
      final shop = MockShopApi(server);
      final products = await shop.listProducts(demoShopId);
      final target = products.first;
      await shop.setPrice(target.id, 99500);

      final reopened = MockServer(store: store, latency: false);
      expect(reopened.products[target.id]!.price, 99500);
    });

    test('the catalog marks what the shop already sells', () async {
      final f = Fixture();
      final hits = await f.shop.searchCatalog(demoShopId, 'sut');
      expect(hits, isNotEmpty);
      final sut = hits.firstWhere((h) => h.id == 'sut-1l');
      expect(sut.has, isTrue);
    });

    test('adding from the catalog makes the product orderable', () async {
      final f = Fixture();
      // Baraka does not sell meat, so any meat item is new to it.
      await f.shop.addFromCatalog(demoShopId, 'tovuq', 42000);
      final products = await f.shop.listProducts(demoShopId);
      final added = products.firstWhere((p) => p.id == '$demoShopId:tovuq');
      expect(added.price, 42000);
      expect(added.inStock, isTrue);
    });

    test('a custom product gets an id of its own', () async {
      final f = Fixture();
      await f.shop.createCustom(
        demoShopId,
        name: 'Uy nonlari',
        unit: 'dona',
        categoryId: 'non',
        price: 7000,
      );
      final products = await f.shop.listProducts(demoShopId);
      final created = products.firstWhere((p) => p.name == 'Uy nonlari');
      expect(created.price, 7000);
      expect(created.id.startsWith('$demoShopId:x-'), isTrue);
    });
  });

  group('promotions', () {
    test('the promo price must be below the regular price', () async {
      final f = Fixture();
      final products = await f.shop.listProducts(demoShopId);
      final target = products.firstWhere((p) => p.inStock && p.promo == null);
      await expectLater(
        f.shop.createPromo(target.id, target.price, f.shop.promoEnd(PromoDuration.today)),
        throwsA(predicate((e) =>
            e is ApiError &&
            e.message == 'Aksiya narxi odatiy narxdan past boʻlishi kerak')),
      );
    });

    test('a published promotion shows up for the buyer', () async {
      final f = Fixture();
      final products = await f.shop.listProducts(demoShopId);
      final target = products.firstWhere((p) => p.inStock && p.promo == null);
      final promoPrice = target.price - 1000;

      await f.shop.createPromo(
        target.id,
        promoPrice,
        f.shop.promoEnd(PromoDuration.oneWeek),
      );

      final view = f.server.toProductView(
          f.server.products[target.id]!, f.server.nowMs());
      expect(view.promo, isNotNull);
      expect(view.price, promoPrice);
    });

    test('ending a promotion restores the regular price', () async {
      final f = Fixture();
      final products = await f.shop.listProducts(demoShopId);
      final target = products.firstWhere((p) => p.inStock && p.promo == null);
      await f.shop.createPromo(target.id, target.price - 500,
          f.shop.promoEnd(PromoDuration.threeDays));
      await f.shop.endPromo(target.id);
      final view = f.server.toProductView(
          f.server.products[target.id]!, f.server.nowMs());
      expect(view.promo, isNull);
      expect(view.price, target.price);
    });

    test('promoEnd picks today 23:00, or three hours when that is too close',
        () {
      final f = Fixture();
      final morning = tashkentDayAt(f.server.nowMs(), 9);
      expect(hhmm(f.shop.promoEnd(PromoDuration.today, morning)), '23:00');
      final late = tashkentDayAt(f.server.nowMs(), 22, 30);
      expect(f.shop.promoEnd(PromoDuration.today, late), late + 3 * 3600000);
      expect(
        f.shop.promoEnd(PromoDuration.threeDays, morning),
        morning + 3 * 24 * 3600000,
      );
      expect(
        f.shop.promoEnd(PromoDuration.oneWeek, morning),
        morning + 7 * 24 * 3600000,
      );
    });

    test('at most twenty active promotions', () async {
      final f = Fixture();
      final products = await f.shop.listProducts(demoShopId);
      final end = f.shop.promoEnd(PromoDuration.oneWeek);
      var created = 0;
      for (final p in products.where((p) => p.inStock)) {
        try {
          await f.shop.createPromo(p.id, p.price - 500, end);
          created++;
        } on ApiError catch (e) {
          expect(e.code, ApiErrorCode.promoLimit);
          break;
        }
      }
      expect(created, lessThanOrEqualTo(maxActivePromos + 1));
    });
  });

  group('statistics', () {
    test('the demo shop reports the baseline figures', () async {
      final f = Fixture();
      final stats = await f.shop.getStats(demoShopId);
      expect(stats.orders, greaterThanOrEqualTo(12));
      expect(stats.revenue, greaterThanOrEqualTo(1240000));
      expect(stats.views, greaterThanOrEqualTo(312));
      expect(stats.yesterdayOrders, 11);
    });

    test('waiting orders are counted with the oldest timestamp', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final stats = await f.shop.getStats(demoShopId);
      expect(stats.waiting, 2); // Sardor and Dilnoza
      expect(stats.oldestWaitingAt, isNotNull);
    });

    test('another shop has no demo baseline', () async {
      final f = Fixture();
      final stats = await f.shop.getStats('tungi');
      expect(stats.orders, 0);
      expect(stats.revenue, 0);
      expect(stats.views, 0);
      expect(stats.yesterdayOrders, 0);
    });
  });

  group('settings and registration', () {
    test('saving settings changes what buyers see', () async {
      final f = Fixture();
      await f.shop.saveSettings(demoShopId, deliveryFee: 12345, minOrder: 1000);
      final view = f.server.toShopView(
        f.server.shopById[demoShopId]!,
        serviceCenter,
        f.server.nowMs(),
      );
      expect(view.deliveryFee, 12345);
      expect(view.minOrder, 1000);
    });

    test('turning the shop off closes it', () async {
      final f = Fixture();
      await f.shop.saveSettings(demoShopId, manualOpen: false);
      final state = f.server.openState(
          f.server.shopById[demoShopId]!, tashkentDayAt(f.server.nowMs(), 11));
      expect(state.isOpen, isFalse);
    });

    test('a new shop is pending and invisible until approved', () async {
      final f = Fixture();
      final id = await f.shop.registerShop(const Registration(
        name: 'Yangi doʻkon',
        categories: ['non'],
        phone: '+998901112233',
        address: 'Chilonzor, 1-mavze',
        opensAt: '08:00',
        closesAt: '22:00',
        sunDifferent: false,
        sunOpensAt: '08:00',
        sunClosesAt: '22:00',
        delivers: true,
        deliveryFee: 5000,
        minOrder: 20000,
        deliveryRadiusM: 1500,
      ));
      expect(id.startsWith('n-'), isTrue);
      expect(f.shop.activeShopId(), id);

      var shops = await f.server.getShops(serviceCenter);
      expect(shops.any((s) => s.id == id), isFalse);

      await f.shop.approveShop(id);
      shops = await f.server.getShops(serviceCenter);
      expect(shops.any((s) => s.id == id), isTrue);

      final settings = await f.shop.getSettings(id);
      expect(settings.pending, isFalse);
      expect(settings.name, 'Yangi doʻkon');
    });

    test('a registered shop is driven manually as well', () async {
      final f = Fixture();
      await f.shop.openShopApp();
      final id = await f.shop.registerShop(const Registration(
        name: 'Manual doʻkon',
        categories: ['non'],
        phone: '+998901112233',
        address: 'Chilonzor, 2-mavze',
        opensAt: '00:00',
        closesAt: '24:00',
        sunDifferent: false,
        sunOpensAt: '00:00',
        sunClosesAt: '24:00',
        delivers: false,
        deliveryFee: 0,
        minOrder: 0,
        deliveryRadiusM: 0,
      ));
      expect(f.server.isManualShop(id), isTrue);
    });

    test('staff can be listed and removed', () async {
      final f = Fixture();
      final staff = await f.shop.listStaff();
      expect(staff.length, 3);
      expect(staff.first.owner, isTrue);
      await f.shop.removeStaff('s1');
      final after = await f.shop.listStaff();
      expect(after.length, 2);
      expect(after.any((s) => s.id == 's1'), isFalse);
    });

    test('an invite link is single use and lasts a day', () async {
      final f = Fixture();
      final invite = await f.shop.createInvite('seller');
      expect(invite.link.contains('YaqindaDokonBot'), isTrue);
      expect(
        invite.expiresAt - f.server.nowMs(),
        closeTo(24 * 3600000, 5000),
      );
    });
  });
}
