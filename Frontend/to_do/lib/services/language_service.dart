import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
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

  // Get current language locale from preferences
  static Future<Locale> getCurrentLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_prefsKey);

      if (savedLanguage != null &&
          supportedLocales
              .any((locale) => locale.languageCode == savedLanguage)) {
        return Locale(savedLanguage);
      }

      // Default to English if not set or invalid
      return const Locale('en');
    } catch (e) {
      print('Error getting current locale: $e');
      return const Locale('en'); // Default to English on error
    }
  }

  // Save language preference
  static Future<bool> saveLanguagePreference(Locale locale) async {
    try {
      if (!supportedLocales.contains(locale)) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
      return true;
    } catch (e) {
      print('Error saving language preference: $e');
      return false;
    }
  }

  // Check if a language is supported
  static bool isSupported(Locale locale) {
    return supportedLocales.contains(locale);
  }

  // Get locale from language code
  static Locale? getLocaleFromCode(String languageCode) {
    for (var locale in supportedLocales) {
      if (locale.languageCode == languageCode) {
        return locale;
      }
    }
    return null; // Not found
  }

  // Get all language names
  static List<Map<String, String>> getAllLanguages() {
    return supportedLocales.map((locale) {
      return {
        'code': locale.languageCode,
        'name': getLanguageName(locale),
      };
    }).toList();
  }
}
