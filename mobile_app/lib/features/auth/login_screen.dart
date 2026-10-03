import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_secondary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logowanie')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO: replace with the real Facebook login flow.
            UCButton(
              label: 'Zaloguj przez Facebooka',
              onPressed: () => context.go(AppRoutes.items),
            ),
            const SizedBox(height: 16),
            UCSecondaryButton(
              label: 'Wróć',
              onPressed: () => context.go(AppRoutes.welcome),
            ),
          ],
        ),
      ),
    );
  }
}
