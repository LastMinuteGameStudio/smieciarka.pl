import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_secondary_button.dart';
import 'package:uczciwa_cena/models/alert.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerty')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UCButton(
              label: 'Nowy alert',
              onPressed: () => context.push(AppRoutes.newAlert),
            ),
            const SizedBox(height: 16),
            UCSecondaryButton(
              label: 'Otwórz przykładowy alert',
              onPressed: () => context.push(
                AppRoutes.alert,
                extra: const Alert(id: 'example'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
