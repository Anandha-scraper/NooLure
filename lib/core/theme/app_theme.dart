import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({Color accentSeed = AppColors.accent}) =>
      _build(brightness: Brightness.light, accentSeed: accentSeed);

  static ThemeData dark({Color accentSeed = AppColors.accent}) =>
      _build(brightness: Brightness.dark, accentSeed: accentSeed);

  static ThemeData _build({
    required Brightness brightness,
    required Color accentSeed,
  }) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.bg;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final onSurface = isDark ? AppColors.darkText : AppColors.text;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accentSeed,
      onPrimary: bg,
      secondary: AppColors.accent2,
      onSecondary: bg,
      error: isDark ? const Color(0xFFE79A93) : const Color(0xFFB3423A),
      onError: isDark ? AppColors.neutral900 : Colors.white,
      surface: surface,
      onSurface: onSurface,
    );

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final textTheme = TextStyles.figtreeTextTheme(
      base.textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      dividerColor: divider,
      splashFactory: InkRipple.splashFactory,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        titleTextStyle: TextStyles.h4(color: onSurface),
        contentTextStyle: textTheme.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentSeed,
          foregroundColor: bg,
          disabledBackgroundColor: accentSeed.withValues(alpha: 0.45),
          disabledForegroundColor: bg.withValues(alpha: 0.8),
          textStyle: TextStyles.heading(size: 15),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: divider),
          textStyle: TextStyles.heading(size: 15),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentSeed,
          textStyle: TextStyles.heading(size: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: accentSeed, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentSeed,
        foregroundColor: bg,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyles.h4(color: onSurface),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(),
      ),
      iconTheme: IconThemeData(color: onSurface),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accentSeed : divider,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accentSeed : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accentSeed.withValues(alpha: 0.5)
              : divider,
        ),
      ),
    );
  }
}
