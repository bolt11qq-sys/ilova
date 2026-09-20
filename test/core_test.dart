/// Pure-logic tests for `core/`: formatting, phone numbers, Tashkent time,
/// distances and search. The expected values come from the TypeScript sources
/// (checked with `node -e` against the originals).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yaqinda/core/format.dart';
import 'package:yaqinda/core/geo.dart';
import 'package:yaqinda/core/phone.dart';
import 'package:yaqinda/core/search.dart';
import 'package:yaqinda/core/time.dart';

void main() {
  group('format', () {
    test('prices use non-breaking spaces', () {
      expect(formatNumber(12000), '12${nbsp}000');
      expect(formatNumber(1240000), '1${nbsp}240${nbsp}000');
      expect(formatNumber(999), '999');
      expect(formatPrice(12000), '12${nbsp}000${nbsp}soʻm');
    });

    test('formatKm switches to metres below 1 km', () {
      expect(formatKm(0.3), '300${nbsp}m');
      expect(formatKm(0.045), '45${nbsp}m');
      expect(formatKm(1.24), '1.2${nbsp}km');
      expect(formatKm(12), '12.0${nbsp}km');
    });

    test('productTitle only annotates weight and volume goods', () {
      expect(productTitle('Pomidor', 'kg'), 'Pomidor, 1${nbsp}kg');
      expect(productTitle('Kungaboqar yogʻi', 'l'), 'Kungaboqar yogʻi, 1${nbsp}l');
      expect(productTitle('Non', 'dona'), 'Non');
      expect(productTitle('Tuxum (10 ta)', 'quti'), 'Tuxum (10 ta)');
    });

    test('discountPct rounds', () {
      expect(discountPct(12000, 10000), 17);
      expect(discountPct(10000, 7500), 25);
      expect(discountPct(0, 0), 0);
    });
  });

  group('phone', () {
    test('keeps nine national digits, tolerating prefixes', () {
      expect(nationalDigits('901234567'), '901234567');
      expect(nationalDigits('+998 90 123 45 67'), '901234567');
      expect(nationalDigits('998901234567'), '901234567');
      expect(nationalDigits('90 123 45 67 89'), '901234567');
    });

    test('masks progressively', () {
      expect(maskNational('9'), '9');
      expect(maskNational('901'), '90 1');
      expect(maskNational('901234567'), '90 123 45 67');
    });

    test('validates the operator code', () {
      expect(isValidPhone('901234567'), isTrue);
      expect(isValidPhone('931234567'), isTrue);
      expect(isValidPhone('101234567'), isFalse); // 10 is not an operator
      expect(isValidPhone('90123456'), isFalse); // too short
    });

    test('E.164 and display forms', () {
      expect(toE164('901234567'), '+998901234567');
      expect(displayPhone('+998901234567'), '+998 90 123 45 67');
      expect(displayPhone('12345'), '12345');
    });
  });

  group('time (fixed UTC+5)', () {
    test('epoch is a Thursday at 05:00 local', () {
      final t = tashkent(0);
      expect(t.weekday, 3);
      expect(t.minutes, 300);
      expect(t.dayIndex, 0);
    });

    test('weekday and minutes of a known instant', () {
      final ts = DateTime.utc(2026, 9, 19, 6, 5).millisecondsSinceEpoch;
      final t = tashkent(ts);
      expect(t.weekday, 5); // Saturday
      expect(t.minutes, 665); // 11:05
      expect(hhmm(ts), '11:05');
    });

    test('crossing local midnight moves to the next day', () {
      final ts = DateTime.utc(2026, 9, 19, 19, 30).millisecondsSinceEpoch;
      final t = tashkent(ts);
      expect(t.weekday, 6); // Sunday
      expect(t.minutes, 30);
      expect(hhmm(ts), '00:30');
    });

    test('parseHHMM and tashkentDayAt', () {
      expect(parseHHMM('08:30'), 510);
      expect(parseHHMM('00:00'), 0);
      final ts = DateTime.utc(2026, 9, 19, 6, 5).millisecondsSinceEpoch;
      expect(hhmm(tashkentDayAt(ts, 23)), '23:00');
      expect(tashkent(tashkentDayAt(ts, 23)).dayIndex, tashkent(ts).dayIndex);
    });

    test('promoTimeLeft', () {
      final now = DateTime.utc(2026, 9, 19, 6, 5).millisecondsSinceEpoch;
      expect(promoTimeLeft(tashkentDayAt(now, 23), now), 'Bugun 23:00 gacha');
      expect(promoTimeLeft(now + 3 * dayMs, now), '3 kun qoldi');
    });

    test('formatOrderTime', () {
      final now = DateTime.utc(2026, 9, 19, 6, 5).millisecondsSinceEpoch;
      expect(formatOrderTime(now, now), 'Bugun, 11:05');
      expect(formatOrderTime(now - dayMs, now), 'Kecha, 11:05');
      expect(formatOrderTime(now - 3 * dayMs, now), '16.09, 11:05');
    });

    test('short and long dates', () {
      final ts = DateTime.utc(2026, 9, 19, 6, 5).millisecondsSinceEpoch;
      expect(shortDate(ts), '19-sen');
      expect(longDate(ts), '19-sentabr');
      expect(shortDateTime(ts), '19-sen, 11:05');
    });

    test('countdown', () {
      expect(countdown(5 * 60000), '5:00');
      expect(countdown(65000), '1:05');
      expect(countdown(-1), '0:00');
    });
  });

  group('geo', () {
    test('haversine matches the reference implementation', () {
      expect(
        haversineKm(serviceCenter, const Coords(41.2765, 69.2055)),
        closeTo(0.141673, 0.0005),
      );
      expect(
        haversineKm(serviceCenter, const Coords(41.285, 69.222)),
        closeTo(1.811102, 0.0005),
      );
      expect(haversineKm(serviceCenter, serviceCenter), 0);
    });

    test('distanceKm rounds to 0.1', () {
      expect(distanceKm(serviceCenter, const Coords(41.2785, 69.2)), 0.5);
    });

    test('service area is a 5 km circle around Chilonzor', () {
      expect(isInServiceArea(serviceCenter), isTrue);
      expect(isInServiceArea(const Coords(41.2765, 69.2055)), isTrue);
      // Yunusobod is well outside.
      expect(isInServiceArea(const Coords(41.365, 69.287)), isFalse);
    });

    test('nearestDistrict', () {
      expect(nearestDistrict(const Coords(41.2756, 69.2043)).name, 'Chilonzor');
      expect(nearestDistrict(const Coords(41.366, 69.288)).name, 'Yunusobod');
    });

    test('coordsForManualAddress is stable and matches the TS hash', () {
      final a = coordsForManualAddress('Chilonzor', 'Bunyodkor koʻchasi, 12-uy');
      final b = coordsForManualAddress('Chilonzor', 'Bunyodkor koʻchasi, 12-uy');
      expect(a, b);
      expect(a.lat, closeTo(41.279079, 1e-6));
      expect(a.lng, closeTo(69.208188, 1e-6));
      // Different streets land on different points, but stay in the district.
      final c = coordsForManualAddress('Chilonzor', 'Qatortol 30');
      expect(c == a, isFalse);
      expect(haversineKm(a, c), lessThan(1.5));
    });

    test('an unknown district falls back to the first one', () {
      final a = coordsForManualAddress('Nowhere', 'x');
      expect(haversineKm(a, serviceCenter), lessThan(1.0));
    });
  });

  group('search', () {
    test('normalises Cyrillic, apostrophes and repeats', () {
      expect(normalize('Sut'), 'sut');
      expect(normalize('сут'), 'sut');
      expect(normalize('sutt'), 'sut');
      expect(normalize('Goʻsht'), 'gosht');
      expect(normalize('gʻalla'), 'gala');
      expect(normalize('  Coca-Cola  (1,5 l) '), 'coca cola 1 5 l');
    });

    test('scores prefix, contains and typos', () {
      expect(matchScore('sut', 'Sut 2,5% (1 l)'), 0);
      expect(matchScore('ola', 'Coca-Cola'), 1);
      expect(matchScore('pomidr', 'Pomidor'), 2);
      expect(matchScore('banan', 'Pomidor'), isNull);
    });

    test('every query token must match', () {
      expect(matchScore('sut kefir', 'Sut 2,5%'), isNull);
      expect(matchScore('yangi non', 'Yangi Non Nonvoyxona'), 0);
    });

    test('empty input never matches', () {
      expect(matchScore('', 'Sut'), isNull);
      expect(matchScore('sut', ''), isNull);
    });

    test('levenshtein', () {
      expect(levenshtein('sut', 'sut'), 0);
      expect(levenshtein('sut', 'set'), 1);
      expect(levenshtein('sut', 'nok'), 3);
    });
  });
}
