/// Distance and service-area maths — a port of `lib/geo.ts`.
library;

import 'dart:math' as math;

class Coords {
  const Coords(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is Coords && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'Coords($lat, $lng)';

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  static Coords fromJson(Map<String, dynamic> j) =>
      Coords((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());
}

const double _rKm = 6371;

double _rad(double d) => d * math.pi / 180;

/// Straight-line distance in km (Haversine).
double haversineKm(Coords a, Coords b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _rKm * math.asin(math.sqrt(h));
}

/// Distance shown to 0.1 km.
double distanceKm(Coords a, Coords b) =>
    (haversineKm(a, b) * 10).round() / 10;

class District {
  const District(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;

  Coords get coords => Coords(lat, lng);
}

/// Rough centroids; manual addresses get these coordinates plus a small
/// deterministic offset.
const List<District> districts = [
  District('Chilonzor', 41.2756, 69.2043),
  District('Yakkasaroy', 41.29, 69.26),
  District('Uchtepa', 41.29, 69.165),
  District('Shayxontohur', 41.32, 69.23),
  District('Olmazor', 41.345, 69.22),
  District('Mirobod', 41.298, 69.275),
  District('Yunusobod', 41.365, 69.287),
  District('Mirzo Ulugʻbek', 41.339, 69.335),
  District('Sergeli', 41.225, 69.22),
];

/// MVP service area: a circle around Chilonzor.
const Coords serviceCenter = Coords(41.2756, 69.2043);
const double serviceRadiusKm = 5;

bool isInServiceArea(Coords c) =>
    haversineKm(serviceCenter, c) <= serviceRadiusKm;

District nearestDistrict(Coords c) {
  var best = districts.first;
  for (final d in districts) {
    if (haversineKm(c, d.coords) < haversineKm(c, best.coords)) best = d;
  }
  return best;
}

int _imul32(int a, int b) =>
    ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) & 0xFFFFFFFF;

/// Stable pseudo-random offset (~±400 m) so different manual addresses in one
/// district do not land on the same point.
Coords coordsForManualAddress(String district, String street) {
  final d = districts.firstWhere(
    (x) => x.name == district,
    orElse: () => districts.first,
  );
  var h = 2166136261;
  for (final ch in '$district|${street.trim().toLowerCase()}'.runes) {
    h = (h ^ ch) & 0xFFFFFFFF;
    h = _imul32(h, 16777619);
  }
  final u = (h % 1000) / 1000 - 0.5;
  final v = ((h >>> 10) % 1000) / 1000 - 0.5;
  return Coords(d.lat + u * 0.007, d.lng + v * 0.009);
}
