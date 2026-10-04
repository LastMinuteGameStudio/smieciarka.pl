import 'package:flutter/material.dart';
import 'package:uczciwa_cena/app/app_router.dart';
import 'package:uczciwa_cena/app/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UczciwaCena',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
