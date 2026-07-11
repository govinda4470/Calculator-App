import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF121212);
  static const panel = Color(0xFF1E1E1E);
  static const key = Color(0xFF2D2D2D);
  static const function = Color(0xFF424242);
  static const orange = Color(0xFFFF9800);
  static const warm = Color(0xFFFFC081);
  static const blue = Color(0xFF2196F3);
  static const text = Color(0xFFE5E2E1);
  static const muted = Color(0xFFA38D7A);
  static const stroke = Color(0xFF353534);
  static const ink = Color(0xFF241400);
  static const green = Color(0xFF0ECB81);
}

final ThemeData precisionTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.orange,
    secondary: AppColors.blue,
    surface: AppColors.panel,
    onSurface: AppColors.text,
    outline: AppColors.stroke,
  ),
  fontFamily: 'Roboto',
  splashColor: Colors.white10,
  highlightColor: Colors.white10,
  dividerColor: AppColors.stroke,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.warm,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    ),
  ),
);
