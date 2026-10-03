import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/models/search_area.dart';

void main() {
  const center = LatLng(52.2297, 21.0122);
  const area = SearchArea(center: center, radiusKm: 5);

  group('SearchArea.contains', () {
    test('accepts points inside the radius', () {
      // About 3 km north of the centre.
      expect(area.contains(const LatLng(52.2567, 21.0122)), isTrue);
    });

    test('rejects points outside the radius', () {
      // About 22 km north of the centre.
      expect(area.contains(const LatLng(52.4267, 21.0122)), isFalse);
    });

    test('accepts the centre itself', () {
      expect(area.contains(center), isTrue);
    });
  });
}
