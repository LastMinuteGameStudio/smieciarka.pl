import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button_shadow.dart';

/// Square icon button for adding something, with the shared button shadow.
class UCAddButton extends StatelessWidget {
  const UCAddButton({super.key, required this.onPressed});

  static const _size = 56.0;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return UCButtonShadow(
      child: SizedBox.square(
        dimension: _size,
        child: ElevatedButton(
          onPressed: onPressed,
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
    );
  }
}
