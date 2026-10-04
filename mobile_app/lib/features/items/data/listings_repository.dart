import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/models/item.dart';

class ListingsRepository {
  ListingsRepository({required this.dio});

  static const _radiusM = 10000;

  final Dio dio;

  /// Semantic search around [at]. An empty [query] lists the nearest listings.
  /// [mine] limits results to the signed-in user's listings (needs a session).
  Future<List<Item>> search(
    String query,
    LatLng at, {
    bool mine = false,
  }) async {
    final text = query.trim();
    final location = {
      'lat': at.latitude,
      'lng': at.longitude,
      'radius': _radiusM,
      if (mine) 'mine': true,
    };

    final response = text.isEmpty
        ? await dio.get<List<dynamic>>(
            '/listings/nearby',
            queryParameters: location,
          )
        : await dio.get<List<dynamic>>(
            '/listings/search',
            queryParameters: {...location, 'q': text},
          );

    return (response.data ?? const [])
        .map((json) => _toItem(json as Map<String, dynamic>))
        .toList();
  }

  static Item _toItem(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      phoneNumber: json['author_phone'] as String?,
      pickupLocation:
          (json['address'] as String?) ?? (json['location_label'] as String?),
      imageUrls: [
        for (final image in (json['images'] as List<dynamic>? ?? const []))
          (image as Map<String, dynamic>)['url'] as String,
      ],
    );
  }
}
