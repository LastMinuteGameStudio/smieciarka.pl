import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/models/alert.dart';
import 'package:uczciwa_cena/models/search_area.dart';

/// Alerts are saved listening filters on the backend. Requires a session.
class AlertsRepository {
  AlertsRepository({required this.dio});

  final Dio dio;

  /// The signed-in user's alerts.
  Future<List<Alert>> list() async {
    final response = await dio.get<List<dynamic>>('/filters');
    return (response.data ?? const [])
        .map((json) => _toAlert(json as Map<String, dynamic>))
        .toList();
  }

  /// Creates a radius alert. [description] is the search text.
  Future<Alert> create({
    required String name,
    required String description,
    required SearchArea area,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/filters',
      data: {
        'name': name,
        'query': description,
        'area': {
          'type': 'radius',
          'center': {'lat': area.center.latitude, 'lng': area.center.longitude},
          'radius_m': (area.radiusKm * 1000).round(),
        },
      },
    );
    return _toAlert(response.data!);
  }

  static Alert _toAlert(Map<String, dynamic> json) {
    final lat = json['center_lat'] as num?;
    final lng = json['center_lng'] as num?;
    final radiusM = json['radius_m'] as int?;
    final query = json['query'] as String;

    return Alert(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? query,
      description: query,
      area: lat == null || lng == null || radiusM == null
          ? null
          : SearchArea(
              center: LatLng(lat.toDouble(), lng.toDouble()),
              radiusKm: radiusM / 1000,
            ),
    );
  }
}
