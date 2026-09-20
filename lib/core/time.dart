/// Tashkent wall-clock helpers — a port of `lib/time.ts`.
///
/// Tashkent is UTC+5 all year (no DST), so a fixed offset is exact and no
/// timezone database is needed.
library;

const int tzOffsetMs = 5 * 3600000;
const int dayMs = 24 * 3600000;

class TashkentTime {
  const TashkentTime(this.weekday, this.minutes, this.dayIndex);

  /// 0 = Monday … 6 = Sunday (same numbering as the shops' opening hours).
  final int weekday;

  /// Minutes since local midnight.
  final int minutes;

  /// Days since the Unix epoch in local time.
  final int dayIndex;
}

TashkentTime tashkent(int ts) {
  final local = ts + tzOffsetMs;
  final dayIndex = (local / dayMs).floor();
  final minutes = ((local - dayIndex * dayMs) / 60000).floor();
  // 1970-01-01 was a Thursday (weekday 3 with Monday = 0).
  final weekday = ((dayIndex + 3) % 7 + 7) % 7;
  return TashkentTime(weekday, minutes, dayIndex);
}

String pad2(int n) => n.toString().padLeft(2, '0');

String hhmm(int ts) {
  final m = tashkent(ts).minutes;
  return '${pad2(m ~/ 60)}:${pad2(m % 60)}';
}

/// `"08:30"` → 510.
int parseHHMM(String s) {
  final parts = s.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return h * 60 + m;
}

/// Timestamp (UTC ms) of a given Tashkent wall-clock time on the day of [ts].
int tashkentDayAt(int ts, int hour, [int minute = 0]) {
  final dayIndex = tashkent(ts).dayIndex;
  return dayIndex * dayMs - tzOffsetMs + (hour * 60 + minute) * 60000;
}

DateTime _local(int ts) =>
    DateTime.fromMillisecondsSinceEpoch(ts + tzOffsetMs, isUtc: true);

/// `Bugun 23:00 gacha` / `3 kun qoldi`.
String promoTimeLeft(int endsAt, int now) {
  final days = tashkent(endsAt).dayIndex - tashkent(now).dayIndex;
  if (days <= 0) return 'Bugun ${hhmm(endsAt)} gacha';
  return '$days kun qoldi';
}

/// `Bugun, 14:05` / `Kecha, 14:05` / `19.09, 14:05`.
String formatOrderTime(int ts, int now) {
  final days = tashkent(now).dayIndex - tashkent(ts).dayIndex;
  if (days == 0) return 'Bugun, ${hhmm(ts)}';
  if (days == 1) return 'Kecha, ${hhmm(ts)}';
  final d = _local(ts);
  return '${pad2(d.day)}.${pad2(d.month)}, ${hhmm(ts)}';
}

const List<String> monthsShort = [
  'yan', 'fev', 'mar', 'apr', 'may', 'iyn',
  'iyl', 'avg', 'sen', 'okt', 'noy', 'dek',
];

const List<String> monthsLong = [
  'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
  'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
];

/// `19-sen`.
String shortDate(int ts) {
  final d = _local(ts);
  return '${d.day}-${monthsShort[d.month - 1]}';
}

/// `19-sen, 11:59`.
String shortDateTime(int ts) => '${shortDate(ts)}, ${hhmm(ts)}';

/// `19-sentabr`.
String longDate(int ts) {
  final d = _local(ts);
  return '${d.day}-${monthsLong[d.month - 1]}';
}

/// `4:12` — a countdown used by the partial-fulfilment sheet.
String countdown(int msLeft) {
  final total = msLeft < 0 ? 0 : msLeft ~/ 1000;
  return '${total ~/ 60}:${pad2(total % 60)}';
}
