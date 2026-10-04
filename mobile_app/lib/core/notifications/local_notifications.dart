import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows notifications on this device. Nothing leaves the phone: the backend
/// is polled elsewhere and this only displays what was found.
class LocalNotifications {
  static const _channelId = 'matches';
  static const _channelName = 'Nowe dopasowania';

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Sets the plugin up and asks for permission (Android 13+ requires it).
  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
