import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_list_tile.dart';
import 'package:uczciwa_cena/models/alert.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    return UCListTile(
      title: 'Alert ${alert.id}',
      onTap: () => context.push(AppRoutes.alert, extra: alert),
    );
  }
}
