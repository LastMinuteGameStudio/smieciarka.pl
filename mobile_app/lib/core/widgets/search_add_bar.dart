import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button_shadow.dart';

class SearchAddBar extends StatelessWidget {
  const SearchAddBar({
    super.key,
    required this.hintText,
    required this.onAddPressed,
  });

  static const _height = 64.0;

  final String hintText;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _height,
            child: TextField(
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 18,
                  color: ColorPalette.mainColor,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        UCButtonShadow(
          child: SizedBox.square(
            dimension: _height,
            child: ElevatedButton(
              onPressed: onAddPressed,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                elevation: 0,
                backgroundColor: ColorPalette.mainColor,
                foregroundColor: ColorPalette.yelowishWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
