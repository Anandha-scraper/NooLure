import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Caprasimo (display headings) over Figtree (body), per the Organic system.
class TextStyles {
  TextStyles._();

  static TextStyle heading({required double size, Color? color}) =>
      GoogleFonts.caprasimo(
        fontSize: size,
        height: 1.12,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle h1({Color? color}) => heading(size: 42, color: color);
  static TextStyle h2({Color? color}) => heading(size: 32, color: color);
  static TextStyle h3({Color? color}) => heading(size: 25, color: color);
  static TextStyle h4({Color? color}) => heading(size: 20, color: color);

  /// Small uppercase section labels (e.g. "Subtasks", "Notes"). Caprasimo
  /// doesn't read well at this size, so these use bold Figtree instead even
  /// though the mockup marks them up as headings.
  static TextStyle sectionLabel({Color? color}) => GoogleFonts.figtree(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextTheme figtreeTextTheme(TextTheme base) =>
      GoogleFonts.figtreeTextTheme(base);

  // Card sub-styles — take BuildContext so opacity reads correctly against
  // the active theme's text color in both light and dark mode.
  static TextStyle cardKicker(BuildContext context) {
    final theme = Theme.of(context);
    return GoogleFonts.figtree(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: AppColors.accentInk(theme.colorScheme.primary, theme.brightness),
    );
  }

  static TextStyle cardTitle(BuildContext context) =>
      heading(size: 17, color: Theme.of(context).colorScheme.onSurface);

  static TextStyle cardBody(BuildContext context) => GoogleFonts.figtree(
    fontSize: 13,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
  );

  static TextStyle cardMeta(BuildContext context) => GoogleFonts.figtree(
    fontSize: 11,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
  );
}
