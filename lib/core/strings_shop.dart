/// All UI text of the shop app in one place — a port of `shop/strings.ts`.
/// Uzbek (Latin). The nested objects of the TS file become nested classes so
/// call sites read the same: `S.orders.accept`, `S.panel.waiting(2)`.
library;

class ShopCommon {
  const ShopCommon();
  final String save = 'Saqlash';
  final String back = 'Orqaga qaytish';
  final String cont = 'Davom etish';
  final String finish = 'Yakunlash';
  final String add = 'Qoʻshish';
  final String cancel = 'Bekor qilish';
  final String som = 'soʻm';
  final String error = 'Nimadir xato ketdi';
  final String retry = 'Qayta urinish';
  final String close = 'Yopish';
}

class ShopNav {
  const ShopNav();
  final String panel = 'Panel';
  final String orders = 'Buyurtmalar';
  final String products = 'Mahsulotlar';
  final String settings = 'Sozlamalar';
}

class ShopPanel {
  const ShopPanel();
  String today(String d) => 'Bugun, $d';
  final String open = 'Doʻkon ochiq';
  final String openSub = 'Mijozlar buyurtma bera oladi';
  final String closed = 'Doʻkon yopiq';
  final String closedSub = 'Buyurtmalar qabul qilinmaydi';
  String waiting(int n) => '$n ta yangi buyurtma kutyapti';
  String oldest(int m) => 'Eng eskisi $m daqiqa oldin kelgan';
  final String view = 'Koʻrish';
  final String promoTitle = 'Aksiya qoʻshish';
  final String promoSub = '30 soniyada: mahsulot, yangi narx, muddat';
  final String todayTitle = 'Bugun';
  final String ordersLabel = 'Buyurtmalar';
  final String revenueLabel = 'Tushum';
  final String viewsLabel = 'Doʻkonni koʻrganlar';
  final String promosLabel = 'Faol aksiyalar';
  String yesterday(String d) => 'Kechagidan $d';
  final String viaPromos = 'Aksiyalar tufayli';
  String best(String n) => 'Eng yaxshisi: $n';
  final String noPromo = 'Hali aksiya yoʻq';
  final String stock = 'Qoldiqni yangilash';
  String stockSub(int n) =>
      n != 0 ? '$n ta mahsulot tugagan deb belgilangan' : 'Hamma mahsulot bor';
  final String pending = 'Tekshirilmoqda';
  final String pendingSub =
      'Administrator doʻkoningizni 24 soat ichida tasdiqlaydi';
}

class ShopOrders {
  const ShopOrders();
  final String title = 'Buyurtmalar';
  final String fresh = 'Yangi';
  final String progress = 'Jarayonda';
  final String done = 'Yakunlangan';
  String waitMin(int m) => m <= 0 ? 'Hozir keldi' : '$m daq kutyapti';
  final String delivery = 'Yetkazish';
  final String pickup = 'Olib ketish';
  final String cash = 'Naqd pul';
  String itemsN(int n) => '$n ta mahsulot';
  final String fee = 'Yetkazish';
  final String total = 'Jami';
  String landmark(String v) => 'Moʻljal: $v';
  final String missing = 'Baʼzi mahsulot yoʻqmi?';
  final String reject = 'Rad etish';
  final String accept = 'Qabul qilish';
  final String call = 'Mijozga qoʻngʻiroq';
  final String pack = 'Yigʻishni boshlash';
  final String dispatch = 'Kuryerga berildi';
  final String ready = 'Tayyor deb belgilash';
  final String delivered = 'Yetkazildi';
  final String pickedUp = 'Olib ketildi';
  final String waitingConfirm = 'Mijoz tasdiqlashini kutyapmiz';
  final Map<String, String> status = const {
    'accepted': 'Qabul qilindi',
    'preparing': 'Yigʻilmoqda',
    'on_the_way': 'Yoʻlda',
    'ready': 'Tayyor',
    'completed': 'Yakunlandi',
    'rejected': 'Rad etildi',
    'cancelled': 'Bekor qilindi',
    'expired': 'Javobsiz qoldi',
    'confirm': 'Tasdiq kutilmoqda',
    'new': 'Yangi',
  };
  final String emptyTitle = 'Hozircha yangi buyurtma yoʻq';
  final String emptyText =
      'Aksiya qoʻshing: atrofdagi xaridorlar uni birinchi boʻlib koʻradi.';
  final String share = 'Doʻkon havolasini ulashish';
  final String shareHint = 'Mahalla guruhingizga yuboring';
  final String openLine = 'Doʻkon ochiq';
  final String openLineSub = 'mijozlar buyurtma bera oladi';
  final String noShopTitle = 'Hozircha buyurtma yoʻq';
  final String noShopText =
      'Mijozlar sizning doʻkoningizdan buyurtma berishganda, ular shu yerda koʻrinadi.';
  final String subtitle = 'Barcha buyurtmalar shu yerda koʻrinadi.';
  final String someRejected = 'Yakunlanmagan buyurtmalar';
  final String errStale = 'Buyurtma holati oʻzgargan, yangilang';
}

