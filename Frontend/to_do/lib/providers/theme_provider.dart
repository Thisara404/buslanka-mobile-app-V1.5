import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    loadThemePreference();
  }

  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('selectedTheme') ?? 'System Default';
      final darkMode = prefs.getBool('darkModeEnabled') ?? false;

      _isDarkMode = darkMode;

      switch (theme) {
        case 'Light':
          _themeMode = ThemeMode.light;
          break;
        case 'Dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }

      notifyListeners();
    } catch (e) {
      // Default to system theme if there's any error
      _themeMode = ThemeMode.system;
      print('Error loading theme preference: $e');
    }
  }

  Future<void> setThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();

    switch (theme) {
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    await prefs.setString('selectedTheme', theme);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = isDark;

    // If setting dark mode manually, also update the theme mode
    if (isDark) {
      _themeMode = ThemeMode.dark;
      await prefs.setString('selectedTheme', 'Dark');
    } else {
      _themeMode = ThemeMode.light;
      await prefs.setString('selectedTheme', 'Light');
    }

    await prefs.setBool('darkModeEnabled', isDark);
    notifyListeners();
  }
}
