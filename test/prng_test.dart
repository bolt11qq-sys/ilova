/// The seed generator has to reproduce the web app's assortment bit for bit,
/// otherwise the two apps would show different shops and prices.
///
/// The expected sequences were produced by the original TypeScript
/// `mulberry32` (`node -e`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yaqinda/data/mock_db.dart';
import 'package:yaqinda/data/mock_api.dart';
import 'package:yaqinda/data/prng.dart';
import 'package:yaqinda/data/seed.dart';

void main() {
  group('mulberry32', () {
    test('matches the TypeScript sequence for seed 1000', () {
      final r = mulberry32(1000);
      const expected = [
        0.79519490688107908,
        0.82768791355192661,
        0.69151610578410327,
        0.88057521427981555,
        0.01780739263631403,
        0.42510278965346515,
      ];
      for (final value in expected) {
        expect(r(), closeTo(value, 1e-15));
      }
    });

    test('matches the sequence of the eighth shop (seed 1000 + 7 * 97)', () {
      final r = mulberry32(1000 + 7 * 97);
      const expected = [
        0.43823242001235485,
        0.30938259745016694,
        0.66479570767842233,
        0.04081460507586598,
      ];
      for (final value in expected) {
        expect(r(), closeTo(value, 1e-15));
      }
    });

    test('stays inside [0, 1)', () {
      final r = mulberry32(42);
      for (var i = 0; i < 2000; i++) {
        final v = r();
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(1));
      }
    });

    test('imul32 keeps the low 32 bits', () {
      expect(imul32(0xFFFFFFFF, 0xFFFFFFFF), 1);
      expect(imul32(3, 4), 12);
      expect(imul32(0x12345678, 0x9ABCDEF0), 0x242D2080);
    });
  });

  group('roundTo', () {
    test('rounds to the step and never below it', () {
      expect(roundTo(12345, 500), 12500);
      expect(roundTo(7, 500), 500);
      expect(roundTo(0, 1000), 1000);
      expect(roundTo(20400, 1000), 20000);
    });
  });

  group('seed determinism', () {
    test('two servers build the same assortment', () {
      final a = MockServer(store: MemoryStore(), latency: false, boot: 1);
      final b = MockServer(store: MemoryStore(), latency: false, boot: 1);
      expect(a.products.length, b.products.length);
      for (final id in a.products.keys) {
        expect(b.products.containsKey(id), isTrue, reason: id);
        expect(a.products[id]!.price, b.products[id]!.price, reason: id);
        expect(a.products[id]!.inStock, b.products[id]!.inStock, reason: id);
      }
      expect(a.promos.length, b.promos.length);
    });

    test('every shop sells sut-1l and non when it stocks that category', () {
      final server = MockServer(store: MemoryStore(), latency: false, boot: 1);
      for (final shop in server.shops) {
        if (shop.categories.contains('sut')) {
          expect(server.products['${shop.id}:sut-1l'], isNotNull);
          expect(server.products['${shop.id}:sut-1l']!.inStock, isTrue);
        }
        if (shop.categories.contains('non')) {
          expect(server.products['${shop.id}:non'], isNotNull);
          expect(server.products['${shop.id}:non']!.inStock, isTrue);
        }
      }
    });

    test('products only come from the shop\'s own categories', () {
      final server = MockServer(store: MemoryStore(), latency: false, boot: 1);
      for (final product in server.products.values) {
        final shop = server.shopById[product.shopId]!;
        expect(shop.categories.contains(product.categoryId), isTrue,
            reason: product.id);
      }
    });

    test('promo prices stay below the regular price', () {
      final server = MockServer(store: MemoryStore(), latency: false, boot: 1);
      for (final promo in server.promos) {
        final product = server.products[promo.productId]!;
        expect(promo.promoPrice, lessThan(product.price));
        expect(promo.promoPrice, greaterThan(0));
      }
    });

    test('the catalog and the shops match the brief', () {
      expect(catalog.length, 41);
      expect(categories.length, 7);
      expect(buildSeedShops().length, 8);
      expect(popularIds.length, 12);
    });
  });
}
