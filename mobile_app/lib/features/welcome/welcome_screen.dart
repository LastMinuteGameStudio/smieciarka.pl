import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_secondary_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_title.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const UCTitle(title: 'UczciwaCena'),
            const SizedBox(height: 32),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'To twoje miejsce na danie przedmiotom drugiego życia.\n\nBo ',
                  ),
                  TextSpan(
                    text: 'za darmo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ', to uczciwa cena.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                color: ColorPalette.descColor,
              ),
            ),
            const SizedBox(height: 48),
            Column(
              spacing: 24,
              children: [
                UCButton(
                  label: 'ZALOGUJ SIĘ',
                  onPressed: () => context.push(AppRoutes.login),
                ),
                UCSecondaryButton(
                  label: 'POMIŃ LOGOWANIE',
                  onPressed: () => context.push(AppRoutes.items),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
