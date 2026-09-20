/// The mock server's database — a port of the `MockDb` shape that the web app
/// keeps in `localStorage`.
///
/// In the APK the buyer screens and the shop screens run in one process, so a
/// single in-memory instance is shared and mirrored to `shared_preferences` as
/// one JSON blob. Every read and write is wrapped in try/catch: a broken or
/// missing blob must never stop the app from starting.
library;

import 'dart:convert';

import 'models.dart';
import 'seed.dart';

const String dbKey = 'yaqinda-mock-db';
const String activeShopKey = 'yaqinda-shop-active';

class ProductRecord {
  ProductRecord({
    required this.id,
    required this.shopId,
    required this.catalogId,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.emoji,
    required this.description,
    required this.inStock,
    required this.price,
  });

  final String id;
  final String shopId;
  final String catalogId;
  String name;
  Unit unit;
  String categoryId;
  String emoji;
  String description;
  bool inStock;
  int price;

  ProductRecord copy() => ProductRecord(
        id: id,
        shopId: shopId,
        catalogId: catalogId,
        name: name,
        unit: unit,
        categoryId: categoryId,
        emoji: emoji,
        description: description,
        inStock: inStock,
        price: price,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'catalogId': catalogId,
        'name': name,
        'unit': unit,
        'categoryId': categoryId,
        'emoji': emoji,
        'description': description,
        'inStock': inStock,
        'price': price,
      };

  static ProductRecord fromJson(Map<String, dynamic> j) => ProductRecord(
        id: j['id'] as String,
        shopId: j['shopId'] as String,
        catalogId: (j['catalogId'] ?? 'custom') as String,
        name: (j['name'] ?? '') as String,
        unit: (j['unit'] ?? 'dona') as String,
        categoryId: (j['categoryId'] ?? 'bakaleya') as String,
        emoji: (j['emoji'] ?? '📦') as String,
        description: (j['description'] ?? '') as String,
        inStock: (j['inStock'] ?? true) as bool,
        price: (j['price'] as num).toInt(),
      );
}

class PromoRecord {
  PromoRecord({
    required this.productId,
    required this.promoPrice,
    required this.startsAt,
    required this.endsAt,
  });

  final String productId;
  final int promoPrice;
  final int startsAt;
  final int endsAt;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'promoPrice': promoPrice,
        'startsAt': startsAt,
        'endsAt': endsAt,
      };

  static PromoRecord fromJson(Map<String, dynamic> j) => PromoRecord(
        productId: j['productId'] as String,
        promoPrice: (j['promoPrice'] as num).toInt(),
        startsAt: (j['startsAt'] as num).toInt(),
        endsAt: (j['endsAt'] as num).toInt(),
      );
}

/// An order driven by the shop app instead of the demo timeline.
class ManualState {
  ManualState({
    required this.status,
    required this.history,
    this.rejectReason,
    this.availability,
    this.deadline,
  });

  OrderStatus status;
  List<StatusStamp> history;
  String? rejectReason;

  /// How many units of each product the shop can supply (partial fulfilment).
  Map<String, int>? availability;
  int? deadline;

  Map<String, dynamic> toJson() => {
        'status': status.wire,
        'history': history.map((h) => h.toJson()).toList(),
        'rejectReason': rejectReason,
        'availability': availability,
        'deadline': deadline,
      };

  static ManualState fromJson(Map<String, dynamic> j) => ManualState(
        status: OrderStatus.fromWire(j['status'] as String?),
        history: ((j['history'] ?? []) as List)
            .map((e) => StatusStamp.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        rejectReason: j['rejectReason'] as String?,
        availability: j['availability'] == null
            ? null
            : Map<String, int>.from(
                (j['availability'] as Map).map((k, v) => MapEntry('$k', (v as num).toInt())),
              ),
        deadline: (j['deadline'] as num?)?.toInt(),
      );
}

/// The stored order. The status a screen sees is derived from this record and
/// the current time (see `MockServer.toOrder`).
class OrderRecord {
  OrderRecord({
    required this.id,
    required this.number,
    required this.shopId,
    required this.shopName,
    required this.shopPhone,
    required this.fulfilment,
    required this.address,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.total,
    required this.comment,
    required this.createdAt,
    required this.cancelledAt,
    this.buyerName,
    this.buyerPhone,
    this.manual,
    this.foreign = false,
    this.etaMinutes,
    this.confirmedAt,
  });

