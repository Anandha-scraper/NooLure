import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _restore();
  }

  static const _modeKey = 'noolure_theme_mode';
  static const _accentKey = 'noolure_accent_sage';
  static const _colorsKey = 'noolure_custom_colors';

  ThemeMode mode = ThemeMode.light;
  Color accentSeed = AppColors.accent;
  final Map<String, Color> customColors = {};

  Color colorFor(String role, Color fallback, Brightness brightness) =>
      customColors['${brightness.name}_$role'] ?? fallback;

  static double _luminance(Color color) => color.computeLuminance();

  bool setColor(String role, Color color, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final bg = role == 'background'
        ? color
        : colorFor(
            'background',
            dark ? AppColors.darkBg : AppColors.bg,
            brightness,
          );
    final surface = role == 'surface'
        ? color
        : colorFor(
            'surface',
            dark ? AppColors.darkSurface : AppColors.surface,
            brightness,
          );
    final ink = role == 'text'
        ? color
        : colorFor(
            'text',
            dark ? AppColors.darkText : AppColors.text,
            brightness,
          );
    final accent = role == 'accent'
        ? color
        : colorFor('accent', accentSeed, brightness);
    double contrast(Color a, Color b) {
      final aL = _luminance(a) + 0.05;
      final bL = _luminance(b) + 0.05;
      return aL > bL ? aL / bL : bL / aL;
    }

    if (contrast(bg, ink) < 4.5 ||
        contrast(surface, ink) < 4.5 ||
        contrast(bg, accent) < 3 ||
        contrast(surface, accent) < 3)
      return false;
    customColors['${brightness.name}_$role'] = color;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setStringList(
        _colorsKey,
        customColors.entries
            .map((e) => '${e.key}:${e.value.toARGB32()}')
            .toList(),
      ),
    );
    return true;
  }

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
    for (final entry in prefs.getStringList(_colorsKey) ?? const <String>[]) {
      final parts = entry.split(':');
      if (parts.length == 2 && int.tryParse(parts[1]) != null) {
        customColors[parts[0]] = Color(int.parse(parts[1]));
      }
    }
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
