import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_add_button.dart';

/// Search field with an optional add button on its right.
class SearchAddBar extends StatelessWidget {
  const SearchAddBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onAddPressed,
  });

  static const _height = 64.0;

  final String hintText;
  final ValueChanged<String>? onChanged;

  /// When null, the add button is not shown.
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final onAdd = onAddPressed;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _height,
            child: TextField(
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.center,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: ColorPalette.mainColor,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                prefixIcon: Icon(Icons.search_rounded),
              ).copyWith(hintText: hintText),
            ),
          ),
        ),
        if (onAdd != null) ...[
          const SizedBox(width: 12),
          UCAddButton(onPressed: onAdd),
        ],
      ],
    );
  }
}
