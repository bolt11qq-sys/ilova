/// Number, price and distance formatting — a port of `lib/format.ts`.
///
/// Prices are integer soʻm. The thousands separator and the gap before the unit
/// are a non-breaking space (U+00A0) so a price never wraps mid-way.
library;

/// Non-breaking space (U+00A0).
const String nbsp = '\u00A0';

/// `12000` → `12 000` (non-breaking spaces).
String formatNumber(num n) {
  final digits = n.round().abs().toString();
  final sign = n.round() < 0 ? '-' : '';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(nbsp);
    buf.write(digits[i]);
  }
  return '$sign$buf';
}

/// `12000` → `12 000 soʻm`.
String formatPrice(num n) => '${formatNumber(n)}${nbsp}soʻm';

/// Under 1 km people think in metres: `300 m`; above that `1.2 km`.
String formatKm(double km) {
  if (km < 1) return '${(km * 1000).round()}${nbsp}m';
  return '${km.toStringAsFixed(1)}${nbsp}km';
}

/// `Pomidor, 1 kg` for weight/volume goods; countable goods keep their plain name.
String productTitle(String name, String unit) =>
    unit == 'kg' || unit == 'l' ? '$name, 1$nbsp$unit' : name;

/// Discount in whole percent, rounded.
int discountPct(int regular, int promo) {
  if (regular <= 0) return 0;
  return ((regular - promo) / regular * 100).round();
}
