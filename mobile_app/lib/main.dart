import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uczciwa_cena/app/app.dart';
import 'package:get_it/get_it.dart';
import 'package:uczciwa_cena/core/di/injection.dart';
import 'package:uczciwa_cena/core/notifications/local_notifications.dart';
import 'package:uczciwa_cena/features/notifications/notification_poller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  setupDependencies();
  await GetIt.instance<LocalNotifications>().init();
  GetIt.instance<NotificationPoller>().start();
  runApp(const App());
}
