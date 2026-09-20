/// The demo data set — a port of `data/seed.ts`.
///
/// Photos point at bundled assets instead of `public/img`.
library;

import 'models.dart';

const List<Category> categories = [
  Category('sut', 'Sut'),
  Category('non', 'Non'),
  Category('meva-sabzavot', 'Meva-sabzavot'),
  Category('gosht', 'Goʻsht'),
  Category('ichimlik', 'Ichimlik'),
  Category('bakaleya', 'Bakaleya'),
  Category('uy-rozgor', 'Uy-roʻzgʻor'),
];

String categoryName(String id) => categories
    .firstWhere((c) => c.id == id, orElse: () => const Category('', ''))
    .name;

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.emoji,
    required this.basePrice,
    required this.description,
  });

  final String id;
  final String name;
  final Unit unit;
  final String categoryId;
  final String emoji;
  final int basePrice;
  final String description;
}

/// The shared catalog (TZ 5.4 quick-add). Shops sell subsets of it with their
/// own prices.
const List<CatalogItem> catalog = [
  CatalogItem(id: 'sut-1l', name: 'Sut 2,5% (1 l)', unit: 'dona', categoryId: 'sut', emoji: '🥛', basePrice: 12000, description: 'Pasterizatsiya qilingan sigir suti, 2,5% yogʻlilik.'),
  CatalogItem(id: 'qatiq', name: 'Qatiq (500 g)', unit: 'dona', categoryId: 'sut', emoji: '🥣', basePrice: 9000, description: 'Tabiiy qatiq, qoʻshimchalarsiz.'),
  CatalogItem(id: 'smetana', name: 'Smetana (400 g)', unit: 'dona', categoryId: 'sut', emoji: '🍶', basePrice: 18000, description: 'Quyuq smetana, 20% yogʻlilik.'),
  CatalogItem(id: 'tvorog', name: 'Tvorog (300 g)', unit: 'dona', categoryId: 'sut', emoji: '🧀', basePrice: 16000, description: 'Yangi tvorog.'),
  CatalogItem(id: 'kefir', name: 'Kefir (1 l)', unit: 'dona', categoryId: 'sut', emoji: '🥛', basePrice: 13000, description: 'Kefir, 2,5% yogʻlilik.'),
  CatalogItem(id: 'sariyog', name: 'Sariyogʻ (200 g)', unit: 'dona', categoryId: 'sut', emoji: '🧈', basePrice: 24000, description: 'Sariyogʻ, 82,5% yogʻlilik.'),
  CatalogItem(id: 'pishloq', name: 'Pishloq', unit: 'kg', categoryId: 'sut', emoji: '🧀', basePrice: 85000, description: 'Qattiq pishloq, ogʻirlik boʻyicha.'),

  CatalogItem(id: 'non', name: 'Non', unit: 'dona', categoryId: 'non', emoji: '🍞', basePrice: 4000, description: 'Yangi yopilgan non.'),
  CatalogItem(id: 'patir', name: 'Patir', unit: 'dona', categoryId: 'non', emoji: '🥯', basePrice: 6000, description: 'Tandirda pishirilgan patir.'),
  CatalogItem(id: 'lavash', name: 'Lavash', unit: 'dona', categoryId: 'non', emoji: '🫓', basePrice: 3000, description: 'Yupqa lavash.'),
  CatalogItem(id: 'bulochka', name: 'Bulochka', unit: 'dona', categoryId: 'non', emoji: '🥐', basePrice: 3500, description: 'Yumshoq bulochka.'),
  CatalogItem(id: 'baton', name: 'Baton', unit: 'dona', categoryId: 'non', emoji: '🥖', basePrice: 5500, description: 'Oq baton.'),

  CatalogItem(id: 'olma', name: 'Olma', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🍎', basePrice: 14000, description: 'Mahalliy olma.'),
  CatalogItem(id: 'banan', name: 'Banan', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🍌', basePrice: 18000, description: 'Pishgan banan.'),
  CatalogItem(id: 'pomidor', name: 'Pomidor', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🍅', basePrice: 12000, description: 'Yangi pomidor.'),
  CatalogItem(id: 'bodring', name: 'Bodring', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🥒', basePrice: 9000, description: 'Yangi bodring.'),
  CatalogItem(id: 'kartoshka', name: 'Kartoshka', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🥔', basePrice: 6000, description: 'Kartoshka, yuvilgan.'),
  CatalogItem(id: 'piyoz', name: 'Piyoz', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🧅', basePrice: 5000, description: 'Sariq piyoz.'),
  CatalogItem(id: 'sabzi', name: 'Sabzi', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🥕', basePrice: 5500, description: 'Shirin sabzi.'),
  CatalogItem(id: 'uzum', name: 'Uzum', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🍇', basePrice: 25000, description: 'Danaksiz uzum.'),
  CatalogItem(id: 'limon', name: 'Limon', unit: 'kg', categoryId: 'meva-sabzavot', emoji: '🍋', basePrice: 22000, description: 'Suvli limon.'),

  CatalogItem(id: 'mol-gosht', name: 'Mol goʻshti', unit: 'kg', categoryId: 'gosht', emoji: '🥩', basePrice: 95000, description: 'Suyaksiz mol goʻshti.'),
  CatalogItem(id: 'tovuq', name: 'Tovuq goʻshti', unit: 'kg', categoryId: 'gosht', emoji: '🍗', basePrice: 38000, description: 'Butun tovuq.'),
  CatalogItem(id: 'qiyma', name: 'Qiyma', unit: 'kg', categoryId: 'gosht', emoji: '🥩', basePrice: 85000, description: 'Mol goʻshtidan qiyma.'),
  CatalogItem(id: 'kolbasa', name: 'Kolbasa', unit: 'kg', categoryId: 'gosht', emoji: '🌭', basePrice: 62000, description: 'Pishirilgan kolbasa.'),

  CatalogItem(id: 'suv', name: 'Suv (1,5 l)', unit: 'dona', categoryId: 'ichimlik', emoji: '🚰', basePrice: 3500, description: 'Gazsiz ichimlik suvi.'),
  CatalogItem(id: 'cola', name: 'Coca-Cola (1,5 l)', unit: 'dona', categoryId: 'ichimlik', emoji: '🥤', basePrice: 11000, description: 'Gazlangan ichimlik.'),
  CatalogItem(id: 'choy', name: 'Qora choy (100 g)', unit: 'quti', categoryId: 'ichimlik', emoji: '🍵', basePrice: 14000, description: 'Barglari yirik qora choy.'),
  CatalogItem(id: 'sharbat', name: 'Sharbat (1 l)', unit: 'dona', categoryId: 'ichimlik', emoji: '🧃', basePrice: 15000, description: 'Meva sharbati.'),

  CatalogItem(id: 'guruch', name: 'Guruch', unit: 'kg', categoryId: 'bakaleya', emoji: '🍚', basePrice: 16000, description: 'Devzira guruchi.'),
  CatalogItem(id: 'un', name: 'Un', unit: 'kg', categoryId: 'bakaleya', emoji: '🌾', basePrice: 8000, description: 'Oliy navli bugʻdoy uni.'),
  CatalogItem(id: 'shakar', name: 'Shakar', unit: 'kg', categoryId: 'bakaleya', emoji: '🍬', basePrice: 14000, description: 'Oq shakar.'),
  CatalogItem(id: 'makaron', name: 'Makaron (400 g)', unit: 'dona', categoryId: 'bakaleya', emoji: '🍝', basePrice: 8000, description: 'Spagetti makaroni.'),
  CatalogItem(id: 'yog', name: 'Kungaboqar yogʻi', unit: 'l', categoryId: 'bakaleya', emoji: '🌻', basePrice: 24000, description: 'Rafinadlangan yogʻ.'),
  CatalogItem(id: 'tuz', name: 'Tuz (1 kg)', unit: 'dona', categoryId: 'bakaleya', emoji: '🧂', basePrice: 3000, description: 'Yodlangan tuz.'),
  CatalogItem(id: 'tuxum', name: 'Tuxum (10 ta)', unit: 'quti', categoryId: 'bakaleya', emoji: '🥚', basePrice: 16000, description: 'Tovuq tuxumi, 10 dona.'),

  CatalogItem(id: 'idish-yuvish', name: 'Idish yuvish vositasi', unit: 'dona', categoryId: 'uy-rozgor', emoji: '🧴', basePrice: 18000, description: 'Suyuq idish yuvish vositasi, 500 ml.'),
  CatalogItem(id: 'kir-kukun', name: 'Kir yuvish kukuni', unit: 'quti', categoryId: 'uy-rozgor', emoji: '🧼', basePrice: 38000, description: 'Avtomat uchun kir yuvish kukuni, 3 kg.'),
  CatalogItem(id: 'sovun', name: 'Sovun', unit: 'dona', categoryId: 'uy-rozgor', emoji: '🧼', basePrice: 5000, description: 'Qoʻl uchun sovun.'),
  CatalogItem(id: 'salfetka', name: 'Salfetka', unit: 'quti', categoryId: 'uy-rozgor', emoji: '🧻', basePrice: 6000, description: 'Qogʻoz salfetkalar.'),
  CatalogItem(id: 'wc-qogoz', name: 'Hojatxona qogʻozi', unit: 'quti', categoryId: 'uy-rozgor', emoji: '🧻', basePrice: 22000, description: 'Uch qavatli, 8 dona.'),
];

/// A shop of the demo data set. Mutable, because the shop app edits it and the
/// overlay in the mock database is replayed onto it on every call.
class SeedShop {
  SeedShop({
    required this.id,
    required this.name,
    required this.type,
    required this.emoji,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.delivers,
    required this.deliveryFee,
    required this.minOrder,
    required this.deliveryRadiusM,
    required this.deliveryTimeText,
    required this.opensAt,
    required this.closesAt,
    required this.manualOpen,
    required this.categories,
    this.rejectsOrders = false,
    this.pending = false,
    this.vacation = false,
    this.sunOpensAt,
    this.sunClosesAt,
    this.partialOrders = false,
  });

  String id;
  String name;
  String type;
  String emoji;
  String phone;
  double lat;
  double lng;
  bool delivers;
  int deliveryFee;
  int minOrder;
  int deliveryRadiusM;
  String deliveryTimeText;
  String opensAt;
  String closesAt;

  /// The shop owner switched the shop off (TZ 5.2).
  bool manualOpen;
  List<String> categories;

  /// Demo: this shop rejects every order ("Mahsulot tugagan").
  bool rejectsOrders;

  /// Registered through the shop app and not yet approved: hidden from buyers.
  bool pending;

  /// The shop owner switched on vacation mode ("Taʼtil rejimi").
  bool vacation;

  /// Different opening hours on Sundays.
  String? sunOpensAt;
  String? sunClosesAt;

  /// Demo: this shop is out of the first item of any multi-item order and asks
  /// the buyer to confirm.
  bool partialOrders;

  SeedShop clone() => SeedShop(
        id: id,
        name: name,
        type: type,
        emoji: emoji,
        phone: phone,
        lat: lat,
        lng: lng,
        delivers: delivers,
        deliveryFee: deliveryFee,
        minOrder: minOrder,
        deliveryRadiusM: deliveryRadiusM,
        deliveryTimeText: deliveryTimeText,
        opensAt: opensAt,
        closesAt: closesAt,
        manualOpen: manualOpen,
        categories: List<String>.from(categories),
        rejectsOrders: rejectsOrders,
        pending: pending,
        vacation: vacation,
        sunOpensAt: sunOpensAt,
        sunClosesAt: sunClosesAt,
        partialOrders: partialOrders,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'emoji': emoji,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'delivers': delivers,
        'deliveryFee': deliveryFee,
        'minOrder': minOrder,
        'deliveryRadiusM': deliveryRadiusM,
        'deliveryTimeText': deliveryTimeText,
        'opensAt': opensAt,
        'closesAt': closesAt,
        'manualOpen': manualOpen,
        'categories': categories,
        'rejectsOrders': rejectsOrders,
        'pending': pending,
        'vacation': vacation,
        'sunOpensAt': sunOpensAt,
        'sunClosesAt': sunClosesAt,
        'partialOrders': partialOrders,
      };

  static SeedShop fromJson(Map<String, dynamic> j) => SeedShop(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        type: (j['type'] ?? 'Doʻkon') as String,
        emoji: (j['emoji'] ?? '🏪') as String,
        phone: (j['phone'] ?? '') as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        delivers: (j['delivers'] ?? false) as bool,
        deliveryFee: (j['deliveryFee'] as num?)?.toInt() ?? 0,
        minOrder: (j['minOrder'] as num?)?.toInt() ?? 0,
        deliveryRadiusM: (j['deliveryRadiusM'] as num?)?.toInt() ?? 0,
        deliveryTimeText: (j['deliveryTimeText'] ?? '') as String,
        opensAt: (j['opensAt'] ?? '08:00') as String,
        closesAt: (j['closesAt'] ?? '20:00') as String,
        manualOpen: (j['manualOpen'] ?? true) as bool,
        categories: List<String>.from((j['categories'] ?? []) as List),
        rejectsOrders: (j['rejectsOrders'] ?? false) as bool,
        pending: (j['pending'] ?? false) as bool,
        vacation: (j['vacation'] ?? false) as bool,
        sunOpensAt: j['sunOpensAt'] as String?,
        sunClosesAt: j['sunClosesAt'] as String?,
        partialOrders: (j['partialOrders'] ?? false) as bool,
      );
}

/// A fresh copy of the seed shops. The mock server owns its own list because
/// the shop app edits it.
List<SeedShop> buildSeedShops() => [
      SeedShop(
        id: 'baraka', name: 'Baraka Market', type: 'Oziq-ovqat doʻkoni', emoji: '🛒', phone: '+998 71 200 11 22',
        lat: 41.2765, lng: 69.2055, delivers: true, deliveryFee: 8000, minOrder: 40000, deliveryRadiusM: 2500,
        deliveryTimeText: '30–40 daqiqa', opensAt: '07:00', closesAt: '23:00', manualOpen: true,
        categories: ['sut', 'non', 'meva-sabzavot', 'ichimlik', 'bakaleya', 'uy-rozgor'],
      ),
      SeedShop(
        id: 'nonvoy', name: 'Yangi Non', type: 'Nonvoyxona', emoji: '🥖', phone: '+998 90 111 22 33',
        lat: 41.272, lng: 69.201, delivers: true, deliveryFee: 5000, minOrder: 20000, deliveryRadiusM: 1500,
        deliveryTimeText: '20–30 daqiqa', opensAt: '06:00', closesAt: '21:00', manualOpen: true,
        categories: ['non', 'sut', 'ichimlik'],
      ),
      SeedShop(
        id: 'sabzavot', name: 'Meva Bogʻi', type: 'Meva-sabzavot doʻkoni', emoji: '🥬', phone: '+998 93 222 33 44',
        lat: 41.28, lng: 69.21, delivers: true, deliveryFee: 10000, minOrder: 50000, deliveryRadiusM: 3000,
        deliveryTimeText: '40–50 daqiqa', opensAt: '07:00', closesAt: '20:00', manualOpen: true,
        categories: ['meva-sabzavot'], partialOrders: true,
      ),
      SeedShop(
        id: 'sut-olami', name: 'Sut Olami', type: 'Sut mahsulotlari doʻkoni', emoji: '🥛', phone: '+998 94 333 44 55',
        lat: 41.269, lng: 69.198, delivers: false, deliveryFee: 0, minOrder: 0, deliveryRadiusM: 0,
        deliveryTimeText: '', opensAt: '07:00', closesAt: '22:00', manualOpen: true,
        categories: ['sut', 'non', 'ichimlik'],
      ),
      SeedShop(
        id: 'gosht', name: 'Qassob Karim', type: 'Goʻsht doʻkoni', emoji: '🥩', phone: '+998 97 444 55 66',
        lat: 41.2745, lng: 69.207, delivers: true, deliveryFee: 12000, minOrder: 80000, deliveryRadiusM: 2000,
        deliveryTimeText: '45–60 daqiqa', opensAt: '08:00', closesAt: '20:00', manualOpen: false,
        categories: ['gosht', 'bakaleya'],
      ),
      SeedShop(
        id: 'tungi', name: 'Tungi doʻkon 24/7', type: 'Oziq-ovqat doʻkoni', emoji: '🌙', phone: '+998 88 555 66 77',
        lat: 41.2785, lng: 69.2, delivers: true, deliveryFee: 15000, minOrder: 30000, deliveryRadiusM: 2000,
        deliveryTimeText: '25–35 daqiqa', opensAt: '00:00', closesAt: '24:00', manualOpen: true,
        categories: ['sut', 'non', 'meva-sabzavot', 'gosht', 'ichimlik', 'bakaleya', 'uy-rozgor'],
      ),
      SeedShop(
        id: 'yashil', name: 'Nodira opa doʻkoni', type: 'Meva-sabzavot doʻkoni', emoji: '🍎', phone: '+998 99 666 77 88',
        lat: 41.285, lng: 69.222, delivers: true, deliveryFee: 9000, minOrder: 40000, deliveryRadiusM: 1500,
        deliveryTimeText: '35–45 daqiqa', opensAt: '08:00', closesAt: '21:00', manualOpen: true,
        categories: ['meva-sabzavot', 'ichimlik'],
      ),
      SeedShop(
        id: 'oila', name: 'Oila Doʻkoni', type: 'Uy-roʻzgʻor doʻkoni', emoji: '🧼', phone: '+998 91 777 88 99',
        lat: 41.274, lng: 69.2075, delivers: true, deliveryFee: 7000, minOrder: 25000, deliveryRadiusM: 1800,
        deliveryTimeText: '30–40 daqiqa', opensAt: '00:00', closesAt: '24:00', manualOpen: true,
        categories: ['uy-rozgor', 'bakaleya', 'ichimlik'], rejectsOrders: true,
      ),
    ];

/// Product photos. Products without one fall back to an emoji tile.
const Map<String, String> photos = {
  'banan': 'assets/img/banan.png',
  'pomidor': 'assets/img/pomidor.png',
  'sut-1l': 'assets/img/sut2.png',
  'tovuq': 'assets/img/tovuq.png',
  'tuxum': 'assets/img/tuxum.png',
  'bodring': 'assets/img/bodring.png',
  'kartoshka': 'assets/img/kartoshka.png',
  'piyoz': 'assets/img/piyoz.png',
  'olma': 'assets/img/olma.png',
  'patir': 'assets/img/patir.png',
  'uzum': 'assets/img/uzum.png',
  'tvorog': 'assets/img/tvorog.png',
  'cola': 'assets/img/cola.png',
  'yog': 'assets/img/yog.png',
};

/// Catalog ids shown under "Ommabop mahsulotlar" on Home.
const List<String> popularIds = [
  'banan', 'pomidor', 'sut-1l', 'tuxum', 'bodring', 'kartoshka',
  'piyoz', 'olma', 'tovuq', 'patir', 'uzum', 'tvorog',
];

class ShopLook {
  const ShopLook({
    required this.address,
    required this.bg,
    required this.icon,
    this.photo,
  });

  final String address;

  /// `#12a05a`
  final String bg;
  final String icon;
  final String? photo;

  Map<String, dynamic> toJson() =>
      {'address': address, 'bg': bg, 'icon': icon, 'photo': photo};

  static ShopLook fromJson(Map<String, dynamic> j) => ShopLook(
        address: (j['address'] ?? '') as String,
        bg: (j['bg'] ?? '#0E7A4A') as String,
        icon: (j['icon'] ?? 'store') as String,
        photo: j['photo'] as String?,
      );
}

/// Street address and logo colour of each shop.
const Map<String, ShopLook> shopLookSeed = {
  'baraka': ShopLook(address: 'Chilonzor, 9-mavze, 12-uy', bg: '#12a05a', photo: 'assets/img/shop-baraka.png', icon: 'cart'),
  'nonvoy': ShopLook(address: 'Chilonzor, 7-mavze, Bunyodkor koʻchasi 4', bg: '#f59a2f', photo: 'assets/img/shop-yangi-non.png', icon: 'bread'),
  'sabzavot': ShopLook(address: 'Chilonzor, 10-mavze, Bozor yonida', bg: '#3fb24d', photo: 'assets/img/shop-meva-bogi.png', icon: 'leaf'),
  'sut-olami': ShopLook(address: 'Chilonzor, 6-mavze, 21-uy', bg: '#3f8cf0', icon: 'milk'),
  'gosht': ShopLook(address: 'Chilonzor, 8-mavze, 3-uy', bg: '#e5546b', photo: 'assets/img/shop-qassob.png', icon: 'meat'),
  'tungi': ShopLook(address: 'Chilonzor, 9-mavze, Qatortol koʻchasi 30', bg: '#5b5bd6', icon: 'moon'),
  'yashil': ShopLook(address: 'Chilonzor, 14-mavze, 5-uy', bg: '#a06be0', icon: 'bag'),
  'oila': ShopLook(address: 'Chilonzor, 9-mavze, 18-uy', bg: '#ff6f5e', photo: 'assets/img/shop-oila.png', icon: 'soap'),
};

/// Storefront pictures a newly registered shop can pick from (the demo has no
/// camera roll access — see DECISIONS.md).
const List<String> pickablePhotos = [
  'assets/img/shop-baraka.png',
  'assets/img/shop-yangi-non.png',
  'assets/img/shop-meva-bogi.png',
  'assets/img/shop-qassob.png',
  'assets/img/shop-oila.png',
];
