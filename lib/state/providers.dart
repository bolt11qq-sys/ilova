/// Riverpod wiring: one mock server, one app state, and small futures the
/// screens watch.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/geo.dart';
import '../data/mock_api.dart';
import '../data/mock_db.dart';
import '../data/mock_shop_api.dart';
import '../data/models.dart';
import 'app_state.dart';

/// `shared_preferences`, resolved once in `main` and injected here. It stays
/// null when the plugin is unavailable (widget tests, a broken install): the
/// app then keeps everything in memory for the session.
final sharedPrefsProvider = Provider<SharedPreferences?>((ref) => null);

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this.prefs);

  final SharedPreferences prefs;

  @override
  String? read(String key) {
    try {
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    try {
      prefs.setString(key, value);
    } catch (_) {
      // Ignore quota and plugin errors: the demo keeps working in memory.
    }
  }

  @override
  void remove(String key) {
    try {
      prefs.remove(key);
    } catch (_) {
      // Same as above.
    }
  }
}

final storeProvider = Provider<KeyValueStore>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs == null ? MemoryStore() : SharedPrefsStore(prefs);
});

final serverProvider = Provider<MockServer>(
  (ref) => MockServer(store: ref.watch(storeProvider)),
);

final shopApiProvider = Provider<MockShopApi>(
  (ref) => MockShopApi(ref.watch(serverProvider)),
);

final appStateProvider = ChangeNotifierProvider<AppStateController>(
  (ref) => AppStateController(ref.watch(storeProvider)),
);

// ---------------------------------------------------------------- derived

final cartProvider =
    Provider<CartState>((ref) => ref.watch(appStateProvider).state.cart);

final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).count);

final activeAddressProvider =
    Provider<Address?>((ref) => ref.watch(appStateProvider).state.activeAddress);

final coordsProvider =
    Provider<Coords>((ref) => ref.watch(appStateProvider).state.coords);

final inServiceAreaProvider =
    Provider<bool>((ref) => ref.watch(appStateProvider).state.inServiceArea);

// ---------------------------------------------------------------- data

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(serverProvider).getCategories(),
);

final shopsProvider = FutureProvider.autoDispose<List<ShopView>>(
  (ref) => ref.watch(serverProvider).getShops(ref.watch(coordsProvider)),
);

final popularProvider = FutureProvider.autoDispose<List<ProductHit>>(
  (ref) => ref.watch(serverProvider).getPopular(ref.watch(coordsProvider)),
);

/// Home shows at most ten; the Aksiyalar page asks for all of them.
final homePromotionsProvider = FutureProvider.autoDispose<List<ProductHit>>(
  (ref) => ref
      .watch(serverProvider)
      .getPromotions(ref.watch(coordsProvider), limit: 10),
);

final promotionsProvider =
    FutureProvider.autoDispose.family<List<ProductHit>, String?>(
  (ref, category) => ref
      .watch(serverProvider)
      .getPromotions(ref.watch(coordsProvider), category: category),
);

final ordersProvider = FutureProvider.autoDispose<List<Order>>(
  (ref) => ref.watch(serverProvider).listOrders(),
);

final orderProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) => ref.watch(serverProvider).getOrder(id),
);

final shopProvider = FutureProvider.autoDispose.family<ShopView, String>(
  (ref, id) =>
      ref.watch(serverProvider).getShop(id, ref.watch(coordsProvider)),
);

typedef ShopProductsKey = ({String shopId, String? categoryId});

final shopProductsProvider =
    FutureProvider.autoDispose.family<List<ProductView>, ShopProductsKey>(
  (ref, key) => ref
      .watch(serverProvider)
      .getShopProducts(key.shopId, categoryId: key.categoryId),
);

final categoryProductsProvider =
    FutureProvider.autoDispose.family<List<ProductHit>, String>(
  (ref, categoryId) => ref
      .watch(serverProvider)
      .getCategoryProducts(categoryId, ref.watch(coordsProvider)),
);

typedef SearchKey = ({String query, SearchSort sort});

final searchProvider =
    FutureProvider.autoDispose.family<SearchResult, SearchKey>(
  (ref, key) => ref
      .watch(serverProvider)
      .search(key.query, ref.watch(coordsProvider), sort: key.sort),
);

// ---------------------------------------------------------------- shop mode

/// Which shop the owner is signed in as. Changing it refreshes every shop-mode
/// screen at once.
final activeShopIdProvider = StateProvider<String>(
  (ref) => ref.watch(shopApiProvider).activeShopId(),
);

final shopOrdersProvider = FutureProvider.autoDispose<List<Order>>(
  (ref) => ref
      .watch(shopApiProvider)
      .listOrders(ref.watch(activeShopIdProvider)),
);

final shopStatsProvider = FutureProvider.autoDispose<ShopStats>(
  (ref) =>
      ref.watch(shopApiProvider).getStats(ref.watch(activeShopIdProvider)),
);

final shopProductsOwnProvider = FutureProvider.autoDispose<List<ShopProduct>>(
  (ref) => ref
      .watch(shopApiProvider)
      .listProducts(ref.watch(activeShopIdProvider)),
);

final shopSettingsProvider = FutureProvider.autoDispose<ShopSettingsData>(
  (ref) =>
      ref.watch(shopApiProvider).getSettings(ref.watch(activeShopIdProvider)),
);

final staffProvider = FutureProvider.autoDispose<List<Staff>>(
  (ref) => ref.watch(shopApiProvider).listStaff(),
);

/// Refreshes everything that reads from the mock server.
void invalidateAll(WidgetRef ref) {
  ref.invalidate(shopsProvider);
  ref.invalidate(popularProvider);
  ref.invalidate(homePromotionsProvider);
  ref.invalidate(promotionsProvider);
  ref.invalidate(ordersProvider);
  ref.invalidate(orderProvider);
  ref.invalidate(shopProvider);
  ref.invalidate(shopProductsProvider);
  ref.invalidate(categoryProductsProvider);
  ref.invalidate(searchProvider);
  ref.invalidate(shopOrdersProvider);
  ref.invalidate(shopStatsProvider);
  ref.invalidate(shopProductsOwnProvider);
  ref.invalidate(shopSettingsProvider);
}
