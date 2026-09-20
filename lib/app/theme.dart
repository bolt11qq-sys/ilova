/// The design system: a soft mint page, white rounded cards with gentle
/// shadows, one brand green and a coral accent for discounts.
///
/// The palette lives in [YTokens]; read it in a widget with `yt(context)`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `#12a05a` → a [Color]. Accepts `#rgb`, `#rrggbb` and `#aarrggbb`.
Color hexColor(String hex, {Color fallback = const Color(0xFF0E7A4A)}) {
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

@immutable
class YTokens {
  const YTokens({
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.hint,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.accentInk,
    required this.mint,
    required this.peach,
    required this.coral,
    required this.badge,
    required this.danger,
    required this.warn,
    required this.border,
    required this.photoBg,
    required this.gradientTop,
    required this.gradientBottom,
    required this.shadow,
    required this.isDark,
  });

  final Color bg;
  final Color surface;

  /// Grouped background behind cards and list rows.
  final Color card;
  final Color text;
  final Color hint;

  /// Brand green.
  final Color accent;
  final Color accentText;
  final Color accentSoft;

  /// Green text on [accentSoft].
  final Color accentInk;
  final Color mint;
  final Color peach;

  /// Promotion price.
  final Color coral;

  /// `−N%` tags and unread dots.
  final Color badge;
  final Color danger;
  final Color warn;
  final Color border;
  final Color photoBg;
  final Color gradientTop;
  final Color gradientBottom;
  final List<BoxShadow> shadow;
  final bool isDark;

  static const YTokens light = YTokens(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFF1F4F3),
    text: Color(0xFF0E1442),
    hint: Color(0xFF6D7192),
    accent: Color(0xFF07AB59),
    accentText: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE4F9EE),
    accentInk: Color(0xFF0B8A48),
    mint: Color(0xFFD8F9E8),
    peach: Color(0xFFFEEFEB),
    coral: Color(0xFFEE4327),
    badge: Color(0xFFFF5B3A),
    danger: Color(0xFFE5484D),
    warn: Color(0xFFC2751A),
    border: Color(0x140E1442),
    photoBg: Color(0xFFF0EFEF),
    gradientTop: Color(0xFFDAF7E9),
    gradientBottom: Color(0xFFF6FCF9),
    shadow: [
      BoxShadow(
        color: Color(0x0D143C32),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x12143C32),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    isDark: false,
  );

  static const YTokens dark = YTokens(
    bg: Color(0xFF151E28),
    surface: Color(0xFF1D2834),
    card: Color(0xFF26333F),
    text: Color(0xFFF2F5F8),
    hint: Color(0xFF9AA8B8),
    accent: Color(0xFF2FC172),
    accentText: Color(0xFF08170F),
    accentSoft: Color(0xFF1B3A2B),
    accentInk: Color(0xFF5FDC98),
    mint: Color(0xFF1F4636),
    peach: Color(0xFF3A2A27),
    coral: Color(0xFFFF7A5F),
    badge: Color(0xFFFF6A4A),
    danger: Color(0xFFF06B6F),
    warn: Color(0xFFF0B34A),
    border: Color(0x17FFFFFF),
    photoBg: Color(0xFF2A3744),
    gradientTop: Color(0xFF163229),
    gradientBottom: Color(0xFF0F1720),
    shadow: [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    isDark: true,
  );
}

/// The palette of the current theme.
YTokens yt(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? YTokens.dark : YTokens.light;

/// The three Home banners, in the order they appear.
enum BannerKind { promo, fresh, fast }

class BannerPalette {
  const BannerPalette(this.gradient, this.tag, this.ink);
  final List<Color> gradient;

  /// Colour of the small tag and of the call-to-action button.
  final Color tag;

  /// Colour of the headline text on the banner.
  final Color ink;

  static const Map<BannerKind, BannerPalette> all = {
    BannerKind.promo: BannerPalette(
      [Color(0xFFFD9779), Color(0xFFFEC49C), Color(0xFFFEC9A0)],
      Color(0xFFE0454F),
      Color(0xFF5A1F13),
    ),
    BannerKind.fresh: BannerPalette(
      [Color(0xFFFFB27B), Color(0xFFFFD8A6), Color(0xFFFFE7C4)],
      Color(0xFFDD6F2A),
      Color(0xFF4A2A12),
    ),
    BannerKind.fast: BannerPalette(
      [Color(0xFFB7ECD0), Color(0xFFD9F7E6), Color(0xFFEAFBF2)],
      Color(0xFF0AA457),
      Color(0xFF0E1442),
    ),
  };
}

/// Radii used across the app.
class YRadius {
  static const double card = 18;
  static const double bigCard = 22;
  static const double banner = 22;
  static const double button = 14;
  static const double smallButton = 12;
  static const double sheet = 24;
  static const double mini = 12;
  static const double pill = 999;
}

const double screenPadding = 16;

/// Bundled Figtree is optional (see DECISIONS.md); when it is missing Flutter
/// falls back to the platform font, which renders `ʻ` and `ʼ` correctly.
const String? appFontFamily = null;

ThemeData buildTheme(Brightness brightness) {
  final t = brightness == Brightness.dark ? YTokens.dark : YTokens.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: appFontFamily,
  );

  TextStyle style(double size, FontWeight weight,
          {Color? color, double? spacing, double? height}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? t.text,
        letterSpacing: spacing,
        height: height,
      );

  return base.copyWith(
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: t.accent,
      brightness: brightness,
    ).copyWith(
      primary: t.accent,
      onPrimary: t.accentText,
      secondary: t.accentInk,
      onSecondary: t.accentText,
      error: t.danger,
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.text,
      outline: t.hint,
    ),
    textTheme: base.textTheme.copyWith(
      displaySmall: style(22, FontWeight.w800, spacing: -0.4),
      headlineMedium: style(21, FontWeight.w800, spacing: -0.4, height: 1.15),
      headlineSmall: style(18, FontWeight.w800, spacing: -0.2),
      titleLarge: style(17, FontWeight.w800),
      titleMedium: style(16, FontWeight.w700),
      titleSmall: style(15, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400, height: 1.35),
      bodyMedium: style(15, FontWeight.w400, height: 1.35),
      bodySmall: style(13, FontWeight.w400, color: t.hint, height: 1.3),
      labelLarge: style(15.5, FontWeight.w600),
      labelMedium: style(13, FontWeight.w600),
      labelSmall: style(11, FontWeight.w600, color: t.hint),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: t.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: style(18, FontWeight.w800, spacing: -0.2),
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
    splashFactory: InkRipple.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surface,
      hintStyle: style(15, FontWeight.w400, color: t.hint),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(YRadius.button),
        borderSide: BorderSide(color: t.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(YRadius.button),
        borderSide: BorderSide(color: t.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(YRadius.button),
        borderSide: BorderSide(color: t.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(YRadius.button),
        borderSide: BorderSide(color: t.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(YRadius.button),
        borderSide: BorderSide(color: t.danger, width: 1.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YRadius.sheet),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: t.border,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.isDark ? t.card : const Color(0xFF17233A),
      contentTextStyle: style(14.5, FontWeight.w600, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YRadius.button),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? t.accent
            : (t.isDark ? const Color(0xFF3A4653) : const Color(0xFFDDE3E1)),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
