/// Data shapes shared by the mock server, the state layer and the screens —
/// a port of `api/types.ts` and `shop/shopTypes.ts`.
///
/// Everything that has to survive a restart carries `toJson` / `fromJson`.
library;

import '../core/format.dart';
import '../core/geo.dart';

/// `dona`, `kg`, `l`, `quti` — kept as plain strings, exactly as in the seed.
typedef Unit = String;

enum Fulfilment {
  delivery('delivery'),
  pickup('pickup');

  const Fulfilment(this.wire);
  final String wire;

  static Fulfilment fromWire(String? w) =>
      w == 'pickup' ? Fulfilment.pickup : Fulfilment.delivery;
}

enum AddressLabel {
  home('home'),
  work('work'),
  other('other');

  const AddressLabel(this.wire);
  final String wire;

  static AddressLabel fromWire(String? w) => AddressLabel.values.firstWhere(
        (e) => e.wire == w,
        orElse: () => AddressLabel.home,
      );
}

enum SearchSort { distance, price, discount }

class Category {
  const Category(this.id, this.name);
  final String id;
  final String name;
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.district,
    required this.street,
    required this.apartment,
    required this.landmark,
    required this.isDefault,
    required this.lat,
    required this.lng,
  });

  final String id;
  final AddressLabel label;
  final String district;
  final String street;
  final String apartment;
  final String landmark;
  final bool isDefault;
  final double lat;
  final double lng;

  Coords get coords => Coords(lat, lng);

  /// `Chilonzor tumani, 9-mavze 12-uy`.
  String get oneLine => '$district tumani, $street';

  Address copyWith({
    AddressLabel? label,
    String? district,
    String? street,
    String? apartment,
    String? landmark,
    bool? isDefault,
    double? lat,
    double? lng,
  }) =>
      Address(
        id: id,
        label: label ?? this.label,
        district: district ?? this.district,
        street: street ?? this.street,
        apartment: apartment ?? this.apartment,
        landmark: landmark ?? this.landmark,
        isDefault: isDefault ?? this.isDefault,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label.wire,
        'district': district,
        'street': street,
        'apartment': apartment,
        'landmark': landmark,
        'isDefault': isDefault,
        'lat': lat,
        'lng': lng,
      };

  static Address fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as String,
        label: AddressLabel.fromWire(j['label'] as String?),
        district: (j['district'] ?? '') as String,
        street: (j['street'] ?? '') as String,
        apartment: (j['apartment'] ?? '') as String,
        landmark: (j['landmark'] ?? '') as String,
        isDefault: (j['isDefault'] ?? false) as bool,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

class User {
  const User({
    this.telegramId,
    this.firstName = '',
    this.phone = '',
    this.phoneVerified = false,
    this.language = 'uz_latn',
  });

  final int? telegramId;
  final String firstName;
  final String phone;

  /// Always false in the APK: `requestContact()` does not exist here.
  final bool phoneVerified;
  final String language;

  User copyWith({String? firstName, String? phone, bool? phoneVerified}) => User(
        telegramId: telegramId,
        firstName: firstName ?? this.firstName,
        phone: phone ?? this.phone,
        phoneVerified: phoneVerified ?? this.phoneVerified,
        language: language,
      );

  Map<String, dynamic> toJson() => {
        'telegramId': telegramId,
        'firstName': firstName,
        'phone': phone,
        'phoneVerified': phoneVerified,
        'language': language,
      };

