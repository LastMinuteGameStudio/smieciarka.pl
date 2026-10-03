import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_secondary_button.dart';
import 'package:uczciwa_cena/models/item.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ogłoszenia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UCButton(
              label: 'Dodaj ogłoszenie',
              onPressed: () => context.push(AppRoutes.newItem),
            ),
            const SizedBox(height: 16),
            UCSecondaryButton(
              label: 'Otwórz przykładowe ogłoszenie',
              onPressed: () => context.push(
                AppRoutes.item,
                extra: const Item(id: 'example'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
