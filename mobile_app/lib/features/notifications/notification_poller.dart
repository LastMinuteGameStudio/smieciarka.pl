import 'dart:async';

import 'package:dio/dio.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/notifications/local_notifications.dart';
import 'package:uczciwa_cena/features/items/data/listings_repository.dart';
import 'package:uczciwa_cena/features/notifications/data/notifications_repository.dart';
import 'package:uczciwa_cena/models/app_notification.dart';

/// Checks for new matches every [interval] while the app is running and shows
/// each new one as a device notification.
///
/// The first check after a login only records what already exists, so old
/// matches don't pop up on every launch. Without a session nothing is checked.
class NotificationPoller {
  NotificationPoller({
    required this.auth,
    required this.notifications,
    required this.listings,
    required this.local,
  });

  static const interval = Duration(seconds: 30);

  final AuthRepository auth;
  final NotificationsRepository notifications;
  final ListingsRepository listings;
  final LocalNotifications local;

  Timer? _timer;
  bool _checking = false;

  /// Ids already seen. `null` until the first check after a login.
  Set<String>? _seen;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _seen = null;
  }

  Future<void> _check() async {
    // A slow request must not overlap with the next tick.
    if (_checking) {
      return;
    }
    _checking = true;
    try {
      if (!await auth.hasStoredSession()) {
        _seen = null;
        return;
      }

      final current = await notifications.list();
      final ids = {for (final n in current) n.id};
      final baseline = _seen;
      _seen = {...?baseline, ...ids};
      if (baseline == null) {
        return;
      }

      for (final notification in current) {
        if (!baseline.contains(notification.id)) {
          await _show(notification);
        }
      }
    } on DioException {
      // Offline or server down: try again on the next tick.
    } finally {
      _checking = false;
    }
  }

  Future<void> _show(AppNotification notification) async {
    var body = 'Pojawiło się ogłoszenie pasujące do Twojego alertu.';
    try {
      final listing = await listings.get(notification.listingId);
      body = listing.name;
    } on DioException {
      // The listing couldn't be loaded; the generic text still tells the user.
    }
    await local.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: 'Nowe dopasowanie',
      body: body,
    );
  }
}
