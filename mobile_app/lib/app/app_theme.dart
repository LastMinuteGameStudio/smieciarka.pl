import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.light(
      primary: ColorPalette.primary,
      onPrimary: ColorPalette.onPrimary,
      secondary: ColorPalette.secondary,
      onSecondary: ColorPalette.onSecondary,
      surface: ColorPalette.surface,
      onSurface: ColorPalette.onSurface,
      error: ColorPalette.error,
    ),
    scaffoldBackgroundColor: ColorPalette.background,
  );
}
