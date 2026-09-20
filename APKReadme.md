# Yaqinda — Flutter demo APK: build brief for Claude Code

> **Foydalanuvchi uchun (o'zbekcha, qisqa).** Shu `flutter-kit` papkasini butunlay yangi joyga ko'chiring (ichida `APKReadme.md` va `reference/` bor).
> Kompyuteringizda Flutter SDK + Android SDK o'rnatilgan bo'lsin (`flutter doctor` xatosiz). Papkada `claude` ni oching va shuni yozing:
> **"APKReadme.md ni boshidan oxirigacha o'qi, reference/ papkasidagi hamma rasm va fayllarni ko'r, keyin shu bo'yicha ilovani qurib, release APK chiqar."**
> Natija: `build/app/outputs/flutter-apk/app-release.apk` — telefonga o'rnatib demo qilasiz. Internet, server va Telegram kerak emas.

The rest of this document is written for Claude Code. It is a complete brief: read all of it, look at every file in `reference/`, then build.

---

## 1. What to build

A native **Android app in Flutter**, packaged as a **demo APK**, that reproduces the existing "Yaqinda" Telegram Mini App:

- **Yaqinda** — the buyer app (order groceries from neighbourhood shops in Chilonzor, Tashkent).
- **Yaqinda Doʻkon** — the shop-owner app, inside the **same APK** as a second mode. Both modes share one local mock database, so a demo can show a buyer placing an order and the shop accepting it on the same phone.

Ground rules:

| Rule | Detail |
| --- | --- |
| Demo, offline | No backend, no network calls, no Telegram. All data is local (seed data + `shared_preferences`). The release APK must not need the `INTERNET` permission. |
| Language | Uzbek (Latin) only. Strings must be copied **exactly** from `reference/source/uz_latn.ts` (buyer) and `reference/source/strings.ts` (shop). Keep the special apostrophes `ʻ` (U+02BB) and `ʼ` (U+02BC) as they are (`Doʻkon`, `Maʼlumot`). Prices use a non-breaking space (U+00A0): `12 000 soʻm`. |
| Look | Match the reference screenshots as closely as you can (`reference/screens/`). They are the target. Section 5 gives the design tokens. |
| Behaviour | Port the mock server logic (`reference/source/mockApi.ts`, `mockShopApi.ts`) faithfully: same rules, same numbers, same error messages. |
| Admin panel | **Out of scope** (it is a desktop web tool). |
| Scope discipline | Do not invent features. Where this brief is silent, follow the TZ (`reference/TZ-Readme.md`) and the TS sources. If something truly conflicts, decide, then write the decision into `DECISIONS.md`. |

Note: the TZ (section 2) lists "native iOS or Android app" as *explicitly excluded from the MVP*. This APK is a **demo/prototype for presentations only**, not the product. Do not add backend code, accounts, or payment.

### What is in `reference/`

| Path | What it is | How to use it |
| --- | --- | --- |
| `reference/screens/*.png` | The target UI (buyer + shop screens; `newhome.png` is the final Home). File names are random UUIDs. | **Open every image before writing UI code.** Group them yourself (buyer vs shop) and keep a short note of which image drives which screen. |
| `reference/assets-img/` | Product photos, shop photos, illustrations, banner art. | Copy to `assets/img/` and register in `pubspec.yaml`. Names are used in section 6. |
| `reference/source/*.ts` | The original TypeScript: strings, seed data, types, mock APIs, geo/time/search/phone/format helpers. | Source of truth for **logic and exact strings**. Port to Dart (do not import). |
| `reference/TZ-Readme.md` | The full product spec. | Business rules, roles, lifecycle. |

Priority when they disagree: **screens (look) > source .ts (logic, text) > this brief (decisions) > TZ (background)**.

---

## 2. Definition of done

1. `flutter analyze` — no issues.
2. `flutter test` — all pass (test list in section 12).
3. `flutter build apk --release` succeeds and produces `build/app/outputs/flutter-apk/app-release.apk`. Debug-key signing is fine for a demo. Also run `flutter build apk --release --split-per-abi` and report the sizes, but the universal APK is the deliverable.
4. The APK installs on Android 8+ (set `minSdk 24`), runs offline, portrait only, follows the system light/dark theme.
5. The **demo script** (section 13) works end to end.
6. A short `README.md` in the project: how to build, how to reset demo data, known limitations. A `DECISIONS.md` for deviations.
7. Be honest in your final report: if you could not run the app on an emulator/device, say so and do not claim the UI matches the references. If you could, save screenshots to `docs/screens/`.

---

## 3. Technical decisions

- Flutter stable, Dart 3, Material 3 with a **fully custom theme** (do not leave default Material colours visible).
- Packages (keep it small; add nothing else without a reason written in `DECISIONS.md`):
  `flutter_riverpod` (state), `go_router` (navigation), `shared_preferences` (persistence), `url_launcher` (call the shop: `tel:`), `uuid`, `flutter_launcher_icons` (dev), and optionally `geolocator` (address auto-detect) and `image_picker` (shop photo; the demo may keep the picked image only locally).
- Fonts: **Figtree** (weights 400, 500, 600, 700, 800) bundled in `assets/fonts/` (download once from Google Fonts at dev time). If unavailable, fall back to Roboto. Verify that `ʻ` and `ʼ` render as proper glyphs. Emoji use the system emoji font.
- Icons: outline style, ~1.8 px stroke look. Use `Icons.*_rounded` or a bundled line-icon set. The original icon names are in section 5.4.
- Pure logic (`core/`, `data/`) has **no Flutter imports** so it is unit-testable. UI reads state through Riverpod.
- Time zone: Tashkent is UTC+5 all year. Implement it as a fixed offset exactly like `reference/source/time.ts` (no `timezone` package). All "today / tomorrow / weekday" logic uses it.
- Money: integers in soʻm. Never `double` for prices.
- Persistence: two JSON blobs in `shared_preferences`: (a) app state (user, addresses, cart, onboarded flag, recent searches, active address id), (b) mock database (orders, shop overlays, product overrides, promos, staff, new shops, counters). Wrap every read/write in try/catch and keep an in-memory copy.

### Telegram → Android replacements

| Telegram Mini App | In the APK |
| --- | --- |
| Telegram header (Yopish / Orqaga / title / ⋯) | Normal Flutter `AppBar` with back arrow where the original showed "Orqaga". No fake Telegram bar. |
| MainButton | A full-width primary button pinned above the safe area (same label as the original MainButton). |
| BackButton | Android back gesture + AppBar back; system back on root tabs exits the app. |
| `requestContact()` | Not available: the phone step shows the manual input only (+998 mask, operator-code validation). The "Raqamni ulashish" button is not shown. `phoneVerified = false`, so Profil shows "Tasdiqlanmagan". |
| Haptics | `HapticFeedback.selectionClick()/lightImpact()` on taps of steppers, chips, primary buttons. |
| Bot notifications | Not built. Order status changes show as in-app toasts/snackbars while the app is open, and the Orders/Home cards update by polling (every 15 s, plus immediately on resume). *Optional stretch:* local notifications with `flutter_local_notifications`, off by default. |
| Open Telegram support chat ("Yordam") | Show a simple bottom sheet with the support handle text `@YaqindaSupport` (placeholder) and a "Nusxalash" (copy) action. No network. |
| Shop invite link, share | `Clipboard` copy + Android share sheet is optional; copying is enough. |

---

## 4. Project structure

```
lib/
  main.dart
  app/            router.dart, theme.dart, shell_buyer.dart, shell_shop.dart
  core/           format.dart, time.dart, geo.dart, phone.dart, search.dart, ids.dart, strings_buyer.dart, strings_shop.dart
  data/           models.dart, seed.dart, mock_db.dart, mock_api.dart, mock_shop_api.dart, prng.dart
  state/          app_state.dart (user, addresses, cart, recent searches), providers.dart
  features/
    onboarding/   4 steps + legal pages
    home/         home page, banners, active order card, repeat card
    shops/        shops list, shop page
    category/     category page
    search/       search page
    promotions/   promotions page
    cart/         cart + checkout
    orders/       orders list, order tracking
    profile/      profile
    sheets/       product, address, choice, confirm, partial-fulfilment
    widgets/      buttons, chips, product cards, status tags, skeletons, empty/error states, toasts
  shop_mode/      panel, orders, products, add_product, promo, settings, register, pending, sheets
assets/img/  assets/fonts/
test/
```

---

## 5. Design system

The look is a soft mint page, white rounded cards with gentle shadows, a fixed brand green and a coral accent for discounts. Compare with `reference/screens/newhome.png` first.

### 5.1 Colour tokens

| Token | Light | Dark |
| --- | --- | --- |
| `bg` / `surface` | `#FFFFFF` | `#1D2834` (surface), `#151E28` (bg) |
| `card` (grouped background) | `#F1F4F3` | `#26333F` |
| `text` | `#0E1442` | `#F2F5F8` |
| `hint` | `#6D7192` | `#9AA8B8` |
| `accent` (brand green) | `#07AB59` | `#2FC172` |
| `accentText` (on accent) | `#FFFFFF` | `#08170F` |
| `accentSoft` | `#E4F9EE` | `#1B3A2B` |
| `accentInk` (green text on soft) | `#0B8A48` | `#5FDC98` |
| `mint` | `#D8F9E8` | `#1F4636` |
| `peach` | `#FEEFEB` | `#3A2A27` |
| `coral` (promo price) | `#EE4327` | `#FF7A5F` |
| `badge` (−N% tag, dots) | `#FF5B3A` | `#FF6A4A` |
| `danger` | `#E5484D` | `#E5484D` (lighten if needed) |
| `warn` | `#C2751A` | `#F0B34A` |
| `border` | `rgba(14,20,66,.08)` | `rgba(255,255,255,.09)` |
| `photoBg` | `#F0EFEF` | `#2A3744` |
| page gradient | top `#DAF7E9` → bottom `#F6FCF9` over the first ~460 px, then flat | top `#163229` → bottom `#0F1720` |
| shadow | `0 2 6 rgba(20,60,50,.05)` + `0 8 24 rgba(20,60,50,.07)` | black at .30 / .25 |

Banner gradients on Home (angle ~100°): **coral** `#FD9779 → #FEC49C → #FEC9A0`, tag/CTA `#E0454F`; **amber** `#FFB27B → #FFD8A6 → #FFE7C4`, tag/CTA `#DD6F2A`, text `#4A2A12`; **mint** `#B7ECD0 → #D9F7E6 → #EAFBF2`, tag/CTA `#0AA457`, text `#0E1442`.

Status tag colours: green = success/active, amber `#F59E0B` on 18 % tint = "needs confirmation", red = rejected/cancelled/expired, grey = neutral. Shop logo circle colours per shop are in section 6.3.

### 5.2 Shape, spacing, typography

- Radii: cards 16–22, banners 22, buttons 14 (small 12), chips/pills full-round, bottom sheets top 24, circle avatars 50 %, mini product cards 12.
- Screen side padding 16. Vertical rhythm 12–16 between sections. Tap targets ≥ 44 dp.
- Type (Figtree): H1 20–22/800 (letter-spacing −0.4), H2 18/800, section title 17–18/800, body 15–16/400–500, small 12–13, captions 10.5–11.5. Prices 14–15/700; promo price coral, old price struck through in hint colour.
- Primary button: height 50, radius 14, accent fill, label 15.5/600. Variants: small (38 h), outline (accent border 1.5), grey, mint, danger; disabled = 50 % opacity.
- Bottom navigation: floating white pill, 12 dp side margin, 10 dp bottom margin, radius 26, shadow `0 8 28 rgba(20,60,50,.16)`, **5 items**: Bosh sahifa, Doʻkonlar, Savat, Buyurtmalar, Profil. Active item is accent-coloured, bold, with a filled icon; the Savat item shows a small accent count badge (white ring). Labels 10–10.5 sp.
- Skeleton placeholders while loading; every screen has loading, empty and error (with "Qayta urinish") states.

### 5.3 Reusable components

Category/filter **chips**; **MiniProduct** card (photo on `photoBg`, green discount tag top-right, name, shop name in hint, price); **PromoCard** (photo, `−N%` badge, name, coral price + struck old price, shop · distance, clock line "Bugun 23:00 gacha"); **ShopRow** (logo circle, name, distance, open/closed tag, delivery info, promo count); **ShopCircle** (48 dp coloured circle with white line icon + 2-line label, closed = 55 % opacity); **Stepper** (− n +); **StatusTag**; **Toast** (top/bottom snackbar, success/error); **BottomSheet** scaffold; **EmptyState** (illustration, title, text, CTA).

### 5.4 Icon names used by the original (map to your icon set)

search, chevron-right/down, back, close, plus, minus, check, pin, truck/scooter, walk, bag, cash, phone, tag, bell, sliders, heart, arrow-right, calendar, clock, shield, info, box, check-circle, x-circle, clipboard, store, user, home, more, card, trash, headset, briefcase, chat, repeat, cart, percent, bread, leaf, milk-bottle, meat, moon, soap, coins, eye, pencil, sparkle, share, copy, settings, inbox, grid, crown, bulb, palm-tree (vacation), camera, send, help.
Shop icon keys (`ShopView.icon`): `cart, bread, leaf, milk, meat, moon, bag, soap, store`.

### 5.5 Images (`assets/img/`)

Product photos (mapped by catalog id in 6.4): `banan, pomidor, sut2, tovuq, tuxum, bodring, kartoshka, piyoz, olma, patir, uzum, tvorog, cola, yog` (all `.png`). Shop photos: `shop-baraka, shop-yangi-non, shop-meva-bogi, shop-qassob, shop-oila` (`.png`). Banners/illustrations: `hero-basket.jpg` (Home coral banner), `bag.png` (mint banner), `patir.png` + `sut2.png` (amber banner "duo"), `basket.png`, `empty-cart.png`, `empty-orders.png`, `outside.png` (outside service area), shop-mode art `so-box, so-counter, so-shelf, so-pending` (`.png`) and `so-map.jpg` (static map image standing in for a real map). Files missing a photo fall back to an emoji tile.

---

## 6. Data (seed)

Port `reference/source/seed.ts` exactly (descriptions are there). Summary:

### 6.1 Categories (id → name)
`sut` Sut · `non` Non · `meva-sabzavot` Meva-sabzavot · `gosht` Goʻsht · `ichimlik` Ichimlik · `bakaleya` Bakaleya · `uy-rozgor` Uy-roʻzgʻor.
Category chips everywhere: "Hammasi" + these seven.

### 6.2 Shared catalog (id · name · unit · category · emoji · base price soʻm)

| id | name | unit | cat | emoji | price |
| --- | --- | --- | --- | --- | --- |
| sut-1l | Sut 2,5% (1 l) | dona | sut | 🥛 | 12000 |
| qatiq | Qatiq (500 g) | dona | sut | 🥣 | 9000 |
| smetana | Smetana (400 g) | dona | sut | 🍶 | 18000 |
| tvorog | Tvorog (300 g) | dona | sut | 🧀 | 16000 |
| kefir | Kefir (1 l) | dona | sut | 🥛 | 13000 |
| sariyog | Sariyogʻ (200 g) | dona | sut | 🧈 | 24000 |
| pishloq | Pishloq | kg | sut | 🧀 | 85000 |
| non | Non | dona | non | 🍞 | 4000 |
| patir | Patir | dona | non | 🥯 | 6000 |
| lavash | Lavash | dona | non | 🫓 | 3000 |
| bulochka | Bulochka | dona | non | 🥐 | 3500 |
| baton | Baton | dona | non | 🥖 | 5500 |
| olma | Olma | kg | meva-sabzavot | 🍎 | 14000 |
| banan | Banan | kg | meva-sabzavot | 🍌 | 18000 |
| pomidor | Pomidor | kg | meva-sabzavot | 🍅 | 12000 |
| bodring | Bodring | kg | meva-sabzavot | 🥒 | 9000 |
| kartoshka | Kartoshka | kg | meva-sabzavot | 🥔 | 6000 |
| piyoz | Piyoz | kg | meva-sabzavot | 🧅 | 5000 |
| sabzi | Sabzi | kg | meva-sabzavot | 🥕 | 5500 |
| uzum | Uzum | kg | meva-sabzavot | 🍇 | 25000 |
| limon | Limon | kg | meva-sabzavot | 🍋 | 22000 |
| mol-gosht | Mol goʻshti | kg | gosht | 🥩 | 95000 |
| tovuq | Tovuq goʻshti | kg | gosht | 🍗 | 38000 |
| qiyma | Qiyma | kg | gosht | 🥩 | 85000 |
| kolbasa | Kolbasa | kg | gosht | 🌭 | 62000 |
| suv | Suv (1,5 l) | dona | ichimlik | 🚰 | 3500 |
| cola | Coca-Cola (1,5 l) | dona | ichimlik | 🥤 | 11000 |
| choy | Qora choy (100 g) | quti | ichimlik | 🍵 | 14000 |
| sharbat | Sharbat (1 l) | dona | ichimlik | 🧃 | 15000 |
| guruch | Guruch | kg | bakaleya | 🍚 | 16000 |
| un | Un | kg | bakaleya | 🌾 | 8000 |
| shakar | Shakar | kg | bakaleya | 🍬 | 14000 |
| makaron | Makaron (400 g) | dona | bakaleya | 🍝 | 8000 |
| yog | Kungaboqar yogʻi | l | bakaleya | 🌻 | 24000 |
| tuz | Tuz (1 kg) | dona | bakaleya | 🧂 | 3000 |
| tuxum | Tuxum (10 ta) | quti | bakaleya | 🥚 | 16000 |
| idish-yuvish | Idish yuvish vositasi | dona | uy-rozgor | 🧴 | 18000 |
| kir-kukun | Kir yuvish kukuni | quti | uy-rozgor | 🧼 | 38000 |
| sovun | Sovun | dona | uy-rozgor | 🧼 | 5000 |
| salfetka | Salfetka | quti | uy-rozgor | 🧻 | 6000 |
| wc-qogoz | Hojatxona qogʻozi | quti | uy-rozgor | 🧻 | 22000 |

Units: `dona`, `kg`, `l`, `quti`. Product title helper: for `kg`/`l` the title shows ", 1 kg"/", 1 l" (`productTitle` in `format.ts`).

### 6.3 Shops (8)

| id | name | type | emoji | phone | lat, lng | delivers | fee | min order | radius m | delivery time | hours | manual open | categories |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| baraka | Baraka Market | Oziq-ovqat doʻkoni | 🛒 | +998 71 200 11 22 | 41.2765, 69.2055 | yes | 8000 | 40000 | 2500 | 30–40 daqiqa | 07:00–23:00 | yes | sut, non, meva-sabzavot, ichimlik, bakaleya, uy-rozgor |
| nonvoy | Yangi Non | Nonvoyxona | 🥖 | +998 90 111 22 33 | 41.272, 69.201 | yes | 5000 | 20000 | 1500 | 20–30 daqiqa | 06:00–21:00 | yes | non, sut, ichimlik |
| sabzavot | Meva Bogʻi | Meva-sabzavot doʻkoni | 🥬 | +998 93 222 33 44 | 41.28, 69.21 | yes | 10000 | 50000 | 3000 | 40–50 daqiqa | 07:00–20:00 | yes | meva-sabzavot · **partialOrders** |
| sut-olami | Sut Olami | Sut mahsulotlari doʻkoni | 🥛 | +998 94 333 44 55 | 41.269, 69.198 | **no** | 0 | 0 | 0 | — | 07:00–22:00 | yes | sut, non, ichimlik |
| gosht | Qassob Karim | Goʻsht doʻkoni | 🥩 | +998 97 444 55 66 | 41.2745, 69.207 | yes | 12000 | 80000 | 2000 | 45–60 daqiqa | 08:00–20:00 | **no (switched off)** | gosht, bakaleya |
| tungi | Tungi doʻkon 24/7 | Oziq-ovqat doʻkoni | 🌙 | +998 88 555 66 77 | 41.2785, 69.2 | yes | 15000 | 30000 | 2000 | 25–35 daqiqa | 00:00–24:00 | yes | all 7 |
| yashil | Nodira opa doʻkoni | Meva-sabzavot doʻkoni | 🍎 | +998 99 666 77 88 | 41.285, 69.222 | yes | 9000 | 40000 | 1500 | 35–45 daqiqa | 08:00–21:00 | yes | meva-sabzavot, ichimlik |
| oila | Oila Doʻkoni | Uy-roʻzgʻor doʻkoni | 🧼 | +998 91 777 88 99 | 41.274, 69.2075 | yes | 7000 | 25000 | 1800 | 30–40 daqiqa | 00:00–24:00 | yes | uy-rozgor, bakaleya, ichimlik · **rejectsOrders** |

Shop look (address · logo colour · photo · icon key):
`baraka` Chilonzor, 9-mavze, 12-uy · `#12a05a` · shop-baraka.png · cart — `nonvoy` Chilonzor, 7-mavze, Bunyodkor koʻchasi 4 · `#f59a2f` · shop-yangi-non.png · bread — `sabzavot` Chilonzor, 10-mavze, Bozor yonida · `#3fb24d` · shop-meva-bogi.png · leaf — `sut-olami` Chilonzor, 6-mavze, 21-uy · `#3f8cf0` · (no photo) · milk — `gosht` Chilonzor, 8-mavze, 3-uy · `#e5546b` · shop-qassob.png · meat — `tungi` Chilonzor, 9-mavze, Qatortol koʻchasi 30 · `#5b5bd6` · (no photo) · moon — `yashil` Chilonzor, 14-mavze, 5-uy · `#a06be0` · (no photo) · bag — `oila` Chilonzor, 9-mavze, 18-uy · `#ff6f5e` · shop-oila.png · soap.

Demo behaviours tied to shops: **Oila Doʻkoni always rejects** after 10 s with reason "Mahsulot tugagan" (shows the rejected path). **Meva Bogʻi** with an order of ≥ 2 lines runs the "Baʼzi mahsulotlar tugagan" partial-fulfilment flow (first line unavailable). **Qassob Karim** is switched off (closed). Extra optional fields exist in `SeedShop`: `sunOpensAt/sunClosesAt` (Sunday hours), `vacation`, `pending`.

### 6.4 Product photos, popular list

`PHOTOS` (catalog id → file): banan→banan.png, pomidor→pomidor.png, sut-1l→sut2.png, tovuq→tovuq.png, tuxum→tuxum.png, bodring→bodring.png, kartoshka→kartoshka.png, piyoz→piyoz.png, olma→olma.png, patir→patir.png, uzum→uzum.png, tvorog→tvorog.png, cola→cola.png, yog→yog.png.
`POPULAR_IDS` = banan, pomidor, sut-1l, tuxum, bodring, kartoshka, piyoz, olma, tovuq, patir, uzum, tvorog. "Ommabop" = for each id, the cheapest in-stock item across **open, in-range** shops.

### 6.5 Deterministic per-shop products (must match the web app)

For each shop (index `si`) create `r = mulberry32(1000 + si * 97)`. For each catalog item **whose category is in the shop's categories**, in catalog order:

1. `always = id in {sut-1l, non}`. If `!always` and `r() > 0.8` → the shop does not sell it (skip). *(`r()` is not called when `always`.)*
2. `price = roundTo(basePrice * (0.92 + r() * 0.2), basePrice >= 20000 ? 1000 : 500)`, where `roundTo(n, step) = max(step, round(n/step)*step)`.
3. `inStock = always ? true : r() > 0.1`. *(`r()` not called when `always`.)*
4. If `inStock` and `r() < 0.24`: create a promotion: `promoPrice = min(price - 100, roundTo(price * (0.7 + r() * 0.2), 100))`; `d = r()`; `endsAt = d < 0.4 ? (today 23:00 Tashkent; if less than 1 h away then now + 3 h) : d < 0.7 ? now + 3 days : now + 7 days`; `startsAt = now − 1 h` (`now` = app start).
Product id = `"<shopId>:<catalogId>"`. Match the `r()` call order exactly.

```dart
int imul(int a, int b) => ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF; // Dart VM ints are 64-bit, low 32 bits are exact
double Function() mulberry32(int seed) {
  var a = seed & 0xFFFFFFFF;
  return () {
    a = (a + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = imul(a ^ (a >>> 15), 1 | a);
    t = ((t + imul(t ^ (t >>> 7), 61 | t)) & 0xFFFFFFFF) ^ t;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296;
  };
}
```
Unit-test the sequence against a few values computed with the TS version (`node -e`), if Node is available.

---

## 7. Rules and algorithms (port exactly from the `.ts` files)

**Distance** — Haversine, R = 6371 km; shown to 0.1 km; `formatKm`: under 1 km as metres ("300 m"), else "1.2 km" (`geo.ts`, `format.ts`). Service area: circle of 5 km around Chilonzor (41.2756, 69.2043). District centroids and `coordsForManualAddress` (stable hash offset, ±~400 m) are in `geo.ts`.

**Open state** (`openState` in `mockApi.ts`): uses Tashkent minutes and weekday (0 = Monday … 6 = Sunday); Sunday may use `sunOpensAt/sunClosesAt`. Closed if `manualOpen == false` or on vacation (no label). Before opening: label "`HH:MM` da ochiladi". After closing: "ertaga `HH:MM` da ochiladi". Shop with 00:00–24:00 shows hours label "Kuniga 24 soat", else "`08:00`–`20:00`".

**Visibility / range**: a delivering shop is `inRange` only if the buyer is inside its delivery radius (`canDeliverHere`); a pickup-only shop is in range within 3 km. Lists show only in-range shops, sorted **open first, then nearest**. Pending shops are hidden.

**Promotions**: active if `startsAt ≤ now < endsAt`; shop card counts only in-stock promoted products. Promotions feed: only open, in-range shops and in-stock products, sorted by discount % descending; category filter; limit 10 on Home. Discount % = `round((regular − promo)/regular*100)`. Time left: same day → "Bugun HH:MM gacha", else "N kun qoldi" (`time.ts`).

**Search** (`search.ts`): normalise (lower-case, Cyrillic→Latin map, drop `ʻ ʼ ' ’`, non-alphanumerics→space, collapse repeated letters so "sutt"→"sut"). Token scoring: prefix 0, contains 1, Levenshtein ≤ 1 on prefix (query ≥ 3 chars) or whole token (≥ 4 chars) 2; every query token must match; total = sum. Shops match name + type. Products match name, or category name (score 3). Results: out-of-stock sink to the bottom, then sort by chosen sort (`distance` default, `price`, `discount`), relevance breaks ties. Debounce 300 ms, minimum 2 chars, keep the last 5 searches.

**Phone** (`phone.ts`): 9 national digits after +998, operator code in `20,33,50,55,77,88,90,91,93,94,95,97,98,99`; mask "90 123 45 67"; stored as `+998901234567`; displayed `+998 90 123 45 67`.

**Cart** (`useStore.ts`): one cart = one shop; adding from another shop opens the "Savatni yangilaysizmi?" confirm (`cf.*` strings) and, on yes, replaces the cart. Max quantity per line 99; stepper − to 0 removes the line; removing the last line empties the cart (shop reset). Lines remember `priceAtAdd`. Comment max 200 chars. Max **5** saved addresses (`address.max`). Fulfilment: delivery (disabled with `cart.noDelivery` if the shop does not deliver, `cart.outOfRadius` if outside radius) or pickup ("Oʻzim olaman"). Payment: cash only ("Naqd pul", "Yetkazilganda toʻlaysiz"/"Olib ketganda toʻlaysiz"; "Karta orqali toʻlov tez orada").

**Cart validation / checkout** (`validate` + `createOrder`): re-check on the "server" — shop closed → `shop_closed`; each line out of stock → `out_of_stock`; price differs from `priceAtAdd` → `price_changed` (from → to); delivery: outside radius → `delivery_unavailable`, else below minimum → `min_order` (missing amount). Blocking issues disable the button and show the messages `cart.issue.*`; "Savatni yangilash" refreshes prices/stock from `fresh`. Order creation requires an idempotency key (a repeated key returns the same order), max **5 orders per hour** (`RATE_LIMITED` message in source), and the abuse rule (3 cancelled/expired pickups in 30 days + an active order → `ACTIVE_ORDER_LIMIT`). Order stores snapshots of name, unit, price, regularPrice. Order numbers start at **1042** and increase. Delivery fee is 0 for pickup. `total = itemsTotal + deliveryFee`.

**Order lifecycle & demo timeline** (`toOrder`): statuses `new, accepted, confirm, preparing, on_the_way, ready, completed, rejected, cancelled, expired`. Automatic (non-manual) demo shops play out in ms since creation: decide 10 s → accepted; preparing at 25 s; dispatch at 50 s (`on_the_way` for delivery, `ready` for pickup); completed at 80 s. Oila Doʻkoni → rejected at 10 s ("Mahsulot tugagan"). Meva Bogʻi (≥ 2 lines) → `confirm` at 10 s with `changes {oldTotal, newTotal (without the first line), deadline = +5 min}`; the buyer confirms (timeline continues as if accepted) or declines (cancelled); no answer in 5 min → cancelled. Cancel by the buyer only while `new` (`ORDER_NOT_CANCELLABLE` otherwise). Unanswered `new` in manual mode expires after 10 min. ETA for delivery = upper bound of the shop's delivery time text ("30–40 daqiqa" → 40 min). "Takrorlash" re-adds available items of a completed order to the cart (messages `orders.repeated*`).

**Shop mode drives orders** (`mockShopApi.openShopApp`): the first time shop mode is opened, `shopManual = true` (orders for Baraka Market now wait for the shop's actions instead of the automatic timeline) and three orders from other customers are created once (Azizbek on the way, Sardor new pickup, Dilnoza new delivery with the comment "Domofon ishlamaydi, qoʻngʻiroq qiling"). Those are `foreign` (hidden from the buyer's list). Shop actions: accept → pack ("Yigʻishni boshlash") → dispatch ("Kuryerga berildi"/"Tayyor deb belgilash") → complete; reject with a reason (4 preset reasons); "Nechta bor?" availability sheet (per-line available quantity → buyer gets a `confirm` with new total, 5 min). Read `mockShopApi.ts` for every function: products list/stock/price, catalog quick-add, custom product, promotions (max 20 active, promo price must be below regular price: "Aksiya narxi odatiy narxdan past boʻlishi kerak"), stats (Baraka shows demo figures: 12 orders / 1 240 000 soʻm today baseline, yesterday 11 / 1 120 000, 312 views), settings, registration (a new shop is `pending`, hidden from buyers until "Demo: administrator sifatida tasdiqlash"), staff invite (24 h, single use, mocked link), shop switching.

**Mock API surface to port** — buyer (`mockApi.ts`): `getCategories, getShops, getShop, getShopProducts, getProducts(ids), getPromotions, getPopular, getCategoryProducts, search, validateCart, createOrder, listOrders, getOrder, cancelOrder, confirmChanges, onboard (no-op), joinWaitlist, deleteAccount`. Shop (`mockShopApi.ts`): `openShopApp, myShops, listOrders, actOnOrder, listProducts, setStock, setPrice, searchCatalog, addFromCatalog, createCustom, createPromo, endPromo, promoEnd, getStats, getSettings, saveSettings, registerShop, approveShop, listStaff, removeStaff, createInvite` and the active-shop helpers. In the web app the two mock APIs share one `localStorage` database; in Flutter they share one `MockDb` instance (persisted as JSON).

**Time formats** (`time.ts`): `hhmm`, "Bugun, 14:05"/"Kecha, 14:05"/"19.09, 14:05" for order times, "19-sen", "19-sentabr".

**Errors**: reuse the Uzbek messages of `ApiError` in `mockApi.ts`. Simulated latency: 100–300 ms per call (orders 300–600 ms) so loading states are visible.

---

## 8. Buyer screens

Use the reference images for layout; the list below gives content, behaviour and which string keys apply (`reference/source/uz_latn.ts`).

**Router (go_router).** `/onboarding`, `/legal/:doc`; shell with the 5-tab bottom nav: `/` Home, `/shops`, `/cart`, `/orders`, `/profile`; pushed routes: `/search`, `/promotions`, `/shop/:id`, `/category/:id`, `/orders/:id`. Until `onboarded` is true, everything redirects to `/onboarding`. Unknown routes → `/`.

1. **Onboarding (4 steps, first launch).** Progress bar; back goes to the previous step. (1) Welcome: `onb.welcome.*` (headline "Yaqin doʻkonlar, bir bosishda", 3 benefits, "Boshlash", terms line with links to the Legal pages). (2) Phone: `onb.phone.*`, manual input with +998 mask and operator validation ("Raqam notoʻgʻri. Operator kodini tekshiring"). (3) Name: 2–30 characters (`onb.name.*`). (4) Address: "Joylashuvimni aniqlash" (geolocator; on failure `address.detectFailed`) or "Qoʻlda kiritish" (district picker from `DISTRICTS`, street & building, apartment, landmark; validation `address.tooShort`). If the address is outside the 5 km service area: `onb.outside.*` with "Ha, xabar bering" (waitlist, toast `onb.waitlistDone`) and "Baribir koʻrish". Finish → Home.
2. **Home** (`newhome.png`). Top: small "Salom!", H1 "Yaqin atrofingizdagi mahsulotlar"; address row (pin, "`District` tumani, `street`", chevron) → Address sheet. Search box with a sliders button (opens the categories choice sheet → `/category/:id`); tapping the field → `/search`. If there are active orders: the live-order card (accent border, icon with pulse, "Buyurtma #N · status", 4-segment progress, "+N ta faol buyurtma") → tracking. Banner carousel (3 slides, 182 dp, auto-advance every 5 s, pauses 10 s on touch, "1/3" counter, dots): **promo** (coral, hero-basket.jpg, → /promotions), **fresh** (amber, patir+sut2 "duo", → /shops), **fast** (mint, bag.png, → /shops); strings `hb.*`. "Doʻkonlar" row: horizontally scrolling shop circles + a final "Boshqa" grid tile, "Barchasini koʻrish" → /shops. "Mahsulotlar": 4-column grid of up to 8 popular mini cards (tap opens the Product sheet). "Bugungi aksiyalar" (only if any): horizontal PromoCards (up to 8), "Barchasini koʻrish" → /promotions. If the last order is completed and nothing is active: repeat card ("Yana shuni buyurtma qilasizmi?" + "Takrorlash"). Outside service area: the `out.*` empty state with `outside.png`. Orders refresh every 15 s.
3. **Doʻkonlar** (`shops.*`): search field "Doʻkon nomini qidiring", count line "N ta doʻkon · eng yaqini birinchi", ShopRows (open/closed tag, "`HH:MM` da ochiladi", "Yetkazish {sum}" or "Faqat olib ketish", "N ta aksiya").
4. **Shop page** (`sp.*`, `shop.*`): header with photo/logo, name, type, hours ("Ochiq · 23:00 gacha"), facts (distance, delivery time, delivery fee or "Bepul", "Eng kami {sum}"); promotions strip; category chips limited to the shop's categories; 2-column product grid, in stock first and promotions first; out-of-stock cards say "Hozir tugagan"; closed shop shows the closed banner and "Doʻkon yopiq" instead of add buttons; floating cart bar "Savat · N ta" + total → cart.
5. **Category** (`/category/:id`): products of that category across in-range shops (`getCategoryProducts`), empty state `cat.empty`.
6. **Search** (`search.*`, `se.*`): field autofocus, recent searches (max 5, "Tozalash"), min-chars hint, two groups "Doʻkonlar" and "Mahsulotlar", sort chips (`search.sort.*`), empty state `search.empty` + hint, summary `se.summary`.
7. **Aksiyalar** (`promos.*`, `pr.*`): summary "Atrofingizdagi doʻkonlarda hozir N ta chegirma bor", category chips, grid of PromoCards sorted by discount ("Eng katta chegirmalar birinchi").
8. **Savat** (`sv.*`, `cart.*`, `co.*`): shop header; line items with photo, name, price, stepper; "Qanday olasiz?" (Yetkazib berish / Oʻzim olaman) segmented control; address card (delivery) → Address sheet, landmark line; cash payment card; comment field (placeholder `sv.note`, max 200); summary (Mahsulotlar, Aksiya chegirmasi, Yetkazish, Jami); blocking issues in a warning card with "Savatni yangilash"; primary button "Buyurtma berish · {sum}" (double-tap safe: disable while sending, one idempotency key per checkout); success → toast "Buyurtma #N yuborildi" and go to tracking. Empty state `sv.empty*` with promo count line.
9. **Buyurtmalar** (`od.*`, `orders.*`): status tabs (Barchasi / Yetkazilgan / Jarayonda / Bekor), sort choice (`orders.sort.*`), sections "Faol" and "Oldingilar"; card: shop, `#N`, time, status tag, progress segments, first items + "yana N ta mahsulot", fulfilment, total; actions "Doʻkonga qoʻngʻiroq" (tel:), "Bekor qilish" (only `new`, with confirm), "Takrorlash" (completed). Empty state `od.empty*`. Poll every 15 s.
10. **Buyurtma kuzatuvi** (`ot.*`, `trk.*`): title "Buyurtma #N", status headline + text per status (`trk.msg.*`), vertical/segmented stepper (Qabul qilindi → Yigʻilmoqda → Yoʻlda/Tayyor → Yetkazildi/Olib ketildi), ETA ("{a}–{b} orasida yetkaziladi"), shop card with call button, address / pickup location, items, payment line, totals. Statuses `rejected` (with reason), `expired`, `cancelled` have their own messages. `confirm` shows the **partial-fulfilment card/sheet** (`pc.*`: "Baʼzi mahsulotlar tugagan", old vs new total, countdown "Javob berish uchun {t} qoldi", "Tasdiqlash · {sum}", "Buyurtmani bekor qilish").
11. **Profil** (`pf.*`, `profile.*`): name + phone with "Tasdiqlanmagan" tag, "Tahrirlash"; "Mening manzillarim" (add, edit, delete with confirm, "Asosiy qilish", max 5); Til row "Oʻzbekcha (lotin)"; Yordam; Foydalanish shartlari; Maxfiylik siyosati (Legal pages use `legal.*`); **"Doʻkoningiz bormi? Yaqindaga bepul qoʻshiling"** card → opens **shop mode**; "Hisobni oʻchirish" (confirm; wipes app state and mock DB, back to onboarding); version "Yaqinda 1.0".
12. **Sheets** (bottom sheets): **Product** (`ps.*`: large photo, name/unit, price + old price, promo end, description, shop line "Doʻkonga oʻtish", quantity stepper, "Savatga qoʻshish · {sum}" or "Tugagan"/"Doʻkon yopiq"); **Address** (`address.*`: select from saved + add/edit form with label Uy/Ish/Boshqa, district, street, apartment, landmark); **Choice** (generic list); **Confirm** (yes/no); **Replace cart** (`cf.*`); **Partial confirm** (`pc.*`).

State that survives restarts: onboarded flag, user, addresses (+ active address), cart, recent searches, mock DB.

---

## 9. Shop mode ("Yaqinda Doʻkon")

A separate shell (own bottom nav with 4 tabs: **Panel, Buyurtmalar, Mahsulotlar, Sozlamalar**), reached from Profil → "Doʻkoningiz bormi?". Strings: `reference/source/strings.ts` (object `S`). Add one new string for switching back: Sozlamalar → "Xaridor ilovasiga qaytish" (put it in the Demo group). Design goal from the TZ: a shop owner accepts an order or posts a promotion in under 30 seconds. Visual style: the same tokens, plus the illustrations `so-*.png`.

- **Panel**: open/closed switch card ("Doʻkon ochiq"/"Doʻkon yopiq"); alert card "{n} ta yangi buyurtma kutyapti" + "Eng eskisi {m} daqiqa oldin kelgan" + "Koʻrish"; large "Aksiya qoʻshish" card ("30 soniyada: mahsulot, yangi narx, muddat"); "Bugun" stats grid (Buyurtmalar, Tushum, Doʻkonni koʻrganlar, Faol aksiyalar) with "Kechagidan …" deltas (hide the delta when yesterday is 0); "Aksiyalar tufayli"/"Eng yaxshisi"; quick link "Qoldiqni yangilash"; when the shop is pending: "Tekshirilmoqda" card (`so-pending.png`).
- **Buyurtmalar**: sections Yangi / Jarayonda / Yakunlangan; new-order cards have a highlighted border and "N daq kutyapti"; card body: `#N`, buyer first name, fulfilment, cash, items with prices, address + "Moʻljal", comment, total. Buttons by status: `new` → "Qabul qilish", "Rad etish", "Baʼzi mahsulot yoʻqmi?"; `accepted` → "Yigʻishni boshlash"; `preparing` → "Kuryerga berildi" (delivery) / "Tayyor deb belgilash" (pickup); `on_the_way`/`ready` → "Yetkazildi"/"Olib ketildi"; `confirm` → "Mijoz tasdiqlashini kutyapmiz"; "Mijozga qoʻngʻiroq" (tel:). **Reject sheet** (`S.reject`): 4 reasons, tip card offering "Baʼzi mahsulot yoʻq deb belgilash", preview of the buyer message, "Buyurtmani rad etish". **Availability sheet** ("Nechta bor?", `S.avail`): per line stepper "Hammasi bor / N ta kam / Yoʻq", old vs new total, note about 5 minutes, "Mijozga yuborish · {sum}". Stale action → `S.orders.errStale`. Play a short sound/vibration when a new order arrives while the screen is open (optional, `HapticFeedback` is enough).
- **Mahsulotlar**: search, chips (Hammasi / Tugagan / Aksiyada), rows with photo, name, price (tap = edit price sheet), promo tag, one-tap "Bor/Tugagan" switch; "Qoʻshish" opens **Add product** (`S.addProduct`: tabs "Katalogdan" (search catalog, set only the price, "Doʻkoningizda bor" for owned items) and "Oʻzim yarataman" (name, unit, category, price, optional photo)); empty state with `so-shelf.png`.
- **Aksiya qoʻshish** (`S.promo`): choose product, promo price (must be lower than the regular price), duration chips Bugun / 3 kun / 1 hafta / Sana tanlash (`promoEnd` in `mockShopApi.ts`), live preview "Mijozlar shunday koʻradi", "Aksiyani eʼlon qilish"; max 20 active; end promotion action. Published promos appear in the buyer app's Aksiyalar immediately (shared DB).
- **Sozlamalar** (`S.settings`): shop info (name, phone, photo), delivery (on/off, fee, minimum order, radius, delivery time text), hours (Dushanba–Shanba, optional different Yakshanba), "Taʼtil rejimi" (on/off; a date range is not required in the demo), Xodimlar ("Xodim taklif qilish" → invite sheet `S.invite` with role Sotuvchi/Kuryer, mocked 24 h single-use link, copy), Tarif card (`tariff*`), **Demo** group: "Yangi doʻkon roʻyxatdan oʻtkazish", "Baraka Market (demo) ga qaytish", "Demo: administrator sifatida tasdiqlash", "Xaridor ilovasiga qaytish" (new).
- **Registration (4 steps + pending)** (`S.reg`): (1) name, "Nima sotasiz?" chips (`cats`), phone; (2) location on the static map image `so-map.jpg` with a centred pin and address field, optional shop photo (image_picker, kept locally); (3) working hours with "Yakshanba boshqa vaqtda" switch; (4) delivery yes/no, fee, minimum order, radius slider 0.5–3 km. Submit → the shop becomes `pending`, hidden from buyers; "Arizangiz qabul qilindi" screen with `so-pending.png`, "Mahsulot qoʻshish". "Demo: administrator sifatida tasdiqlash" activates it and it appears in the buyer app.

---

## 10. Notifications, analytics, misc

- Analytics (`track()` in the web app) is optional: keep a local event log (`app_open, onboarding_step, shop_view, product_add_to_cart, checkout_start, order_placed, order_status_changed`) in memory only; do not send anything.
- Deep links, share, and the Telegram SDK are not implemented.
- The support link and Legal texts are placeholders (`legal.draft` line stays visible on the Legal pages).

---

## 11. Android specifics

- `applicationId`: `uz.yaqinda.demo`; app label **Yaqinda**; launcher icon: green (`#07AB59`) adaptive icon with a white "Y" (or the basket illustration) — generate with `flutter_launcher_icons`.
- `minSdk 24`, portrait only, edge-to-edge with transparent status bar (dark icons on light theme).
- Add the `tel` scheme to `<queries>` in `AndroidManifest.xml` (Android 11+ `url_launcher`). Location permissions only if `geolocator` is used; handle "denied" gracefully.
- Release build: keep R8/shrink on unless it breaks; report the APK size.
- Keep the release manifest free of `INTERNET`.

---

## 12. Tests (must exist and pass)

Port these from the web tests / logic (the original tests are in `buyer-app/src/**/*.test.ts`, the sources you have cover the logic):

- `format`: `12 000 soʻm`, `formatKm` (300 m / 1.2 km), `productTitle`, `discountPct`.
- `phone`: masks, operator codes, pasted `+998`/`998` prefixes, `toE164`, `displayPhone`.
- `time` (fixed UTC+5): weekday, `hhmm`, `promoTimeLeft`, `formatOrderTime` (Bugun/Kecha/dd.mm), around midnight.
- `geo`: Haversine reference values, `isInServiceArea`, `coordsForManualAddress` stability.
- `search`: normalisation (Cyrillic, "sutt", apostrophes), scoring, sort and out-of-stock ordering, 2-char minimum in the UI.
- `prng`: `mulberry32` sequence; seed determinism (same shops/prices/promos on every launch except promo end times).
- `mock_api`: open state, visibility/range, cart validation issues, checkout (idempotency, 5/hour, min order, delivery radius), order timeline (all statuses, reject shop, partial shop, expiry, cancel only `new`), repeat order.
- `mock_shop_api`: manual mode, accept → pack → dispatch → complete, reject reason reaches the buyer, availability → `confirm`, promo rules (20 max, price below regular), registration → pending → approve.
- Widget smoke tests: onboarding to Home, add to cart → checkout → order appears, bottom-nav badge.

---

## 13. Demo script (acceptance)

1. Fresh install → onboarding (phone, name, address in Chilonzor) → Home looks like `newhome.png` (banner carousel moves by itself).
2. Open **Baraka Market**, add Non + Sut to the cart (minimum 40 000 soʻm for delivery; try below it → the warning "Yetkazib berish uchun yana … soʻmlik mahsulot qoʻshing"), place the order → tracking shows Yangi → Qabul qilindi → Yigʻilmoqda → Yoʻlda → Yetkazildi over ~80 s (before shop mode has ever been opened).
3. Order from **Oila Doʻkoni** → after 10 s "Rad etildi · Sabab: Mahsulot tugagan".
4. Order 2+ items from **Meva Bogʻi** → "Baʼzi mahsulotlar tugagan" sheet with the new total; confirm.
5. Try **Qassob Karim** → "Yopiq", add buttons replaced by "Doʻkon yopiq".
6. Search "sut", "сут", "sutt" → same products; sort by "Eng arzon".
7. Profil → card "Doʻkoningiz bormi? Yaqindaga bepul qoʻshiling" (in the web app it opened the shop bot; here it opens **shop mode**) → **shop mode**: Panel shows waiting orders; accept one, run it to completion; reject another with a reason; mark one product "Tugagan"; add a promotion "Non" → back to the buyer mode: the promo shows in Aksiyalar and the stock change blocks ordering.
8. Buyer places a new order to Baraka Market → in shop mode it appears as new; accept → buyer's tracking shows "Qabul qilindi".
9. Register a new shop in shop mode → "Arizangiz qabul qilindi" → "Demo: administrator sifatida tasdiqlash" → the shop shows in the buyer's Doʻkonlar.
10. Profil → "Hisobni oʻchirish" → back to onboarding with a clean database. Dark theme also works everywhere.

---

## 14. Suggested work order

1. Create the Flutter project, add packages, fonts, assets; theme (light/dark), Riverpod/go_router skeleton, shell with the bottom nav.
2. `core/` (format, time, geo, phone, search, prng) **with tests**.
3. `data/` (models, seed, mock DB + mock API + shop API) **with tests**.
4. Buyer features in this order: onboarding → Home → shop page + product sheet → cart/checkout → orders + tracking → search/promotions/category → profile/address.
5. Shop mode.
6. Polish (states, skeletons, dark theme, haptics), README/DECISIONS, launcher icon.
7. `flutter analyze`, `flutter test`, `flutter build apk --release`; run the demo script on an emulator/device if possible; save screenshots.

Commit after each step if the folder is a git repository. Do not stop to ask questions: make a reasonable decision, log it in `DECISIONS.md`, continue.

---

## 15. Known limitations (say so in your final report)

- Demo data only: no real backend, no accounts, no push/bot notifications, no online payment, single language.
- Product/shop images are placeholders cropped from design references; the map is a static picture; the phone number is not verified.
- Calls open the phone dialer (`tel:`); nothing is sent anywhere.
- Real-device behaviour (geolocation, dialer, back gesture) can only be confirmed on a device; state clearly what was and was not verified.
