import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button_shadow.dart';

class UCButton extends StatelessWidget {
  const UCButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return UCButtonShadow(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? ColorPalette.mainColor,
          foregroundColor: ColorPalette.yelowishWhite,
          elevation: 0,
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
