import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      if (themeString == 'light') {
        emit(ThemeMode.light);
      } else if (themeString == 'dark') {
        emit(ThemeMode.dark);
      }
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    emit(newMode);
    await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }
}
