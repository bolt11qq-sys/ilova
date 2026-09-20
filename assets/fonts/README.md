# Figtree (optional)

The design uses **Figtree** at weights 400, 500, 600, 700 and 800. It is not
bundled here, because the machine that generated this project had no network
access. Without it the app falls back to the platform font, which renders the
Uzbek apostrophes `ʻ` (U+02BB) and `ʼ` (U+02BC) correctly.

To bundle it:

1. Download Figtree from Google Fonts and put these files in this folder:

   ```
   Figtree-Regular.ttf     (400)
   Figtree-Medium.ttf      (500)
   Figtree-SemiBold.ttf    (600)
   Figtree-Bold.ttf        (700)
   Figtree-ExtraBold.ttf   (800)
   ```

2. Uncomment the `fonts:` block at the bottom of `pubspec.yaml`.
3. Set `appFontFamily = 'Figtree'` in `lib/app/theme.dart`.
4. `flutter pub get` and rebuild.
