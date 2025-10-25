import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService instance = ThemeService._init();
  static const String _themeKey = 'theme_mode';
  
  ThemeService._init();

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.dark.index;
      themeNotifier.value = ThemeMode.values[themeIndex];
    } catch (e) {
      print('Theme service error: $e');
      // If there's an error, just use dark mode as default
      themeNotifier.value = ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      themeNotifier.value = themeMode;
    } catch (e) {
      print('Theme save error: $e');
      // If there's an error saving, just update the notifier
      themeNotifier.value = themeMode;
    }
  }

  void toggleTheme() {
    final newTheme = themeNotifier.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    setTheme(newTheme);
  }
}
