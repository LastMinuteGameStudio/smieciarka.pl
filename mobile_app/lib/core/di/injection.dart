import 'package:get_it/get_it.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/auth/token_storage.dart';
import 'package:uczciwa_cena/core/network/api_client.dart';
import 'package:uczciwa_cena/core/notifications/local_notifications.dart';
import 'package:uczciwa_cena/features/alerts/data/alerts_repository.dart';
import 'package:uczciwa_cena/features/items/data/listings_repository.dart';
import 'package:uczciwa_cena/features/notifications/data/notifications_repository.dart';
import 'package:uczciwa_cena/features/notifications/notification_poller.dart';

void setupDependencies() {
  final tokens = TokenStorage();
  final dio = createApiClient(tokens);

  final auth = AuthRepository(dio: dio, tokens: tokens);
  final listings = ListingsRepository(dio: dio);
  final notifications = NotificationsRepository(dio: dio);
  final local = LocalNotifications();

  GetIt.instance.registerSingleton<AuthRepository>(auth);
  GetIt.instance.registerSingleton<ListingsRepository>(listings);
  GetIt.instance.registerSingleton<AlertsRepository>(
    AlertsRepository(dio: dio),
  );
  GetIt.instance.registerSingleton<LocalNotifications>(local);
  GetIt.instance.registerSingleton<NotificationPoller>(
    NotificationPoller(
      auth: auth,
      notifications: notifications,
      listings: listings,
      local: local,
    ),
  );
}