  static User fromJson(Map<String, dynamic> j) => User(
        telegramId: j['telegramId'] as int?,
        firstName: (j['firstName'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        phoneVerified: (j['phoneVerified'] ?? false) as bool,
      );
}

// ---------------------------------------------------------------- shops

/// A shop as buyers see it. The phone number is deliberately absent until an
/// order exists.
class ShopView {
  const ShopView({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    required this.lat,
    required this.lng,
    required this.delivers,
    required this.deliveryFee,
    required this.minOrder,
    required this.deliveryRadiusM,
    required this.deliveryTimeText,
    required this.categories,
    required this.hoursLabel,
    required this.address,
    required this.logoBg,
    required this.icon,
    required this.photo,
    required this.isOpen,
    required this.opensLabel,
    required this.distanceKm,
    required this.inRange,
    required this.canDeliverHere,
    required this.promoCount,
  });

  final String id;
  final String name;
  final String type;
  final String emoji;
  final double lat;
  final double lng;
  final bool delivers;
  final int deliveryFee;
  final int minOrder;
  final int deliveryRadiusM;
  final String deliveryTimeText;
  final List<String> categories;
  final String hoursLabel;
  final String address;

  /// `#12a05a` — the colour of the logo circle.
  final String logoBg;

  /// Name of the white line icon drawn on the colour circle.
  final String icon;

  /// Storefront photo when the shop has one.
  final String? photo;
  final bool isOpen;

  /// `08:00 da ochiladi` style hint when closed.
  final String? opensLabel;
  final double distanceKm;

  /// False → too far for delivery (delivering shop) or for pickup (3 km).
  final bool inRange;

  /// The buyer's address is inside the shop's delivery radius.
  final bool canDeliverHere;
  final int promoCount;

  Coords get coords => Coords(lat, lng);
}

class ShopSummary {
  const ShopSummary(this.id, this.name, this.distanceKm, this.isOpen);
  final String id;
  final String name;
  final double distanceKm;
  final bool isOpen;
}

// ---------------------------------------------------------------- products

class PromoInfo {
  const PromoInfo({
    required this.promoPrice,
    required this.regularPrice,
    required this.discountPct,
    required this.endsAt,
  });

  final int promoPrice;
  final int regularPrice;
  final int discountPct;
  final int endsAt;
}

class ProductView {
  const ProductView({
    required this.id,
    required this.shopId,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.emoji,
    required this.description,
    required this.inStock,
    required this.photo,
    required this.regularPrice,
    required this.price,
    required this.promo,
  });

  final String id;
  final String shopId;
  final String name;
  final Unit unit;
  final String categoryId;
  final String emoji;
  final String description;
  final bool inStock;
  final String? photo;
  final int regularPrice;

  /// What the buyer pays right now (the promo price when one is active).
  final int price;
  final PromoInfo? promo;

  String get title => productTitle(name, unit);
}

class ProductHit {
  const ProductHit(this.product, this.shop);
  final ProductView product;
  final ShopSummary shop;
}

class SearchResult {
  const SearchResult(this.shops, this.products);
  final List<ShopView> shops;
  final List<ProductHit> products;
}

// ---------------------------------------------------------------- cart

class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unit,
    required this.emoji,
    required this.photo,
    required this.priceAtAdd,
    required this.regularPrice,
    required this.quantity,
  });

  final String productId;
  final String name;
  final Unit unit;
  final String emoji;
  final String? photo;

  /// Price when the line was added; the server re-checks at checkout.
  final int priceAtAdd;
  final int regularPrice;
  final int quantity;

  CartLine copyWith({int? quantity, int? priceAtAdd, int? regularPrice}) =>
      CartLine(
        productId: productId,
        name: name,
        unit: unit,
        emoji: emoji,
        photo: photo,
        priceAtAdd: priceAtAdd ?? this.priceAtAdd,
        regularPrice: regularPrice ?? this.regularPrice,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'unit': unit,
        'emoji': emoji,
        'photo': photo,
        'priceAtAdd': priceAtAdd,
        'regularPrice': regularPrice,
        'quantity': quantity,
      };

  static CartLine fromJson(Map<String, dynamic> j) => CartLine(
        productId: j['productId'] as String,
        name: (j['name'] ?? '') as String,
        unit: (j['unit'] ?? 'dona') as String,
        emoji: (j['emoji'] ?? '📦') as String,
        photo: j['photo'] as String?,
        priceAtAdd: (j['priceAtAdd'] as num).toInt(),
        regularPrice: (j['regularPrice'] as num).toInt(),
        quantity: (j['quantity'] as num).toInt(),
      );
}

class CartState {
  const CartState({
    this.shopId,
    this.shopName = '',
    this.lines = const [],
    this.fulfilment,
    this.comment = '',
  });

  final String? shopId;
  final String shopName;
  final List<CartLine> lines;
  final Fulfilment? fulfilment;
  final String comment;

  bool get isEmpty => lines.isEmpty;
  int get count => lines.fold(0, (n, l) => n + l.quantity);
  int get itemsTotal => lines.fold(0, (n, l) => n + l.priceAtAdd * l.quantity);

  /// How much the active promotions save compared with the regular prices.
  int get savings =>
      lines.fold(0, (n, l) => n + (l.regularPrice - l.priceAtAdd) * l.quantity);

  CartState copyWith({
    String? shopId,
    String? shopName,
    List<CartLine>? lines,
    Fulfilment? fulfilment,
    String? comment,
    bool clearShop = false,
    bool clearFulfilment = false,
  }) =>
      CartState(
        shopId: clearShop ? null : (shopId ?? this.shopId),
        shopName: clearShop ? '' : (shopName ?? this.shopName),
        lines: lines ?? this.lines,
        fulfilment:
            clearFulfilment ? null : (fulfilment ?? this.fulfilment),
        comment: comment ?? this.comment,
      );

