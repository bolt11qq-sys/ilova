/// The rules the app itself owns: one cart per shop, the 99-unit cap, the five
/// saved addresses, the recent searches and "Takrorlash".
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yaqinda/core/geo.dart';
import 'package:yaqinda/data/mock_db.dart';
import 'package:yaqinda/data/models.dart';
import 'package:yaqinda/state/app_state.dart';

ProductView product(
  String id, {
  String shopId = 'baraka',
  int price = 10000,
  int? regular,
  bool inStock = true,
}) =>
    ProductView(
      id: id,
      shopId: shopId,
      name: id,
      unit: 'dona',
      categoryId: 'non',
      emoji: '🍞',
      description: '',
      inStock: inStock,
      photo: null,
      regularPrice: regular ?? price,
      price: price,
      promo: null,
    );

void main() {
  group('cart', () {
    test('adding from a second shop asks before replacing', () {
      final app = AppStateController(MemoryStore());
      expect(app.addToCart(product('a'), 'Baraka Market'),
          AddToCartResult.added);
      expect(
        app.addToCart(product('b', shopId: 'tungi'), 'Tungi doʻkon 24/7'),
        AddToCartResult.needsReplace,
      );
      expect(app.state.cart.shopId, 'baraka');
      expect(app.state.cart.lines.length, 1);

      expect(
        app.addToCart(product('b', shopId: 'tungi'), 'Tungi doʻkon 24/7',
            replace: true),
        AddToCartResult.added,
      );
      expect(app.state.cart.shopId, 'tungi');
      expect(app.state.cart.lines.length, 1);
      expect(app.state.cart.shopName, 'Tungi doʻkon 24/7');
    });

    test('adding the same product increases the line', () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('a'), 'Baraka Market', quantity: 2);
      app.addToCart(product('a'), 'Baraka Market', quantity: 3);
      expect(app.state.cart.lines.single.quantity, 5);
      expect(app.quantityOf('a'), 5);
    });

    test('a line never goes above 99', () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('a'), 'Baraka Market', quantity: 90);
      app.addToCart(product('a'), 'Baraka Market', quantity: 20);
      expect(app.state.cart.lines.single.quantity, maxLineQuantity);
      app.setQuantity('a', 500);
      expect(app.state.cart.lines.single.quantity, maxLineQuantity);
    });

    test('stepping to zero removes the line, the last one empties the cart',
        () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('a'), 'Baraka Market');
      app.addToCart(product('b'), 'Baraka Market');
      app.setQuantity('a', 0);
      expect(app.state.cart.lines.length, 1);
      expect(app.state.cart.shopId, 'baraka');
      app.setQuantity('b', 0);
      expect(app.state.cart.isEmpty, isTrue);
      expect(app.state.cart.shopId, isNull);
    });

    test('totals and savings', () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('a', price: 9000, regular: 12000),
          'Baraka Market', quantity: 2);
      app.addToCart(product('b', price: 5000), 'Baraka Market');
      expect(app.state.cart.itemsTotal, 9000 * 2 + 5000);
      expect(app.state.cart.savings, 3000 * 2);
      expect(app.state.cart.count, 3);
    });

    test('the comment is capped at 200 characters', () {
      final app = AppStateController(MemoryStore());
      app.setComment('x' * 400);
      expect(app.state.cart.comment.length, maxCommentLength);
    });

    test('refreshCart applies fresh prices and drops sold-out lines', () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('a', price: 9000), 'Baraka Market');
      app.addToCart(product('b', price: 5000), 'Baraka Market');
      app.refreshCart({
        'a': const FreshLine(9500, 11000, true),
        'b': const FreshLine(5000, 5000, false),
      });
      expect(app.state.cart.lines.length, 1);
      final line = app.state.cart.lines.single;
      expect(line.productId, 'a');
      expect(line.priceAtAdd, 9500);
      expect(line.regularPrice, 11000);
    });

    test('refreshing away every line empties the cart', () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('a'), 'Baraka Market');
      app.refreshCart({'a': const FreshLine(0, 0, false)});
      expect(app.state.cart.isEmpty, isTrue);
    });
  });

  group('addresses', () {
    Address make(AppStateController app, String street) => app.buildAddress(
          label: AddressLabel.home,
          district: 'Chilonzor',
          street: street,
          apartment: '',
          landmark: '',
        );

    test('the first address becomes the default and the active one', () {
      final app = AppStateController(MemoryStore());
      final a = make(app, 'Bunyodkor 12');
      expect(app.addAddress(a), isNull);
      expect(app.state.addresses.single.isDefault, isTrue);
      expect(app.state.activeAddress!.id, a.id);
      expect(app.state.coords, isNot(serviceCenter));
    });

    test('at most five addresses', () {
      final app = AppStateController(MemoryStore());
      for (var i = 0; i < maxAddresses; i++) {
        expect(app.addAddress(make(app, 'Koʻcha $i')), isNull);
      }
      expect(app.addAddress(make(app, 'Koʻcha 99')), 'max');
      expect(app.state.addresses.length, maxAddresses);
    });

    test('exactly one address is the default', () {
      final app = AppStateController(MemoryStore());
      final a = make(app, 'Bir');
      final b = make(app, 'Ikki');
      app.addAddress(a);
      app.addAddress(b);
      app.makeDefault(b.id);
      expect(app.state.addresses.where((x) => x.isDefault).length, 1);
      expect(app.state.activeAddress!.id, b.id);

      app.removeAddress(b.id);
      expect(app.state.addresses.length, 1);
      expect(app.state.addresses.single.isDefault, isTrue);
      expect(app.state.activeAddress!.id, a.id);
    });

    test('without an address the app measures from the service centre', () {
      final app = AppStateController(MemoryStore());
      expect(app.state.activeAddress, isNull);
      expect(app.state.coords, serviceCenter);
      expect(app.state.inServiceArea, isTrue);
    });
  });

  group('recent searches', () {
    test('keeps the last five, most recent first, without duplicates', () {
      final app = AppStateController(MemoryStore());
      for (final q in ['sut', 'non', 'olma', 'tuxum', 'cola', 'yog']) {
        app.rememberSearch(q);
      }
      expect(app.state.recentSearches.length, maxRecentSearches);
      expect(app.state.recentSearches.first, 'yog');
      expect(app.state.recentSearches.contains('sut'), isFalse);

      app.rememberSearch('non');
      expect(app.state.recentSearches.first, 'non');
      expect(
        app.state.recentSearches.where((q) => q == 'non').length,
        1,
      );

      app.clearRecentSearches();
      expect(app.state.recentSearches, isEmpty);
    });

    test('blank queries are ignored', () {
      final app = AppStateController(MemoryStore());
      app.rememberSearch('   ');
      expect(app.state.recentSearches, isEmpty);
    });
  });

  group('repeat order', () {
    Order orderOf(List<OrderItem> items) => Order(
          id: 'o1',
          number: 1042,
          buyerName: null,
          buyerPhone: null,
          shopId: 'baraka',
          shopName: 'Baraka Market',
          shopPhone: '+998712001122',
          status: OrderStatus.completed,
          rejectReason: null,
          shopEmoji: '🛒',
          shopLogoBg: '#12a05a',
          shopPhoto: null,
          shopAddress: '',
          etaAt: null,
          history: const [],
          changes: null,
          fulfilment: Fulfilment.delivery,
          address: null,
          items: items,
          itemsTotal: 0,
          deliveryFee: 0,
          total: 0,
          comment: '',
          createdAt: 0,
        );

    OrderItem item(String id, int quantity) => OrderItem(
          productId: id,
          name: id,
          unit: 'dona',
          emoji: '🍞',
          photo: null,
          price: 5000,
          regularPrice: 5000,
          quantity: quantity,
        );

    test('re-adds what is still available and reports what is not', () {
      final app = AppStateController(MemoryStore());
      final result = app.repeatOrder(
        orderOf([item('a', 2), item('b', 1)]),
        [product('a', price: 5500), product('b', inStock: false)],
      );
      expect(result.added, 1);
      expect(result.missing, 1);
      expect(app.state.cart.lines.single.productId, 'a');
      expect(app.state.cart.lines.single.quantity, 2);
      expect(app.state.cart.lines.single.priceAtAdd, 5500);
      expect(app.state.cart.shopId, 'baraka');
    });

    test('nothing available leaves the cart untouched', () {
      final app = AppStateController(MemoryStore());
      app.addToCart(product('keep'), 'Baraka Market');
      final result = app.repeatOrder(orderOf([item('a', 1)]), const []);
      expect(result.added, 0);
      expect(result.missing, 1);
      expect(app.state.cart.lines.single.productId, 'keep');
    });
  });

  group('persistence', () {
    test('state survives a reload from the same store', () {
      final store = MemoryStore();
      final first = AppStateController(store);
      first.setUser(firstName: 'Karim', phone: '+998901234567');
      first.finishOnboarding();
      first.addToCart(product('a'), 'Baraka Market', quantity: 3);

      final second = AppStateController(store);
      expect(second.state.onboarded, isTrue);
      expect(second.state.user.firstName, 'Karim');
      expect(second.state.user.phoneVerified, isFalse);
      expect(second.state.cart.lines.single.quantity, 3);
    });

    test('a corrupt blob starts from scratch instead of crashing', () {
      final store = MemoryStore()..write(appStateKey, 'not json at all');
      final app = AppStateController(store);
      expect(app.state.onboarded, isFalse);
      expect(app.state.cart.isEmpty, isTrue);
    });

    test('reset clears the profile', () {
      final store = MemoryStore();
      final app = AppStateController(store)
        ..setUser(firstName: 'Karim')
        ..finishOnboarding();
      app.reset();
      expect(app.state.onboarded, isFalse);
      expect(app.state.user.firstName, '');
      expect(AppStateController(store).state.onboarded, isFalse);
    });
  });
}
