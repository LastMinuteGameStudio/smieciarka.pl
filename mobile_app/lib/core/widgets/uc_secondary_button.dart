import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button_shadow.dart';

class UCSecondaryButton extends StatelessWidget {
  const UCSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return UCButtonShadow(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: ColorPalette.yelowishWhite,
          foregroundColor: ColorPalette.mainColor,
          side: BorderSide.none,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
