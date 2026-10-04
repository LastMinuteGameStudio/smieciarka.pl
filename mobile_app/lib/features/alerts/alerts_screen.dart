import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/search_add_bar.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/alerts/widgets/alert_tile.dart';
import 'package:uczciwa_cena/models/alert.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  // TODO: replace with alerts from the backend.
  static const _alerts = [Alert(id: '1'), Alert(id: '2'), Alert(id: '3')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UCPageHeader(title: 'Alerty'),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: _alerts.length,
                    itemBuilder: (_, index) => AlertTile(alert: _alerts[index]),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                  ),
                ),
                const SizedBox(height: 24),
                SearchAddBar(
                  hintText: 'Szukaj alertów',
                  onAddPressed: () => context.push(AppRoutes.newAlert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
