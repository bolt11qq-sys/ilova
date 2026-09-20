/// Smoke tests: the app starts in onboarding, a returning buyer lands on Home,
/// the bottom navigation works and the cart badge counts.
///
/// Home keeps a few looping animations alive, so these tests pump fixed
/// durations instead of `pumpAndSettle`, and tear the tree down at the end so
/// no timer outlives the test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaqinda/core/strings_buyer.dart';
import 'package:yaqinda/data/mock_api.dart';
import 'package:yaqinda/data/mock_db.dart';
import 'package:yaqinda/data/models.dart';
import 'package:yaqinda/main.dart';
import 'package:yaqinda/state/app_state.dart';
import 'package:yaqinda/state/providers.dart';

/// A store that already holds a finished onboarding.
MemoryStore onboardedStore({int cartQuantity = 0}) {
  final store = MemoryStore();
  final app = AppStateController(store);
  app.setUser(firstName: 'Karim', phone: '+998901234567');
  app.addAddress(app.buildAddress(
    label: AddressLabel.home,
    district: 'Chilonzor',
    street: 'Bunyodkor koʻchasi, 12-uy',
    apartment: '5',
    landmark: 'dorixona yonida',
    isDefault: true,
  ));
  app.finishOnboarding();
  if (cartQuantity > 0) {
    app.addToCart(
      const ProductView(
        id: 'baraka:non',
        shopId: 'baraka',
        name: 'Non',
        unit: 'dona',
        categoryId: 'non',
        emoji: '🍞',
        description: '',
        inStock: true,
        photo: null,
        regularPrice: 4000,
        price: 4000,
        promo: null,
      ),
      'Baraka Market',
      quantity: cartQuantity,
    );
  }
  return store;
}

Widget harness(MemoryStore store) => ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        serverProvider
            .overrideWith((ref) => MockServer(store: store, latency: false)),
      ],
      child: const YaqindaApp(),
    );

/// Pumps enough frames for the mock server's futures to resolve.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  testWidgets('a fresh install starts in onboarding', (tester) async {
    await tester.pumpWidget(harness(MemoryStore()));
    await settle(tester);

    expect(find.text(t('onb.welcome.title')), findsOneWidget);
    expect(find.text(t('onb.welcome.cta')), findsOneWidget);
    // The phone step is not reachable before the welcome step is confirmed.
    expect(find.text(t('onb.phone.title')), findsNothing);

    await teardown(tester);
  });

  testWidgets('the welcome step leads to the phone step', (tester) async {
    await tester.pumpWidget(harness(MemoryStore()));
    await settle(tester);

    await tester.tap(find.text(t('onb.welcome.cta')));
    await settle(tester);

    expect(find.text(t('onb.phone.title')), findsOneWidget);
    // The Telegram "share my number" button has no Android equivalent.
    expect(find.text(t('onb.phone.share')), findsNothing);

    await teardown(tester);
  });

  testWidgets('an onboarded buyer lands on Home with five tabs',
      (tester) async {
    await tester.pumpWidget(harness(onboardedStore()));
    await settle(tester);

    expect(find.text(t('h.title')), findsOneWidget);
    expect(find.text(t('h.hello')), findsOneWidget);
    for (final label in [
      t('nav.home'),
      t('nav.shops'),
      t('nav.cart'),
      t('nav.orders'),
      t('nav.profile'),
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    await teardown(tester);
  });

  testWidgets('the cart tab shows the empty state', (tester) async {
    await tester.pumpWidget(harness(onboardedStore()));
    await settle(tester);

    await tester.tap(find.text(t('nav.cart')));
    await settle(tester);

    expect(find.text(t('sv.emptyTitle')), findsOneWidget);
    expect(find.text(t('sv.emptyCta')), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('the cart badge counts the items in the cart', (tester) async {
    await tester.pumpWidget(harness(onboardedStore(cartQuantity: 3)));
    await settle(tester);

    expect(find.text('3'), findsWidgets);

    await tester.tap(find.text(t('nav.cart')));
    await settle(tester);

    expect(find.text('Non'), findsWidgets);
    expect(find.text(t('sv.how')), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('the orders tab shows its empty state', (tester) async {
    await tester.pumpWidget(harness(onboardedStore()));
    await settle(tester);

    await tester.tap(find.text(t('nav.orders')));
    await settle(tester);

    expect(find.text(t('od.emptyTitle')), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('the profile tab offers shop mode', (tester) async {
    await tester.pumpWidget(harness(onboardedStore()));
    await settle(tester);

    await tester.tap(find.text(t('nav.profile')));
    await settle(tester);

    expect(find.text('Karim'), findsOneWidget);
    expect(find.text(t('profile.unverified')), findsOneWidget);
    expect(find.text(t('pf.ownerTitle')), findsOneWidget);

    await teardown(tester);
  });
}