  Map<String, dynamic> toJson() => {
        'shopId': shopId,
        'shopName': shopName,
        'lines': lines.map((l) => l.toJson()).toList(),
        'fulfilment': fulfilment?.wire,
        'comment': comment,
      };

  static CartState fromJson(Map<String, dynamic> j) => CartState(
        shopId: j['shopId'] as String?,
        shopName: (j['shopName'] ?? '') as String,
        lines: ((j['lines'] ?? []) as List)
            .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        fulfilment:
            j['fulfilment'] == null ? null : Fulfilment.fromWire(j['fulfilment'] as String),
        comment: (j['comment'] ?? '') as String,
      );
}

/// Why a cart cannot be ordered right now.
sealed class CartIssue {
  const CartIssue();
}

class ShopClosedIssue extends CartIssue {
  const ShopClosedIssue(this.opensLabel);
  final String? opensLabel;
}

class MinOrderIssue extends CartIssue {
  const MinOrderIssue(this.missing);
  final int missing;
}

class OutOfStockIssue extends CartIssue {
  const OutOfStockIssue(this.productId, this.name);
  final String productId;
  final String name;
}

class PriceChangedIssue extends CartIssue {
  const PriceChangedIssue(this.productId, this.name, this.from, this.to);
  final String productId;
  final String name;
  final int from;
  final int to;
}

class DeliveryUnavailableIssue extends CartIssue {
  const DeliveryUnavailableIssue();
}

class FreshLine {
  const FreshLine(this.price, this.regularPrice, this.inStock);
  final int price;
  final int regularPrice;
  final bool inStock;
}

class CartValidation {
  const CartValidation(this.ok, this.issues, this.fresh);
  final bool ok;
  final List<CartIssue> issues;

  /// Fresh prices for every line, used by "Savatni yangilash".
  final Map<String, FreshLine> fresh;
}

class ValidateLine {
  const ValidateLine(this.productId, this.quantity, this.priceAtAdd,
      [this.name]);
  final String productId;
  final int quantity;
  final int priceAtAdd;
  final String? name;
}

class ValidateInput {
  const ValidateInput({
    required this.shopId,
    required this.fulfilment,
    required this.coords,
    required this.lines,
  });

  final String shopId;
  final Fulfilment fulfilment;
  final Coords coords;
  final List<ValidateLine> lines;
}

// ---------------------------------------------------------------- orders

enum OrderStatus {
  isNew('new'),
  accepted('accepted'),
  confirm('confirm'),
  preparing('preparing'),
  onTheWay('on_the_way'),
  ready('ready'),
  completed('completed'),
  rejected('rejected'),
  cancelled('cancelled'),
  expired('expired');

  const OrderStatus(this.wire);
  final String wire;

  static OrderStatus fromWire(String? w) => OrderStatus.values.firstWhere(
        (e) => e.wire == w,
        orElse: () => OrderStatus.isNew,
      );
}

const List<OrderStatus> activeStatuses = [
  OrderStatus.isNew,
  OrderStatus.confirm,
  OrderStatus.accepted,
  OrderStatus.preparing,
  OrderStatus.onTheWay,
  OrderStatus.ready,
];

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.emoji,
    required this.photo,
    required this.price,
    required this.regularPrice,
    required this.quantity,
    this.unavailable = false,
  });

  final String productId;
  final String name;
  final Unit unit;
  final String emoji;
  final String? photo;
  final int price;
  final int regularPrice;
  final int quantity;

  /// The shop marked this item unavailable (the buyer must confirm the new total).
  final bool unavailable;

  OrderItem copyWith({int? quantity, bool? unavailable}) => OrderItem(
        productId: productId,
        name: name,
        unit: unit,
        emoji: emoji,
        photo: photo,
        price: price,
        regularPrice: regularPrice,
        quantity: quantity ?? this.quantity,
        unavailable: unavailable ?? this.unavailable,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'unit': unit,
        'emoji': emoji,
        'photo': photo,
        'price': price,
        'regularPrice': regularPrice,
        'quantity': quantity,
        'unavailable': unavailable,
      };

  static OrderItem fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['productId'] as String,
        name: (j['name'] ?? '') as String,
        unit: (j['unit'] ?? 'dona') as String,
        emoji: (j['emoji'] ?? '📦') as String,
        photo: j['photo'] as String?,
        price: (j['price'] as num).toInt(),
        regularPrice: (j['regularPrice'] as num).toInt(),
        quantity: (j['quantity'] as num).toInt(),
        unavailable: (j['unavailable'] ?? false) as bool,
      );
}

