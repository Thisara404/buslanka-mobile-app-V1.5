import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _prefsKey = 'selected_language';

  // Available languages in the app
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('si'), // Sinhala
    Locale('ta'), // Tamil
  ];

  // Get readable language name from locale
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'si':
        return 'සිංහල (Sinhala)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      default:
        return 'English';
    }
  }

  // Current locale
  Locale get currentLocale => _currentLocale;

  // Constructor - load saved language
  LanguageProvider() {
    loadSavedLanguage();
  }

  // Load saved language preference
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_prefsKey);

    if (savedLanguage != null &&
        supportedLocales
            .any((locale) => locale.languageCode == savedLanguage)) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    }
  }

  // Change language and save preference
  Future<void> changeLanguage(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) return;

    _currentLocale = newLocale;
    notifyListeners();

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }
}
