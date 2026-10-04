import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/models/item.dart';

class ListingsRepository {
  ListingsRepository({required this.dio});

  final Dio dio;

  /// Semantic search, or the newest listings when [query] is empty.
  ///
  /// With [at] and [radiusM] results are limited to that distance; without
  /// them the whole country is searched. [mine] limits results to the
  /// signed-in user's listings (needs a session).
  Future<List<Item>> search(
    String query, {
    LatLng? at,
    int? radiusM,
    bool mine = false,
  }) async {
    final text = query.trim();
    final params = <String, dynamic>{
      if (at != null) 'lat': at.latitude,
      if (at != null) 'lng': at.longitude,
      if (at != null && radiusM != null) 'radius': radiusM,
      if (mine) 'mine': true,
    };

    final response = text.isEmpty
        ? await dio.get<List<dynamic>>(
            '/listings/nearby',
            queryParameters: params,
          )
        : await dio.get<List<dynamic>>(
            '/listings/search',
            queryParameters: {...params, 'q': text},
          );

    return (response.data ?? const [])
        .map((json) => _toItem(json as Map<String, dynamic>))
        .toList();
  }

  /// One listing by id, e.g. to show its title in a notification.
  Future<Item> get(String id) async {
    final response = await dio.get<Map<String, dynamic>>('/listings/$id');
    return _toItem(response.data!);
  }

  /// Soft-deletes one of the signed-in user's listings.
  Future<void> delete(String id) => dio.delete<void>('/listings/$id');

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
      isMine: json['is_mine'] as bool? ?? false,
    );
  }
}
