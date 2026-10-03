import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/widgets/uc_list_tile.dart';
import 'package:uczciwa_cena/models/item.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return UCListTile(
      title: item.name,
      onTap: () => context.push(AppRoutes.item, extra: item),
    );
  }
}
