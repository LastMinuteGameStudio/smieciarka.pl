import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uczciwa_cena/app/app.dart';
import 'package:uczciwa_cena/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  setupDependencies();
  runApp(const App());
}
