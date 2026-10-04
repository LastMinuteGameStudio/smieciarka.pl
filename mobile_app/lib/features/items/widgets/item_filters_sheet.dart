import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';

/// Bottom sheet with the listing filters. Returns the new "own listings only"
/// value when applied, or `null` when dismissed.
Future<bool?> showItemFiltersSheet(
  BuildContext context, {
  required bool mineOnly,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: ColorPalette.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ItemFiltersSheet(mineOnly: mineOnly),
  );
}

class ItemFiltersSheet extends StatefulWidget {
  const ItemFiltersSheet({super.key, required this.mineOnly});

  final bool mineOnly;

  @override
  State<ItemFiltersSheet> createState() => _ItemFiltersSheetState();
}

class _ItemFiltersSheetState extends State<ItemFiltersSheet> {
  late bool _mineOnly = widget.mineOnly;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtry',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: ColorPalette.titleColor,
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _mineOnly,
              onChanged: (value) => setState(() => _mineOnly = value ?? false),
              title: const Text(
                'Wyłącznie własne ogłoszenia',
                style: TextStyle(fontSize: 18, color: ColorPalette.titleColor),
              ),
              activeColor: ColorPalette.mainColor,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            UCButton(
              label: 'Zatwierdź',
              onPressed: () => Navigator.of(context).pop(_mineOnly),
            ),
          ],
        ),
      ),
    );
  }
}
