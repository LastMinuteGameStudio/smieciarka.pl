import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_list_tile.dart';
import 'package:uczciwa_cena/models/alert.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, required this.onChanged});

  final Alert alert;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return UCListTile(
      title: alert.name,
      onTap: () async {
        await context.push(AppRoutes.alert, extra: alert);
        onChanged();
      },
    );
  }
}