  final String id;
  final int number;
  String? buyerName;
  String? buyerPhone;
  final String shopId;
  String shopName;
  String shopPhone;
  final Fulfilment fulfilment;
  final AddressSnapshot? address;
  List<OrderItem> items;
  int itemsTotal;
  int deliveryFee;
  int total;
  String comment;
  int createdAt;
  int? cancelledAt;
  ManualState? manual;

  /// Placed by another customer (demo data for the shop app); hidden from this
  /// buyer's list.
  bool foreign;
  int? etaMinutes;

  /// When the buyer accepted the shop's changes (partial fulfilment).
  int? confirmedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'shopId': shopId,
        'shopName': shopName,
        'shopPhone': shopPhone,
        'fulfilment': fulfilment.wire,
        'address': address?.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'itemsTotal': itemsTotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'comment': comment,
        'createdAt': createdAt,
        'cancelledAt': cancelledAt,
        'manual': manual?.toJson(),
        'foreign': foreign,
        'etaMinutes': etaMinutes,
        'confirmedAt': confirmedAt,
      };

  static OrderRecord fromJson(Map<String, dynamic> j) => OrderRecord(
        id: j['id'] as String,
        number: (j['number'] as num).toInt(),
        buyerName: j['buyerName'] as String?,
        buyerPhone: j['buyerPhone'] as String?,
        shopId: j['shopId'] as String,
        shopName: (j['shopName'] ?? '') as String,
        shopPhone: (j['shopPhone'] ?? '') as String,
        fulfilment: Fulfilment.fromWire(j['fulfilment'] as String?),
        address: j['address'] == null
            ? null
            : AddressSnapshot.fromJson(Map<String, dynamic>.from(j['address'] as Map)),
        items: ((j['items'] ?? []) as List)
            .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        itemsTotal: (j['itemsTotal'] as num).toInt(),
        deliveryFee: (j['deliveryFee'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        comment: (j['comment'] ?? '') as String,
        createdAt: (j['createdAt'] as num).toInt(),
        cancelledAt: (j['cancelledAt'] as num?)?.toInt(),
        manual: j['manual'] == null
            ? null
            : ManualState.fromJson(Map<String, dynamic>.from(j['manual'] as Map)),
        foreign: (j['foreign'] ?? false) as bool,
        etaMinutes: (j['etaMinutes'] as num?)?.toInt(),
        confirmedAt: (j['confirmedAt'] as num?)?.toInt(),
      );
}

/// Settings the shop app changed, replayed onto the seed shop on every call.
class ShopOverlay {
  ShopOverlay(this.values);
  final Map<String, dynamic> values;

  Map<String, dynamic> toJson() => values;

  static ShopOverlay fromJson(Map<String, dynamic> j) => ShopOverlay(j);
}

class NewShop {
  NewShop(this.shop, this.look);
  final SeedShop shop;
  final ShopLook look;

  Map<String, dynamic> toJson() => {'shop': shop.toJson(), 'look': look.toJson()};

  static NewShop fromJson(Map<String, dynamic> j) => NewShop(
        SeedShop.fromJson(Map<String, dynamic>.from(j['shop'] as Map)),
        ShopLook.fromJson(Map<String, dynamic>.from(j['look'] as Map)),
      );
}

class ProductOverride {
  ProductOverride({this.price, this.inStock});
  int? price;
  bool? inStock;

  Map<String, dynamic> toJson() => {'price': price, 'inStock': inStock};

  static ProductOverride fromJson(Map<String, dynamic> j) => ProductOverride(
        price: (j['price'] as num?)?.toInt(),
        inStock: j['inStock'] as bool?,
      );
}

class WaitlistEntry {
  const WaitlistEntry(this.district, this.at);
  final String district;
  final int at;

  Map<String, dynamic> toJson() => {'district': district, 'at': at};

  static WaitlistEntry fromJson(Map<String, dynamic> j) =>
      WaitlistEntry((j['district'] ?? '') as String, (j['at'] as num).toInt());
}

class MockDb {
  MockDb();

  List<OrderRecord> orders = [];
  int nextNumber = 1042;
  Map<String, String> idempotency = {};
  List<WaitlistEntry> waitlist = [];

  /// True once the shop app has been opened: orders of owned shops then wait
  /// for the shop instead of playing the automatic timeline.
  bool shopManual = false;
  Map<String, ShopOverlay> overlay = {};
  Map<String, ProductOverride> productOv = {};
  List<ProductRecord> extra = [];
  List<PromoRecord> promoAdds = [];
  List<String> promoEnded = [];
  List<NewShop> newShops = [];
  List<Staff>? staff;
  bool demoSeeded = false;

  Map<String, dynamic> toJson() => {
        'orders': orders.map((o) => o.toJson()).toList(),
        'nextNumber': nextNumber,
        'idempotency': idempotency,
        'waitlist': waitlist.map((w) => w.toJson()).toList(),
        'shopManual': shopManual,
        'overlay': overlay.map((k, v) => MapEntry(k, v.toJson())),
        'productOv': productOv.map((k, v) => MapEntry(k, v.toJson())),
        'extra': extra.map((e) => e.toJson()).toList(),
        'promoAdds': promoAdds.map((p) => p.toJson()).toList(),
        'promoEnded': promoEnded,
        'newShops': newShops.map((n) => n.toJson()).toList(),
        'staff': staff?.map((s) => s.toJson()).toList(),
        'demoSeeded': demoSeeded,
      };

  static MockDb fromJson(Map<String, dynamic> j) {
    final db = MockDb();
    db.orders = ((j['orders'] ?? []) as List)
        .map((e) => OrderRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    db.nextNumber = (j['nextNumber'] as num?)?.toInt() ?? 1042;
    db.idempotency = Map<String, String>.from(
        ((j['idempotency'] ?? {}) as Map).map((k, v) => MapEntry('$k', '$v')));
    db.waitlist = ((j['waitlist'] ?? []) as List)
        .map((e) => WaitlistEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    db.shopManual = (j['shopManual'] ?? false) as bool;
    db.overlay = ((j['overlay'] ?? {}) as Map).map((k, v) =>
        MapEntry('$k', ShopOverlay(Map<String, dynamic>.from(v as Map))));
    db.productOv = ((j['productOv'] ?? {}) as Map).map((k, v) => MapEntry(
        '$k', ProductOverride.fromJson(Map<String, dynamic>.from(v as Map))));
    db.extra = ((j['extra'] ?? []) as List)
        .map((e) => ProductRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    db.promoAdds = ((j['promoAdds'] ?? []) as List)
        .map((e) => PromoRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    db.promoEnded = List<String>.from((j['promoEnded'] ?? []) as List);
    db.newShops = ((j['newShops'] ?? []) as List)
        .map((e) => NewShop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final st = j['staff'];
    db.staff = st == null
        ? null
        : (st as List)
            .map((e) => Staff.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    db.demoSeeded = (j['demoSeeded'] ?? false) as bool;
    return db;
  }
}

/// Where the database is kept between launches. The app uses
/// [SharedPrefsStore]; tests use [MemoryStore] so they never touch a plugin.
abstract class KeyValueStore {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;

  @override
  void remove(String key) => _values.remove(key);
}

/// Loads a database blob, tolerating anything that is not valid JSON.
MockDb decodeDb(String? raw) {
  if (raw == null || raw.isEmpty) return MockDb();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return MockDb.fromJson(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {
    // A corrupt blob is not worth a crash: start from an empty database.
  }
  return MockDb();
}

String encodeDb(MockDb db) => jsonEncode(db.toJson());
