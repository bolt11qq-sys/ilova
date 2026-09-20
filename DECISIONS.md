# Decisions

Every place where this build departs from `APKReadme.md`, and why.

## Packages

| Brief | Built | Why |
| --- | --- | --- |
| `uuid` | not used | `core/ids.dart` generates RFC-4122 v4 ids with `Random.secure()` in twelve lines. One dependency fewer for a demo that never sends an id anywhere. |
| `geolocator` (optional) | not used | `geolocator_android` pulls in Play Services location, whose manifest merges in `INTERNET`. The brief requires the release manifest to stay free of it, so "Joylashuvimni aniqlash" is simulated instead: a short delay, then the pin lands on the service-area centre and the toast `address.detected` appears. Every other part of the address flow is real. |
| `image_picker` (optional) | not used | Same reasoning plus a permission prompt in the middle of a demo. In shop registration, "Rasm qoʻshish" opens a sheet with the five bundled storefront pictures (`seed.dart: pickablePhotos`). The chosen picture is stored with the shop and shown on the panel. |
| `flutter_launcher_icons` (dev) | not used | It needs to be run, and its output is what ships anyway. `tool/make_icons.mjs` renders the same green-and-white "Y" icon from scratch with Node — no image library, no extra dev dependency — and the PNGs plus the adaptive-icon XML are checked in. |

Kept, as the brief lists them: `flutter_riverpod`, `go_router`,
`shared_preferences`, `url_launcher`.

## Fonts

Figtree is **not bundled**: downloading it needs network access, which the
authoring machine did not have. The app therefore uses the platform font
(Roboto), which renders `ʻ` (U+02BB) and `ʼ` (U+02BC) correctly. The weights and
sizes from the design system are applied as specified.

To switch Figtree on: drop the five `.ttf` files into `assets/fonts/`, uncomment
the `fonts:` block in `pubspec.yaml` and set `appFontFamily = 'Figtree'` in
`lib/app/theme.dart`.

## Strings

`uz_latn.ts` and `strings.ts` are copied verbatim, including the special
apostrophes and the non-breaking spaces in prices. Four strings were **added**
for things the mini app did not have, all marked in the source:

* `support.title`, `support.text`, `support.handle`, `support.copy`,
  `support.copied` — the "Yordam" sheet that replaces the Telegram support chat.
* `S.settings.backToBuyer` / `backToBuyerSub` — "Xaridor ilovasiga qaytish",
  which the brief asks for in the Demo group of Sozlamalar.
* `S.invite.copy` — the invite sheet needs a label on its copy button.

`ShopSettings` was renamed to `ShopSettingsData` in Dart, because `ShopSettings`
is also the name of the strings class for that screen.

## Routing

The shop-mode pages that are pushed on top of the shell live at top-level paths
(`/shop-promo`, `/shop-add-product`, `/shop-register`, `/shop-pending`) rather
than under `/shop-mode/…`. The four shop tabs occupy `/shop-mode/panel`,
`/shop-mode/orders`, `/shop-mode/products` and `/shop-mode/settings`, and
nesting pushed routes under a sibling branch path makes go_router's matching
ambiguous. `/shop-mode` redirects to `/shop-mode/panel`.

## Time and money

Tashkent is a fixed UTC+5 offset, exactly as in `time.ts`; no timezone package.
All prices are `int` soʻm — `double` is never used for money.

## Determinism

`mulberry32` is ported with explicit 32-bit masking (`data/prng.dart`). Dart's
64-bit multiplication wraps modulo 2^64, whose low 32 bits are still exact, so
`imul32` matches JavaScript's `Math.imul`. The expected sequences in
`test/prng_test.dart` were produced by running the original TypeScript under
Node, and the same was done for the Haversine distances, the Tashkent clock and
the FNV-1a address hash.

One thing is *not* deterministic across launches, and this matches the web app:
promotion end times are computed from the app's start time, so "Bugun 23:00
gacha" moves with the day.

## Sorting

`mock_api.dart` sorts with a `stableSorted` helper (a decorate-sort-undecorate
merge over the original indices). `List.sort` in Dart is not guaranteed stable,
while `Array.sort` in modern JavaScript is, and several orderings in the
original rely on that. `localeCompare` became a case-insensitive `compareTo`,
which orders the Uzbek product names the same way.

## Mock server shape

The web app runs the buyer and the shop app in two browser tabs sharing
`localStorage`, so its mock re-reads the database on every call. The APK runs
both modes in one process, so there is a single `MockServer` instance with one
in-memory `MockDb` mirrored to `shared_preferences` as one JSON blob. The
`syncOverlay()` replay on every call is kept, because the shop API still writes
its changes as overlays that the buyer side must pick up.

`MockServer` takes a `latency` flag; tests switch the simulated 100–600 ms
delays off. Test code also injects a `MemoryStore`, so no test touches a plugin.

## Android

* `applicationId` `uz.yaqinda.demo`, label **Yaqinda**, `minSdk 24`, portrait
  only, edge-to-edge with a transparent status bar.
* The release manifest declares **no permissions at all**. `INTERNET` is added
  only in the debug and profile manifests, which Flutter's tooling needs to talk
  to the device.
* `<queries>` declares the `tel` intent so `url_launcher` can reach the dialer
  on Android 11+.
* Release builds are signed with the debug key. R8 and resource shrinking are
  **off**: the brief says to keep them "unless it breaks", and the Play Core
  stubs that Flutter's embedding references are the usual reason a release
  build fails. A demo APK gains little from shrinking. `proguard-rules.pro`
  stays in the tree for whoever turns R8 back on.
* The Gradle files are hand-written for AGP 8.7.3 / Kotlin 2.1.0 / Gradle 8.12.
  `tool/setup_android.ps1` (and `.sh`) regenerates them from the user's own
  Flutter version if that combination does not fit.

## Analyzer configuration

`analysis_options.yaml` includes `package:flutter_lints` and switches off four
purely cosmetic rules: `prefer_const_constructors`,
`prefer_const_literals_to_create_immutables`, `prefer_const_declarations` and
`constant_identifier_names`. The first three are what `dart fix --apply` adds
mechanically; the last one would flag `S`, the shop strings table, whose name is
copied from the TypeScript. `use_build_context_synchronously` and `avoid_print`
are kept on and the code is written to satisfy them.

## Colour API

Colours are blended with `Color.withAlpha(int)` rather than `withOpacity` or
`withValues`. `withOpacity` is deprecated from Flutter 3.27 and `withValues`
does not exist before it; `withAlpha` works on every version and is not
deprecated, which keeps the project buildable across a wider range of SDKs.

## Analytics

The `track()` calls of the web app are not ported. The brief marks them
optional, and a local event log that nothing reads would be dead code.

## Not built

* The admin panel (explicitly out of scope). "Demo: administrator sifatida
  tasdiqlash" in Sozlamalar stands in for the one admin action the demo needs.
* Local notifications (`flutter_local_notifications`), listed as an optional
  stretch. Status changes surface as in-app toasts plus 15-second polling and a
  refresh on resume.
* Deep links, the share sheet and the Telegram SDK.
* Image upload, which the mock server refuses in the original too.
