import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode themeMode = ThemeMode.light;

  bool get isDark => themeMode == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> changeTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();

    themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    await prefs.setString(
      _themeKey,
      isDarkMode ? 'dark' : 'light',
    );

    notifyListeners();
  }
}