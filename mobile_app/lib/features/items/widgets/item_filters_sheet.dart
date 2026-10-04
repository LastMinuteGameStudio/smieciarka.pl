import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';

/// Filters applied to the listings board.
class ItemFilters {
  const ItemFilters({required this.mineOnly, this.maxDistanceKm});

  /// Only the signed-in user's own listings.
  final bool mineOnly;

  /// Maximum distance from the user in km. `null` means the whole country.
  final int? maxDistanceKm;
}

const _distanceOptionsKm = [1, 5, 10, 25, 50, 100];

/// Bottom sheet with the listing filters. Returns the new filters when applied,
/// or `null` when dismissed.
Future<ItemFilters?> showItemFiltersSheet(
  BuildContext context, {
  required ItemFilters current,
}) {
  return showModalBottomSheet<ItemFilters>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: ColorPalette.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ItemFiltersSheet(current: current),
  );
}

class ItemFiltersSheet extends StatefulWidget {
  const ItemFiltersSheet({super.key, required this.current});

  final ItemFilters current;

  @override
  State<ItemFiltersSheet> createState() => _ItemFiltersSheetState();
}

class _ItemFiltersSheetState extends State<ItemFiltersSheet> {
  late bool _mineOnly = widget.current.mineOnly;
  late int? _distanceKm = widget.current.maxDistanceKm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
            const Text(
              'Maksymalna odległość od Ciebie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorPalette.titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final km in _distanceOptionsKm)
                  ChoiceChip(
                    label: Text('$km km'),
                    selected: _distanceKm == km,
                    selectedColor: ColorPalette.mainColor,
                    labelStyle: TextStyle(
                      color: _distanceKm == km
                          ? ColorPalette.yelowishWhite
                          : ColorPalette.titleColor,
                    ),
                    onSelected: (_) => setState(() => _distanceKm = km),
                  ),
                ChoiceChip(
                  label: const Text('Cała Polska'),
                  selected: _distanceKm == null,
                  selectedColor: ColorPalette.mainColor,
                  labelStyle: TextStyle(
                    color: _distanceKm == null
                        ? ColorPalette.yelowishWhite
                        : ColorPalette.titleColor,
                  ),
                  onSelected: (_) => setState(() => _distanceKm = null),
                ),
              ],
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
              onPressed: () => Navigator.of(context).pop(
                ItemFilters(mineOnly: _mineOnly, maxDistanceKm: _distanceKm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
