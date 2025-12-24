import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Mode Colors
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        background: lightBackground,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        secondary: primaryBlue,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightBackground,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextSecondary,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        background: darkBackground,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        secondary: primaryBlue,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
      ),
       bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: primaryBlue,
        unselectedItemColor: darkTextSecondary,
        showSelectedLabels: false,
        showUnselectedLabels: false,
         type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
    );
  }
}