class ShopReject {
  const ShopReject();
  final String title = 'Nega rad etasiz?';
  final List<String> reasons = const [
    'Mahsulot tugagan',
    'Yetkazib bera olmaymiz',
    'Doʻkon yopilmoqda',
    'Boshqa sabab',
  ];
  final String tipTitle = 'Faqat bitta mahsulot tugaganmi?';
  final String tipText =
      'Buyurtmani rad etmang, oʻsha mahsulotni belgilang. Mijoz qolganini oladi.';
  final String tipCta = 'Baʼzi mahsulot yoʻq deb belgilash';
  final String preview = 'Mijozga shunday xabar boradi:';
  String message(String shop, String why) =>
      'Afsuski, $shop buyurtmangizni qabul qila olmadi: ${why.toLowerCase()}.';
  final String submit = 'Buyurtmani rad etish';
}

class ShopAvail {
  const ShopAvail();
  final String title = 'Nechta bor?';
  final String hint = 'Bor sonini koʻrsating. Umuman yoʻq boʻlsa, 0 qiling.';
  String ordered(int n) => 'Buyurtma: $n ta';
  final String all = 'Hammasi bor';
  String less(int n) => '$n ta kam';
  final String none = 'Yoʻq';
  final String items = 'Mahsulotlar';
  final String fee = 'Yetkazish';
  final String old = 'Avvalgi summa';
  final String neu = 'Yangi summa';
  final String note =
      'Mijoz 5 daqiqa ichida tasdiqlaydi. Tasdiqlasa, buyurtma avtomatik qabul qilinadi.';
  String send(String sum) => 'Mijozga yuborish · $sum';
  final String needChange = 'Hech narsa oʻzgarmadi';
  final String allGone = 'Hammasi yoʻq: buyurtmani rad eting';
}

class ShopProducts {
  const ShopProducts();
  final String title = 'Mahsulotlar';
  String count(int n) => '$n ta mahsulot';
  final String add = 'Qoʻshish';
  final String search = 'Mahsulot qidiring';
  final String all = 'Hammasi';
  final String soldOut = 'Tugagan';
  final String onSale = 'Aksiyada';
  final String info =
      'Tugmani bosing: mahsulot bor yoki tugagan. Tugagan mahsulotni mijozlar buyurtma qila olmaydi.';
  final String have = 'Bor';
  final String gone = 'Tugagan';
  final String editPrice = 'Narxni oʻzgartirish';
  final String price = 'Narx';
  final String none = 'Mahsulot topilmadi';
  final String emptyTitle = 'Doʻkoningiz hali boʻsh';
  final String emptyText =
      'Tayyor katalogdan qoʻshing, faqat narxni yozasiz. Bitta mahsulot 5 soniya oladi.';
  final String fromCatalog = 'Katalogdan qoʻshish';
  final String tipTitle = 'Kamida 20 ta mahsulot qoʻshing';
  final String tipText =
      'Shunda doʻkoningiz mijozlar roʻyxatida yuqoriroq chiqadi.';
  final String create = 'Katalogda yoʻqmi? Oʻzingiz yarating';
  String nowHave(String n) => '$n: bor deb belgilandi';
  String nowGone(String n) => '$n: tugagan deb belgilandi';
}

class ShopAddProduct {
  const ShopAddProduct();
  final String title = 'Mahsulot qoʻshish';
  final String tabCatalog = 'Katalogdan';
  final String tabOwn = 'Oʻzim yarataman';
  final String hint = 'Rasm va nom tayyor, faqat narxni yozasiz';
  final String search = 'Katalogdan qidiring';
  String found(int n) => 'Katalogda $n ta natija';
  String category(String c) => 'Toifa: $c';
  final String yourPrice = 'Sizning narxingiz';
  final String alreadyHave = 'Doʻkoningizda bor';
  final String photo = 'Rasm (ixtiyoriy)';
  final String addPhoto = 'Rasm qoʻshish';
  final String photoOk = 'Rasm tayyor';
  final String name = 'Mahsulot nomi';
  final String namePh = 'Masalan: Uy nonlari';
  final String unit = 'Oʻlchov birligi';
  final String categoryLbl = 'Toifa';
  final String priceLbl = 'Narxi';
}

