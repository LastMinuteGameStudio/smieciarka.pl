import 'package:dio/dio.dart';
import 'package:uczciwa_cena/models/app_notification.dart';

/// Matches found for the signed-in user's alerts. Requires a session.
class NotificationsRepository {
  NotificationsRepository({required this.dio});

  final Dio dio;

  Future<List<AppNotification>> list() async {
    final response = await dio.get<List<dynamic>>('/notifications');
    return (response.data ?? const [])
        .map((json) => _toNotification(json as Map<String, dynamic>))
        .toList();
  }

  static AppNotification _toNotification(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
    );
  }
}
