/// Everything the buyer app remembers between launches: the profile, the
/// addresses, the cart and the recent searches.
///
/// It is stored as one JSON blob next to the mock database. A broken blob is
/// discarded rather than crashing the app.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/geo.dart';
import '../core/ids.dart';
import '../data/mock_db.dart';
import '../data/models.dart';

const String appStateKey = 'yaqinda-app-state';

/// The TZ allows five saved addresses.
const int maxAddresses = 5;

/// One line can hold at most 99 units.
const int maxLineQuantity = 99;

const int maxRecentSearches = 5;

const int maxCommentLength = 200;

@immutable
class AppState {
  const AppState({
    this.onboarded = false,
    this.user = const User(),
    this.addresses = const [],
    this.activeAddressId,
    this.cart = const CartState(),
    this.recentSearches = const [],
  });

  final bool onboarded;
  final User user;
  final List<Address> addresses;
  final String? activeAddressId;
  final CartState cart;
  final List<String> recentSearches;

  Address? get activeAddress {
    if (addresses.isEmpty) return null;
    for (final a in addresses) {
      if (a.id == activeAddressId) return a;
    }
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return addresses.first;
  }

  /// Where the shop list is measured from. Without an address the demo falls
  /// back to the centre of the service area.
  Coords get coords => activeAddress?.coords ?? serviceCenter;

  bool get inServiceArea => isInServiceArea(coords);

  AppState copyWith({
    bool? onboarded,
    User? user,
    List<Address>? addresses,
    String? activeAddressId,
    CartState? cart,
    List<String>? recentSearches,
    bool clearActiveAddress = false,
  }) =>
      AppState(
        onboarded: onboarded ?? this.onboarded,
        user: user ?? this.user,
        addresses: addresses ?? this.addresses,
        activeAddressId:
            clearActiveAddress ? null : (activeAddressId ?? this.activeAddressId),
        cart: cart ?? this.cart,
        recentSearches: recentSearches ?? this.recentSearches,
      );

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'user': user.toJson(),
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'activeAddressId': activeAddressId,
        'cart': cart.toJson(),
        'recentSearches': recentSearches,
      };

  static AppState fromJson(Map<String, dynamic> j) => AppState(
        onboarded: (j['onboarded'] ?? false) as bool,
        user: j['user'] == null
            ? const User()
            : User.fromJson(Map<String, dynamic>.from(j['user'] as Map)),
        addresses: ((j['addresses'] ?? []) as List)
            .map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        activeAddressId: j['activeAddressId'] as String?,
        cart: j['cart'] == null
            ? const CartState()
            : CartState.fromJson(Map<String, dynamic>.from(j['cart'] as Map)),
        recentSearches: List<String>.from((j['recentSearches'] ?? []) as List),
      );
}

/// What happened when a product was added to the cart.
enum AddToCartResult {
  added,

  /// The cart already holds another shop's goods; ask before replacing.
  needsReplace,
}

class AppStateController extends ChangeNotifier {
  AppStateController(this.store) {
    _state = _load();
  }

  final KeyValueStore store;
  late AppState _state;

  AppState get state => _state;