class ShopPromo {
  const ShopPromo();
  final String title = 'Aksiya qoʻshish';
  final String product = 'Mahsulot';
  String regular(String p) => 'Odatiy narx: $p';
  final String change = 'Oʻzgartirish';
  final String price = 'Aksiya narxi';
  String discount(String sum, int pct) => 'Chegirma: $sum (−$pct%)';
  final String invalid = 'Aksiya narxi odatiy narxdan past boʻlishi kerak';
  final String duration = 'Qancha davom etadi?';
  final String today = 'Bugun';
  final String d3 = '3 kun';
  final String w1 = '1 hafta';
  final String pick = 'Sana tanlash';
  String endsToday(String t) => 'Aksiya bugun $t da avtomatik tugaydi';
  String endsOn(String d) => 'Aksiya $d da avtomatik tugaydi';
  final String preview = 'Mijozlar shunday koʻradi';
  final String publish = 'Aksiyani eʼlon qilish';
  final String live = 'Aksiya darhol xaridorlar lentasida chiqadi';
  final String chooseProduct = 'Mahsulotni tanlang';
  final String published = 'Aksiya eʼlon qilindi';
  final String noProducts = 'Avval mahsulot qoʻshing';
  final String end = 'Aksiyani tugatish';
  final String endHint =
      'Mahsulot odatiy narxga qaytadi. Aksiya xaridorlar lentasidan darhol olinadi.';
}

class ShopSettings {
  const ShopSettings();
  final String title = 'Sozlamalar';
  final String info = 'Doʻkon maʼlumotlari';
  final String name = 'Doʻkon nomi';
  final String phone = 'Telefon';
  final String delivery = 'Yetkazib berish';
  final String selfDeliver = 'Oʻzim yetkazib beraman';
  final String fee = 'Yetkazish narxi';
  final String min = 'Eng kam buyurtma';
  final String radius = 'Yetkazish hududi';
  final String time = 'Yetkazish vaqti';
  final String hours = 'Ish vaqti';
  final String monSat = 'Dushanba – Shanba';
  final String sunday = 'Yakshanba';
  final String vacation = 'Taʼtil rejimi';
  final String vacationSub = 'Doʻkonni bir necha kunga yopish';
  final String staff = 'Xodimlar';
  final String invite = 'Xodim taklif qilish';
  final String tariff = 'Tarif';
  final String tariffName = 'Boshlangʻich';
  final String tariffFree = 'Bepul davr';
  final String tariffText = '1-oktabrgacha bepul, keyin 99 000 soʻm / oy';
  final String free = 'Bepul';
  final String demo = 'Demo';
  final String newShop = 'Yangi doʻkon roʻyxatdan oʻtkazish';
  final String backToDemo = 'Baraka Market (demo) ga qaytish';
  final String approve = 'Demo: administrator sifatida tasdiqlash';
  final String from = 'dan';
  final String to = 'gacha';
  final String minutesHint = 'Masalan: 20–30 daqiqa';
  final String saved = 'Saqlandi';
  final String photo = 'Doʻkon rasmi';
  final String changePhoto = 'Rasmni almashtirish';
  final String uploading = 'Rasm yuklanmoqda…';
  String switchTo(String n) => 'Doʻkonni almashtirish: $n';
  final String everyDay = 'Har kuni';
  final String approved = 'Doʻkon tasdiqlandi, xaridorlar koʻra oladi';

  /// Added for the Android demo: shop mode and buyer mode live in one APK.
  final String backToBuyer = 'Xaridor ilovasiga qaytish';
  final String backToBuyerSub = 'Yaqinda xaridor rejimiga oʻtasiz';
}

class ShopInvite {
  const ShopInvite();
  final String title = 'Xodim taklif qilish';
  final String which = 'Qaysi vazifada ishlaydi?';
  final String seller = 'Sotuvchi';
  final String sellerSub = 'Buyurtma va qoldiq bilan ishlaydi';
  final String courier = 'Kuryer';
  final String courierSub = 'Faqat yetkazib beradi';
  final String sellerCan = 'Sotuvchi nima qila oladi:';
  final List<String> sellerYes = const [
    'Buyurtmani qabul qiladi va rad etadi',
    'Buyurtma holatini oʻzgartiradi',
    'Mahsulotni bor yoki tugagan deb belgilaydi',
  ];
  final List<String> sellerNo = const [
    'Narx va aksiyalarni oʻzgartira olmaydi',
    'Sozlamalar va xodimlarni oʻzgartira olmaydi',
  ];
  final String courierCan = 'Kuryer nima qila oladi:';
  final List<String> courierYes = const [
    'Yetkazish buyurtmalarini koʻradi',
    '“Yetkazildi” deb belgilaydi',
  ];
  final List<String> courierNo = const [
    'Mahsulot va narxlarni oʻzgartira olmaydi',
    'Sozlamalar va xodimlarni oʻzgartira olmaydi',
  ];
  final String link = 'Taklif havolasi';
  final String valid = 'Havola 24 soat amal qiladi va faqat bir marta ishlaydi';
  final String send = 'Telegram orqali yuborish';
  final String after = 'Xodim qoʻshilganda sizga bot orqali xabar keladi';
  final String copied = 'Havola nusxalandi';