class AddressSnapshot {
  const AddressSnapshot({
    required this.label,
    required this.district,
    required this.street,
    required this.apartment,
    required this.landmark,
  });

  final AddressLabel label;
  final String district;
  final String street;
  final String apartment;
  final String landmark;

  String get oneLine => '$district tumani, $street'
      '${apartment.isEmpty ? '' : ', $apartment-xonadon'}';

  Map<String, dynamic> toJson() => {
        'label': label.wire,
        'district': district,
        'street': street,
        'apartment': apartment,
        'landmark': landmark,
      };

  static AddressSnapshot fromJson(Map<String, dynamic> j) => AddressSnapshot(
        label: AddressLabel.fromWire(j['label'] as String?),
        district: (j['district'] ?? '') as String,
        street: (j['street'] ?? '') as String,
        apartment: (j['apartment'] ?? '') as String,
        landmark: (j['landmark'] ?? '') as String,
      );

  static AddressSnapshot of(Address a) => AddressSnapshot(
        label: a.label,
        district: a.district,
        street: a.street,
        apartment: a.apartment,
        landmark: a.landmark,
      );
}

class StatusStamp {
  const StatusStamp(this.status, this.at);
  final OrderStatus status;
  final int at;

  Map<String, dynamic> toJson() => {'status': status.wire, 'at': at};

  static StatusStamp fromJson(Map<String, dynamic> j) => StatusStamp(
        OrderStatus.fromWire(j['status'] as String?),
        (j['at'] as num).toInt(),
      );
}

class OrderChanges {
  const OrderChanges(this.oldTotal, this.newTotal, this.deadline);
  final int oldTotal;
  final int newTotal;
  final int deadline;
}

/// What a screen shows. Built from an [OrderRecord] plus the clock.
class Order {
  const Order({
    required this.id,
    required this.number,
    required this.buyerName,
    required this.buyerPhone,
    required this.shopId,
    required this.shopName,
    required this.shopPhone,
    required this.status,
    required this.rejectReason,
    required this.shopEmoji,
    required this.shopLogoBg,
    required this.shopPhoto,
    required this.shopAddress,
    required this.etaAt,
    required this.history,
    required this.changes,
    required this.fulfilment,
    required this.address,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.total,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final int number;
  final String? buyerName;
  final String? buyerPhone;
  final String shopId;
  final String shopName;
  final String shopPhone;
  final OrderStatus status;
  final String? rejectReason;
  final String shopEmoji;
  final String shopLogoBg;
  final String? shopPhoto;
  final String shopAddress;
  final int? etaAt;
  final List<StatusStamp> history;

  /// Set while the status is `confirm`: the buyer must accept or decline.
  final OrderChanges? changes;
  final Fulfilment fulfilment;
  final AddressSnapshot? address;
  final String paymentMethod = 'cash';
  final List<OrderItem> items;
  final int itemsTotal;
  final int deliveryFee;
  final int total;
  final String comment;
  final int createdAt;

  bool get isActive => activeStatuses.contains(status);

  int? stampAt(OrderStatus s) {
    for (final h in history) {
      if (h.status == s) return h.at;
    }
    return null;
  }
}

class CreateOrderInput {
  const CreateOrderInput({
    required this.shopId,
    required this.fulfilment,
    required this.address,
    required this.coords,
    required this.lines,
    required this.comment,
    this.buyerName,
    this.buyerPhone,
  });

  final String shopId;
  final Fulfilment fulfilment;
  final Address? address;

  /// The buyer's location for range checks.
  final Coords coords;
  final List<ValidateLine> lines;
  final String comment;
  final String? buyerName;
  final String? buyerPhone;
}

// ---------------------------------------------------------------- errors

enum ApiErrorCode {
  shopClosed('SHOP_CLOSED'),
  minOrderNotMet('MIN_ORDER_NOT_MET'),
  cartChanged('CART_CHANGED'),
  deliveryUnavailable('DELIVERY_UNAVAILABLE'),
  rateLimited('RATE_LIMITED'),
  activeOrderLimit('ACTIVE_ORDER_LIMIT'),
  orderNotCancellable('ORDER_NOT_CANCELLABLE'),
  notFound('NOT_FOUND'),
  validation('VALIDATION'),
  conflict('CONFLICT'),
  promoLimit('PROMO_LIMIT'),
  badTransition('BAD_TRANSITION'),
  internal('INTERNAL');

  const ApiErrorCode(this.wire);
  final String wire;
}

/// Uniform error: a code plus a ready-to-show Uzbek message.
class ApiError implements Exception {
  ApiError(this.code, this.message, [this.issues = const []]);

  final ApiErrorCode code;
  final String message;
  final List<CartIssue> issues;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------- shop side

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.emoji,
    required this.photo,
    required this.price,
    required this.inStock,
    required this.promo,
  });

