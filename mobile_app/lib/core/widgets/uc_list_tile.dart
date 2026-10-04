import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

class UCListTile extends StatelessWidget {
  const UCListTile({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      tileColor: ColorPalette.yelowishWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColorPalette.titleColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: ColorPalette.mainColor,
      ),
      onTap: onTap,
    );
  }
}
