import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _restore();
  }

  static const _modeKey = 'noolure_theme_mode';
  static const _accentKey = 'noolure_accent_sage';

  ThemeMode mode = ThemeMode.light;
  Color accentSeed = AppColors.accent;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_modeKey);
    mode = switch (storedMode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    final useSage = prefs.getBool(_accentKey) ?? false;
    accentSeed = useSage ? AppColors.accent2 : AppColors.accent;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, switch (newMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    });
  }

  Future<void> setAccent(Color color) async {
    accentSeed = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accentKey, color == AppColors.accent2);
  }
}