  final String id;
  final String name;
  final Unit unit;
  final String categoryId;
  final String emoji;
  final String? photo;
  final int price;
  final bool inStock;
  final ShopPromoInfo? promo;
}

class ShopPromoInfo {
  const ShopPromoInfo(this.price, this.endsAt, this.pct);
  final int price;
  final int endsAt;
  final int pct;
}

class ShopSettingsData {
  const ShopSettingsData({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.photo,
    required this.pending,
    required this.manualOpen,
    required this.vacation,
    required this.delivers,
    required this.deliveryFee,
    required this.minOrder,
    required this.deliveryRadiusM,
    required this.deliveryTimeText,
    required this.opensAt,
    required this.closesAt,
    required this.sunOpensAt,
    required this.sunClosesAt,
    required this.sunDifferent,
    required this.categories,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String? photo;
  final bool pending;
  final bool manualOpen;
  final bool vacation;
  final bool delivers;
  final int deliveryFee;
  final int minOrder;
  final int deliveryRadiusM;
  final String deliveryTimeText;
  final String opensAt;
  final String closesAt;
  final String sunOpensAt;
  final String sunClosesAt;
  final bool sunDifferent;
  final List<String> categories;
}

class ShopStats {
  const ShopStats({
    required this.orders,
    required this.ordersDelta,
    required this.revenue,
    required this.revenueDeltaPct,
    required this.views,
    required this.activePromos,
    required this.bestPromo,
    required this.soldOut,
    required this.waiting,
    required this.oldestWaitingAt,
    required this.yesterdayOrders,
  });

  final int orders;
  final int ordersDelta;
  final int revenue;
  final int revenueDeltaPct;
  final int views;
  final int activePromos;
  final String? bestPromo;
  final int soldOut;
  final int waiting;
  final int? oldestWaitingAt;
  final int yesterdayOrders;
}

class CatalogHit {
  const CatalogHit({
    required this.id,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.emoji,
    required this.photo,
    required this.basePrice,
    required this.has,
  });

  final String id;
  final String name;
  final Unit unit;
  final String categoryId;
  final String emoji;
  final String? photo;
  final int basePrice;
  final bool has;
}

/// What a shop can do to an order.
sealed class OrderAction {
  const OrderAction();
}

class AcceptAction extends OrderAction {
  const AcceptAction();
}

class PackAction extends OrderAction {
  const PackAction();
}

class DispatchAction extends OrderAction {
  const DispatchAction();
}

class CompleteAction extends OrderAction {
  const CompleteAction();
}

class RejectAction extends OrderAction {
  const RejectAction(this.reason);
  final String reason;
}

class AvailabilityAction extends OrderAction {
  const AvailabilityAction(this.available);

  /// productId → how many units the shop can supply.
  final Map<String, int> available;
}

class Registration {
  const Registration({
    required this.name,
    required this.categories,
    required this.phone,
    required this.address,
    required this.opensAt,
    required this.closesAt,
    required this.sunDifferent,
    required this.sunOpensAt,
    required this.sunClosesAt,
    required this.delivers,
    required this.deliveryFee,
    required this.minOrder,
    required this.deliveryRadiusM,
    this.photo,
  });

  final String name;
  final List<String> categories;
  final String phone;
  final String address;
  final String opensAt;
  final String closesAt;
  final bool sunDifferent;
  final String sunOpensAt;
  final String sunClosesAt;
  final bool delivers;
  final int deliveryFee;
  final int minOrder;
  final int deliveryRadiusM;

  /// Asset path of the storefront picture chosen in step 2 (demo only).
  final String? photo;
}

class Staff {
  const Staff(this.id, this.name, this.role, {this.owner = false});
  final String id;
  final String name;
  final String role;
  final bool owner;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'role': role, 'owner': owner};

  static Staff fromJson(Map<String, dynamic> j) => Staff(
        j['id'] as String,
        (j['name'] ?? '') as String,
        (j['role'] ?? '') as String,
        owner: (j['owner'] ?? false) as bool,
      );
}

class Invite {
  const Invite(this.link, this.expiresAt);
  final String link;
  final int expiresAt;
}