  AppState _load() {
    try {
      final raw = store.read(appStateKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return AppState.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {
      // Corrupt state: start fresh rather than refusing to launch.
    }
    return const AppState();
  }

  void _set(AppState next) {
    _state = next;
    try {
      store.write(appStateKey, jsonEncode(next.toJson()));
    } catch (_) {
      // Storage is full or unavailable; the session still works in memory.
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ profile

  void setUser({String? firstName, String? phone}) {
    _set(_state.copyWith(
      user: _state.user.copyWith(firstName: firstName, phone: phone),
    ));
  }

  void finishOnboarding() => _set(_state.copyWith(onboarded: true));

  /// Wipes the profile. The mock database is reset by the caller.
  void reset() => _set(const AppState());

  // ------------------------------------------------------------ addresses

  /// Returns null when the address was saved, or the reason it was not.
  String? addAddress(Address address, {bool makeActive = true}) {
    if (_state.addresses.length >= maxAddresses) return 'max';
    final isFirst = _state.addresses.isEmpty;
    final saved = address.isDefault || isFirst
        ? address.copyWith(isDefault: true)
        : address;
    final list = [
      for (final a in _state.addresses)
        saved.isDefault ? a.copyWith(isDefault: false) : a,
      saved,
    ];
    _set(_state.copyWith(
      addresses: list,
      activeAddressId: makeActive ? saved.id : _state.activeAddressId,
    ));
    return null;
  }

  void updateAddress(Address address) {
    final list = [
      for (final a in _state.addresses) a.id == address.id ? address : a,
    ];
    _set(_state.copyWith(addresses: list));
  }

  void removeAddress(String id) {
    final list = _state.addresses.where((a) => a.id != id).toList();
    // Keep exactly one default.
    if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    final active = _state.activeAddressId == id
        ? (list.isEmpty ? null : list.first.id)
        : _state.activeAddressId;
    _set(_state.copyWith(
      addresses: list,
      activeAddressId: active,
      clearActiveAddress: list.isEmpty,
    ));
  }

  void makeDefault(String id) {
    final list = [
      for (final a in _state.addresses) a.copyWith(isDefault: a.id == id),
    ];
    _set(_state.copyWith(addresses: list, activeAddressId: id));
  }

  void setActiveAddress(String id) =>
      _set(_state.copyWith(activeAddressId: id));

  /// Builds an address from the manual form, deriving stable coordinates.
  Address buildAddress({
    String? id,
    required AddressLabel label,
    required String district,
    required String street,
    required String apartment,
    required String landmark,
    bool isDefault = false,
    Coords? detected,
  }) {
    final c = detected ?? coordsForManualAddress(district, street);
    return Address(
      id: id ?? uuid(),
      label: label,
      district: district,
      street: street,
      apartment: apartment,
      landmark: landmark,
      isDefault: isDefault,
      lat: c.lat,
      lng: c.lng,
    );
  }

  // ------------------------------------------------------------ cart

  /// Adds [quantity] units of [product]. When the cart belongs to another shop
  /// nothing is changed and [AddToCartResult.needsReplace] is returned.
  AddToCartResult addToCart(
    ProductView product,
    String shopName, {
    int quantity = 1,
    bool replace = false,
  }) {
    final cart = _state.cart;
    if (cart.shopId != null && cart.shopId != product.shopId && !replace) {
      return AddToCartResult.needsReplace;
    }
    final fresh = replace && cart.shopId != product.shopId;
    final lines = fresh ? <CartLine>[] : List<CartLine>.from(cart.lines);
    final index = lines.indexWhere((l) => l.productId == product.id);
    if (index >= 0) {
      final next = lines[index].quantity + quantity;
      lines[index] = lines[index].copyWith(
        quantity: next > maxLineQuantity ? maxLineQuantity : next,
        priceAtAdd: product.price,
        regularPrice: product.regularPrice,
      );
    } else {
      lines.add(CartLine(
        productId: product.id,
        name: product.name,
        unit: product.unit,
        emoji: product.emoji,
        photo: product.photo,
        priceAtAdd: product.price,
        regularPrice: product.regularPrice,
        quantity: quantity > maxLineQuantity ? maxLineQuantity : quantity,
      ));
    }
    _set(_state.copyWith(
      cart: cart.copyWith(
        shopId: product.shopId,
        shopName: shopName,
        lines: lines,
        clearFulfilment: fresh,
      ),
    ));
    return AddToCartResult.added;
  }

  /// A stepper set to 0 removes the line; removing the last line empties the
  /// cart so another shop can be chosen.
  void setQuantity(String productId, int quantity) {
    final cart = _state.cart;
    if (quantity <= 0) {
      final lines = cart.lines.where((l) => l.productId != productId).toList();
      if (lines.isEmpty) {
        clearCart();
        return;
      }
      _set(_state.copyWith(cart: cart.copyWith(lines: lines)));
      return;
    }
    final capped = quantity > maxLineQuantity ? maxLineQuantity : quantity;
    final lines = [
      for (final l in cart.lines)
        l.productId == productId ? l.copyWith(quantity: capped) : l,
    ];
    _set(_state.copyWith(cart: cart.copyWith(lines: lines)));
  }

  int quantityOf(String productId) {
    for (final l in _state.cart.lines) {
      if (l.productId == productId) return l.quantity;
    }
    return 0;
  }

  void clearCart() => _set(_state.copyWith(
        cart: const CartState(),
      ));

  void setFulfilment(Fulfilment f) =>
      _set(_state.copyWith(cart: _state.cart.copyWith(fulfilment: f)));

  void setComment(String comment) {
    final trimmed = comment.length > maxCommentLength
        ? comment.substring(0, maxCommentLength)
        : comment;
    _set(_state.copyWith(cart: _state.cart.copyWith(comment: trimmed)));
  }

  /// Applies the fresh prices and stock returned by `validateCart`.
  void refreshCart(Map<String, FreshLine> fresh) {
    final lines = <CartLine>[];
    for (final l in _state.cart.lines) {
      final f = fresh[l.productId];
      if (f == null) {
        lines.add(l);
        continue;
      }
      if (!f.inStock) continue; // drop what the shop no longer has
      lines.add(l.copyWith(priceAtAdd: f.price, regularPrice: f.regularPrice));
    }
    if (lines.isEmpty) {
      clearCart();
      return;
    }
    _set(_state.copyWith(cart: _state.cart.copyWith(lines: lines)));
  }

  /// Puts the still-available items of a completed order back into the cart.
  /// Returns how many lines were added and how many were skipped.
  ({int added, int missing}) repeatOrder(
      Order order, List<ProductView> current) {
    final byId = {for (final p in current) p.id: p};
    final lines = <CartLine>[];
    var missing = 0;
    for (final item in order.items) {
      final p = byId[item.productId];
      if (p == null || !p.inStock) {
        missing++;
        continue;
      }
      lines.add(CartLine(
        productId: p.id,
        name: p.name,
        unit: p.unit,
        emoji: p.emoji,
        photo: p.photo,
        priceAtAdd: p.price,
        regularPrice: p.regularPrice,
        quantity: item.quantity > maxLineQuantity
            ? maxLineQuantity
            : item.quantity,
      ));
    }
    if (lines.isEmpty) return (added: 0, missing: missing);
    _set(_state.copyWith(
      cart: CartState(
        shopId: order.shopId,
        shopName: order.shopName,
        lines: lines,
        fulfilment: order.fulfilment,
      ),
    ));
    return (added: lines.length, missing: missing);
  }

  // ------------------------------------------------------------ searches

  void rememberSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = [q, ..._state.recentSearches.where((s) => s != q)];
    _set(_state.copyWith(
      recentSearches:
          list.length > maxRecentSearches ? list.sublist(0, maxRecentSearches) : list,
    ));
  }

  void clearRecentSearches() => _set(_state.copyWith(recentSearches: const []));
}
