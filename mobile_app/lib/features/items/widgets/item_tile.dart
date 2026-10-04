import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_list_tile.dart';
import 'package:uczciwa_cena/models/item.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, this.onDeleted});

  final Item item;

  /// Called after the listing was deleted on its detail screen.
  final Future<void> Function()? onDeleted;

  Future<void> _open(BuildContext context) async {
    final deleted = await context.push<bool>(AppRoutes.item, extra: item);
    if (deleted == true) {
      await onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return UCListTile(title: item.name, onTap: () => _open(context));
  }
}
