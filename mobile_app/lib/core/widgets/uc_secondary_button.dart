import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.primary,
        side: const BorderSide(color: ColorPalette.primary),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}
