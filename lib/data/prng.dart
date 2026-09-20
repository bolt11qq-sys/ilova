/// The deterministic generator that builds the per-shop assortment.
///
/// It reproduces the web app's `mulberry32` bit for bit so a shop sells the
/// same goods at the same prices in both apps. Dart ints are 64-bit; every step
/// is masked back to 32 bits, which is exactly what JavaScript's `|0` and
/// `Math.imul` do.
library;

/// `Math.imul(a, b)` — the low 32 bits of the product.
int imul32(int a, int b) =>
    ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF;

/// Returns a function producing doubles in `[0, 1)`.
double Function() mulberry32(int seed) {
  var a = seed & 0xFFFFFFFF;
  return () {
    a = (a + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = imul32(a ^ (a >>> 15), 1 | a);
    t = ((t + imul32(t ^ (t >>> 7), 61 | t)) & 0xFFFFFFFF) ^ t;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296;
  };
}

/// `roundTo(12345, 500)` → 12500; never returns less than one [step].
int roundTo(num n, int step) {
  final r = (n / step).round() * step;
  return r < step ? step : r;
}
