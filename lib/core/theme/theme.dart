import 'package:flutter/material.dart';

// Light Theme Colors
const Color lightPrimary = Color(0xFF7BAE7F);
const Color lightSecondary = Color(0xFFF4E3B2);
const Color lightBackground = Color(0xFFFAF7F0);
const Color lightText = Color(0xFF2E2E2E);
const Color lightSurface = Color(0xFFFFFFFF);

// Dark Theme Colors
const Color darkPrimary = Color(0xFF5B8761);
const Color darkSecondary = Color(0xFFBFAF8B);
const Color darkBackground = Color(0xFF1D1E20);
const Color darkText = Color(0xFFEDEDED);
const Color darkSurface = Color(0xFF2A2A2A);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  primaryColor: lightPrimary,
  scaffoldBackgroundColor: lightBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: lightBackground,
    foregroundColor: lightText,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: lightText.withOpacity(0.6)),
    labelStyle: const TextStyle(color: lightText),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: lightPrimary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontFamily: 'Inter', color: lightText),
    headlineSmall: TextStyle(fontFamily: 'Lora', color: lightText),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  primaryColor: darkPrimary,
  scaffoldBackgroundColor: darkBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: darkBackground,
    foregroundColor: darkText,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: darkText.withOpacity(0.6)),
    labelStyle: const TextStyle(color: darkText),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: darkSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontFamily: 'Manrope', color: darkText),
    headlineSmall: TextStyle(fontFamily: 'Merriweather', color: darkText),
  ),
);
