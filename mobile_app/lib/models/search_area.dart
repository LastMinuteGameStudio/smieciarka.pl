import 'package:latlong2/latlong.dart';

/// A circular area on the map that an alert is interested in.
class SearchArea {
  const SearchArea({required this.center, required this.radiusKm});

  final LatLng center;
  final double radiusKm;

  /// Whether [point] lies inside the search radius.
  bool contains(LatLng point) {
    final distanceMeters = const Distance().as(LengthUnit.Meter, center, point);
    return distanceMeters <= radiusKm * 1000;
  }
}