  /// Added for the Android demo: the sheet has its own copy button.
  final String copy = 'Nusxalash';
}

class ShopRegStep1 {
  const ShopRegStep1();
  final String title = 'Doʻkoningiz haqida';
  final String sub = 'Keling, avval asosiy maʼlumotlarni kiriting.';
  final String name = 'Doʻkon nomi';
  final String namePh = 'Masalan: Baraka Market';
  final String sells = 'Nima sotasiz?';
  final String phone = 'Telefon raqami';
  final String verified = 'Telegram orqali tasdiqlandi';
  final String share = 'Telegram orqali ulashish';
}

class ShopRegStep2 {
  const ShopRegStep2();
  final String title = 'Doʻkon qayerda?';
  final String sub = 'Xaritada doʻkoningiz joylashuvini belgilang.';
  final String here = 'Doʻkoningiz shu yerda';
  final String hint = 'Xaritani suring, pin doʻkon eshigi ustida tursin.';
  final String address = 'Manzil';
  final String photo = 'Doʻkon rasmi (ixtiyoriy)';
  final String addPhoto = 'Rasm qoʻshish';
}

class ShopRegStep3 {
  const ShopRegStep3();
  final String title = 'Qachon ishlaysiz?';
  final String sub = 'Doʻkoningiz ish vaqtini belgilang.';
  final String sunDiff = 'Yakshanba boshqa vaqtda';
  final String sunDiffSub =
      'Agar yakshanba kunlari ish vaqtingiz boshqacha boʻlsa, yoqing.';
  final String note =
      'Bu vaqtdan tashqari mijozlar buyurtma bera olmaydi. Keyin istalgan payt oʻzgartirasiz.';
}

class ShopRegStep4 {
  const ShopRegStep4();
  final String title = 'Yetkazib berasizmi?';
  final String sub =
      'Mijozlarga qulay boʻlishi uchun yetkazish sozlamalarini tanlang.';
  final String yes = 'Ha, oʻzim yetkazaman';
  final String yesSub = 'Buyurtmalarni oʻzim yetkazib beraman';
  final String fee = 'Yetkazish narxi';
  final String min = 'Eng kam buyurtma';
  final String radius = 'Qancha uzoqqa?';
  final String currency = 'Narxlar soʻmda';
}

class ShopReg {
  const ShopReg();
  String of(int n) => '$n / 4';
  final ShopRegStep1 s1 = const ShopRegStep1();
  final ShopRegStep2 s2 = const ShopRegStep2();
  final ShopRegStep3 s3 = const ShopRegStep3();
  final ShopRegStep4 s4 = const ShopRegStep4();
  final List<String> cats = const [
    'Oziq-ovqat',
    'Non',
    'Meva-sabzavot',
    'Sut',
    'Goʻsht',
    'Boshqa',
  ];
  final String pendingTitle = 'Arizangiz qabul qilindi';
  final String pendingText =
      'Doʻkoningizni 24 soat ichida tekshiramiz va bot orqali xabar beramiz.';
  final String tipTitle = 'Vaqtni tejang';
  final String tipText =
      'Hozirdan mahsulot qoʻshishni boshlang. Tasdiqdan soʻng ular darhol mijozlarga koʻrinadi.';
  final String addProducts = 'Mahsulot qoʻshish';
}

class ShopS {
  const ShopS();
  final String appTitle = 'Yaqinda Doʻkon';
  final ShopNav nav = const ShopNav();
  final ShopCommon common = const ShopCommon();
  final ShopPanel panel = const ShopPanel();
  final ShopOrders orders = const ShopOrders();
  final ShopReject reject = const ShopReject();
  final ShopAvail avail = const ShopAvail();
  final ShopProducts products = const ShopProducts();
  final ShopAddProduct addProduct = const ShopAddProduct();
  final ShopPromo promo = const ShopPromo();
  final ShopSettings settings = const ShopSettings();
  final ShopInvite invite = const ShopInvite();
  final ShopReg reg = const ShopReg();
}

/// The shop app's string table.
const ShopS S = ShopS();

/// The registration category chips map onto the buyer catalog categories.
const Map<String, String> regCategoryIds = {
  'Oziq-ovqat': 'bakaleya',
  'Non': 'non',
  'Meva-sabzavot': 'meva-sabzavot',
  'Sut': 'sut',
  'Goʻsht': 'gosht',
  'Boshqa': 'uy-rozgor',
};
