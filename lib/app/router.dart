/// Navigation. Two shells live in one router: the five buyer tabs and the four
/// shop-mode tabs. Everything else is pushed on top of them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart_page.dart';
import '../features/category/category_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/legal_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/orders/order_tracking_page.dart';
import '../features/orders/orders_page.dart';
import '../features/profile/profile_page.dart';
import '../features/promotions/promotions_page.dart';
import '../features/search/search_page.dart';
import '../features/shops/shop_page.dart';
import '../features/shops/shops_page.dart';
import '../shop_mode/add_product_page.dart';
import '../shop_mode/panel_page.dart';
import '../shop_mode/promo_page.dart';
import '../shop_mode/register_page.dart';
import '../shop_mode/shop_orders_page.dart';
import '../shop_mode/shop_products_page.dart';
import '../shop_mode/shop_settings_page.dart';
import '../state/providers.dart';
import 'shell_buyer.dart';
import 'shell_shop.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Fades a page in instead of the platform slide, which suits the sheets and
/// full-screen pages of this app.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    );

GoRouter buildRouter(Ref ref) {
  final app = ref.read(appStateProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: app.state.onboarded ? '/' : '/onboarding',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final onboarded = ref.read(appStateProvider).state.onboarded;
      final path = state.matchedLocation;
      final isEntry = path == '/onboarding' || path.startsWith('/legal');
      if (!onboarded && !isEntry) return '/onboarding';
      if (onboarded && path == '/onboarding') return '/';
      return null;
    },
    errorBuilder: (context, state) => const HomePage(),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/legal/:doc',
        builder: (context, state) =>
            LegalPage(doc: state.pathParameters['doc'] ?? 'terms'),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _fade(state, const SearchPage()),
      ),
      GoRoute(
        path: '/promotions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PromotionsPage(),
      ),
      GoRoute(
        path: '/shop/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ShopPage(shopId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/category/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            CategoryPage(categoryId: state.pathParameters['id'] ?? ''),
      ),

      // ---- buyer shell ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BuyerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/shops', builder: (context, state) => const ShopsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/cart', builder: (context, state) => const CartPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => OrderTrackingPage(
                    orderId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage()),
          ]),
        ],
      ),

      // ---- shop mode ----
      GoRoute(path: '/shop-mode', redirect: (_, __) => '/shop-mode/panel'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShopShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/shop-mode/panel',
                builder: (context, state) => const ShopPanelPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/shop-mode/orders',
                builder: (context, state) => const ShopOrdersPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/shop-mode/products',
                builder: (context, state) => const ShopProductsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/shop-mode/settings',
                builder: (context, state) => const ShopSettingsPage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/shop-promo',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShopPromoPage(),
      ),
      GoRoute(
        path: '/shop-add-product',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddProductPage(),
      ),
      GoRoute(
        path: '/shop-register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShopRegisterPage(),
      ),
      GoRoute(
        path: '/shop-pending',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShopPendingPage(),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});
