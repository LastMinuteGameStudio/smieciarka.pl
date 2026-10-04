import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

/// Decides where to start: straight into the app when a session is still
/// valid, otherwise to the welcome screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final hasSession = await GetIt.instance<AuthRepository>().restoreSession();
    if (!mounted) {
      return;
    }
    context.go(hasSession ? AppRoutes.items : AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: ColorPalette.mainColor),
      ),
    );
  }
}
