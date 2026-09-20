/// Search that tolerates Latin/Cyrillic mixes and small typos
/// ("sut", "сут", "sutt") — a port of `lib/search.ts`.
library;

const Map<String, String> _cyr = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
  'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
  'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
  'ф': 'f', 'х': 'x', 'ц': 's', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ъ': '',
  'ы': 'i', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya', 'ў': 'o', 'қ': 'q',
  'ғ': 'g', 'ҳ': 'h',
};

final RegExp _cyrRe = RegExp('[а-яёўқғҳ]');
final RegExp _apostrophes = RegExp('[\u02BB\u02BC\'\u2019\u0060\u2018]');
final RegExp _nonAlnum = RegExp('[^a-z0-9]+');
final RegExp _repeats = RegExp(r'(.)\1+');

String normalize(String input) {
  var s = input.toLowerCase();
  s = s.replaceAllMapped(_cyrRe, (m) => _cyr[m[0]] ?? m[0]!);
  s = s.replaceAll(_apostrophes, ''); // oʻ → o, gʻ → g
  s = s.replaceAll(_nonAlnum, ' ');
  s = s.replaceAllMapped(_repeats, (m) => m[1]!); // sutt → sut
  return s.trim();
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  final prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    var last = prev[0];
    prev[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final tmp = prev[j];
      final sub = last + (a[i - 1] == b[j - 1] ? 0 : 1);
      var best = prev[j] + 1;
      if (prev[j - 1] + 1 < best) best = prev[j - 1] + 1;
      if (sub < best) best = sub;
      prev[j] = best;
      last = tmp;
    }
  }
  return prev[b.length];
}

/// Lower is better; `null` = no match.
int? _tokenScore(String q, String t) {
  if (t.startsWith(q)) return 0;
  if (t.contains(q)) return 1;
  final head = t.length < q.length ? t : t.substring(0, q.length);
  if (q.length >= 3 && levenshtein(q, head) <= 1) return 2;
  if (q.length >= 4 && levenshtein(q, t) <= 1) return 2;
  return null;
}

/// Score of a whole query against a text; every query token must match some
/// text token. `null` = no match, otherwise lower is more relevant.
int? matchScore(String query, String text) {
  final qTokens = normalize(query).split(' ').where((s) => s.isNotEmpty);
  final tTokens = normalize(text).split(' ').where((s) => s.isNotEmpty).toList();
  if (qTokens.isEmpty || tTokens.isEmpty) return null;
  var total = 0;
  for (final q in qTokens) {
    int? best;
    for (final t in tTokens) {
      final s = _tokenScore(q, t);
      if (s != null && (best == null || s < best)) best = s;
    }
    if (best == null) return null;
    total += best;
  }
  return total;
}
