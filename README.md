# Yaqinda — demo APK

An offline Android demo of the **Yaqinda** Telegram mini app, written in Flutter.
One APK contains both modes:

* **Yaqinda** — the buyer app: neighbourhood shops in Chilonzor, a cart, checkout
  and live order tracking.
* **Yaqinda Doʻkon** — the shop-owner app: orders, stock, prices, promotions,
  settings and registration.

Both modes talk to the same local mock server, so at a demo you can place an
order as a buyer and accept it as the shop on the same phone. There is no
backend, no Telegram and no network: the release APK does not even declare the
`INTERNET` permission.

---

## Build

Requirements: Flutter **3.22 or newer** (3.27+ recommended) with the Android
toolchain — `flutter doctor` should be clean — and JDK 17.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The deliverable is `build/app/outputs/flutter-apk/app-release.apk`. Install it
with `flutter install` or `adb install -r build/app/outputs/flutter-apk/app-release.apk`.

Per-ABI builds (smaller, three files instead of one):

```bash
flutter build apk --release --split-per-abi
```

Release builds are signed with the debug key — fine for a demo, not for a store
listing. R8 and resource shrinking are off (see DECISIONS.md).

### If Gradle complains

`android/` ships hand-written Gradle files (AGP 8.7.3, Kotlin 2.1.0, Gradle
8.12). If your Flutter version wants something else, regenerate just the build
scripts from your own SDK — everything of ours (manifests, `MainActivity.kt`,
icons, styles) is kept:

```powershell
powershell -ExecutionPolicy Bypass -File tool\setup_android.ps1   # Windows
```

```bash
bash tool/setup_android.sh                                        # macOS / Linux
```

### Building on GitHub instead

`.github/workflows/build-apk.yml` builds the APK in the cloud, so no local
Flutter SDK is needed. Push the project to a GitHub repository and the workflow
runs by itself; you can also start it by hand from the **Actions** tab
("APK" → "Run workflow").

It runs `flutter analyze`, `flutter test`, builds the universal and the
per-ABI APKs, checks that the release APK declares no `INTERNET` permission,
and attaches the files to the run as the **yaqinda-apk** artifact (download it
from the run page). If the checked-in Gradle files do not match the SDK on the
runner, the workflow regenerates them with `tool/setup_android.sh` and retries.

Pushing a tag also publishes a GitHub Release with the APK attached:

```bash
git tag v1.0 && git push origin v1.0
```

Note: `reference/` holds the original mini app's TypeScript sources and design
screenshots. Keep the repository **private**, or add `reference/` to
`.gitignore` before pushing it somewhere public.

### Launcher icon

The green adaptive icon with the white "Y" is checked in. To regenerate it
(Node 18+, no image library needed):

```bash
node tool/make_icons.mjs .
```

---

## What is where

```
lib/
  main.dart                 app entry, portrait lock, edge-to-edge
  app/        router.dart, theme.dart, shell_buyer.dart, shell_shop.dart
  core/       format, time, geo, phone, search, ids, strings_buyer, strings_shop
  data/       models, seed, prng, mock_db, mock_api, mock_shop_api
  state/      app_state.dart (profile, addresses, cart, searches), providers.dart
  features/   onboarding, home, shops, category, search, promotions, cart,
              orders, profile, sheets, widgets
  shop_mode/  panel, orders, products, add_product, promo, settings, register
assets/img/   product, shop and illustration artwork
test/         core, prng, mock_api, mock_shop_api, state and widget tests
```

`core/` and `data/` contain no Flutter imports, so all the business rules are
unit-testable. The UI reads state through Riverpod and navigates with go_router.

Packages: `flutter_riverpod`, `go_router`, `shared_preferences`, `url_launcher`.
Nothing else.

---

## Demo script

1. **Fresh install** → onboarding: phone (`+998`, operator code checked), name,
   address in Chilonzor → Home.
2. Open **Baraka Market**, add Non and Sut, place the order. Below 40 000 soʻm
   the warning "Yetkazib berish uchun yana … soʻmlik mahsulot qoʻshing" blocks
   the button. Tracking then runs Yangi → Qabul qilindi → Yigʻilmoqda → Yoʻlda →
   Yetkazildi in about 80 seconds.
3. Order from **Oila Doʻkoni** → after 10 seconds "Rad etildi · Sabab: Mahsulot
   tugagan".
4. Order two or more items from **Meva Bogʻi** → the "Baʼzi mahsulotlar tugagan"
   card with the new total and a five-minute countdown; confirm or cancel.
5. **Qassob Karim** is switched off: "Yopiq", and the add buttons read
   "Doʻkon yopiq".
6. Search `sut`, `сут`, `sutt` → the same products; sort by "Eng arzon".
7. **Profil → "Doʻkoningiz bormi?"** opens shop mode. The panel shows waiting
   orders; accept one and run it to completion, reject another with a reason,
   mark a product "Tugagan", add a promotion for Non. Back in buyer mode the
   promotion is in Aksiyalar and the sold-out product can no longer be ordered.
8. Place a new order to Baraka Market as the buyer → it appears as new in shop
   mode; accept it → the buyer's tracking shows "Qabul qilindi".
9. Shop mode → Sozlamalar → "Yangi doʻkon roʻyxatdan oʻtkazish" → four steps →
   "Arizangiz qabul qilindi" → "Demo: administrator sifatida tasdiqlash" → the
   shop shows up in the buyer's Doʻkonlar.
10. Profil → "Hisobni oʻchirish" → back to onboarding with a clean database.
    Dark mode works everywhere (it follows the system setting).

**Order timing.** Before shop mode has ever been opened, orders play the
automatic 80-second timeline. The first time shop mode opens, the mock server
switches Baraka Market to manual: its orders then wait for the shop's actions.
The other shops keep the automatic timeline.

---

## Resetting the demo data

* In the app: **Profil → Hisobni oʻchirish**. It wipes the profile, the
  addresses, the cart and the mock database, and returns to onboarding.
* From the outside: `adb shell pm clear uz.yaqinda.demo`.

---

## Known limitations

* Demo data only: no backend, no accounts, no bot or push notifications, no
  online payment, one language (Uzbek, Latin).
* The phone number is never verified, so Profil always shows "Tasdiqlanmagan" —
  Telegram's `requestContact()` has no Android equivalent here.
* "Joylashuvimni aniqlash" is **simulated**: the demo asks for no location
  permission and drops the pin in the service area. Type the street by hand for
  a different address.
* The shop photo in registration is picked from the bundled storefront
  pictures; there is no camera or gallery access.
* The registration map is the static picture `so-map.jpg`, not a real map.
* Product and shop images are placeholders taken from the design references.
* "Doʻkonga qoʻngʻiroq" opens the Android dialer (`tel:`); nothing is sent
  anywhere.
* Status changes appear as in-app toasts and through polling every 15 seconds
  (and on resume). There are no system notifications.
* The admin panel is out of scope; "Demo: administrator sifatida tasdiqlash"
  stands in for it.

## Verification status

The project was written without a Flutter SDK on the authoring machine, so
`flutter analyze`, `flutter test` and `flutter build apk` have **not** been run
here, and no screenshots of the running app exist (`docs/screens/` is empty).
The logic ports were checked against the original TypeScript by computing
reference values with Node (`mulberry32`, Haversine, the Tashkent clock and the
address hash) and asserting them in `test/`. Run the three commands above on a
machine with Flutter to confirm, and if the analyzer reports formatting-level
lints, `dart fix --apply` clears them.

See `DECISIONS.md` for every place where this build deviates from the brief.
