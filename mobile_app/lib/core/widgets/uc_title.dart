import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

class UCTitle extends StatelessWidget {
  final String title;
  final double fontSize;

  const UCTitle({super.key, required this.title, this.fontSize = 36});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.start,
      style: TextStyle(
        color: ColorPalette.titleColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
