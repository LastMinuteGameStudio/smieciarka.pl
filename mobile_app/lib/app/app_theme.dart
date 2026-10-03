import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

abstract final class AppTheme {
  static final ColorScheme _colorScheme = ColorScheme.light(
    primary: ColorPalette.mainColor,
    onPrimary: ColorPalette.titleColor,
    secondary: ColorPalette.darkBlue,
    onSecondary: ColorPalette.yelowishWhite,
    surface: ColorPalette.yelowishWhite,
    onSurface: ColorPalette.titleColor,
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.yelowishWhite.withValues(alpha: 0.75),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ColorPalette.mainColor,
        ),
        hintStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: ColorPalette.mainColor.withAlpha(180),
        ),
        prefixIconColor: ColorPalette.mainColor,
        suffixIconColor: ColorPalette.mainColor,
        border: _inputBorder(ColorPalette.mainColor),
        enabledBorder: _inputBorder(ColorPalette.mainColor),
        focusedBorder: _inputBorder(ColorPalette.mainColor, width: 2),
        errorBorder: _inputBorder(_colorScheme.error, width: 2),
        focusedErrorBorder: _inputBorder(_colorScheme.error, width: 2),
      );

  static final TextTheme _rubikTypography = Typography.material2021().black
      .apply(fontFamily: GoogleFonts.rubik().fontFamily);

  // Text typed into a TextFormField uses `bodyLarge` in Material 3.
  static final TextTheme _textTheme = _rubikTypography.copyWith(
    bodyLarge: _rubikTypography.bodyLarge?.copyWith(
      color: ColorPalette.mainColor,
    ),
  );

  static final NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: ColorPalette.mainColor),
        ),
        labelTextStyle: WidgetStateProperty.all(
          _rubikTypography.labelMedium?.copyWith(
            color: ColorPalette.mainColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static final ThemeData light = ThemeData(
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: ColorPalette.backgroundColor,
    textTheme: _textTheme,
    inputDecorationTheme: _inputDecorationTheme,
    navigationBarTheme: _navigationBarTheme,
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
