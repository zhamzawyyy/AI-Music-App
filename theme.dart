import 'package:flutter/material.dart';

/// Central place for design tokens so the look stays consistent and easy
/// to re-theme -- mirrors the "flexible accent color" idea from the desktop
/// exam app, adapted to Material 3.
class AppTheme {
  static const accent = Color(0xFF2F7BFF);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: accent,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: accent,
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}
