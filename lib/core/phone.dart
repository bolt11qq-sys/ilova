/// +998 phone handling — a port of `lib/phone.ts`.
library;

/// Uzbek mobile operator codes (after +998).
const List<String> operatorCodes = [
  '20', '33', '50', '55', '77', '88', '90', '91', '93', '94', '95', '97', '98', '99',
];

/// Keeps only the 9 national digits, tolerating a pasted `+998` / `998` prefix.
String nationalDigits(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('998')) d = d.substring(3);
  return d.length > 9 ? d.substring(0, 9) : d;
}

/// Mask: `90 123 45 67`.
String maskNational(String d) {
  String cut(int a, int b) =>
      d.length <= a ? '' : d.substring(a, d.length < b ? d.length : b);
  final parts = [cut(0, 2), cut(2, 5), cut(5, 7), cut(7, 9)]
      .where((p) => p.isNotEmpty)
      .toList();
  return parts.join(' ');
}

bool isValidPhone(String national) =>
    national.length == 9 && operatorCodes.contains(national.substring(0, 2));

String toE164(String national) => '+998$national';

/// `+998901234567` → `+998 90 123 45 67`.
String displayPhone(String e164) {
  final d = nationalDigits(e164);
  return d.length == 9 ? '+998 ${maskNational(d)}' : e164;
}
