import 'package:flutter/material.dart';

/// Design tokens for the "Cabin" palette (an override of the Organic design
/// system). Ramp steps 100-900 are perceptual tint/shade scales generated in
/// OKLCH by the source design tool; here they're approximated with sRGB
/// values sampled from that scale, since Dart has no built-in OKLCH mixer.
class AppColors {
  AppColors._();

  // Ground
  static const Color bg = Color(0xFFF8E1B7);
  static const Color text = Color(0xFF2E2010);

  /// Approximates `color-mix(in oklch, #F8E1B7 82%, black)`.
  static const Color surface = Color(0xFFCBB896);

  /// Apply as `AppColors.text.withValues(alpha: 0.16)` at usage sites rather
  /// than flattening to a hex, so it composites correctly over any bg.
  static Color get divider => text.withValues(alpha: 0.16);

  // Accent ramp (gold/terracotta), base = 500.
  static const Color accent100 = Color(0xFFF8F2E8);
  static const Color accent200 = Color(0xFFF0E5D1);
  static const Color accent300 = Color(0xFFE8D7B7);
  static const Color accent400 = Color(0xFFDCC090);
  static const Color accent500 = Color(0xFFCBA35C);
  static const Color accent600 = Color(0xFFBE9652);
  static const Color accent700 = Color(0xFFA47D3E);
  static const Color accent800 = Color(0xFF8F682E);
  static const Color accent900 = Color(0xFF754E1A);
  static const Color accent = accent500;

  // Accent-2 ramp (sage), base = 500.
  static const Color accent2_100 = Color(0xFFE2EAE5);
  static const Color accent2_200 = Color(0xFFD3E0D7);
  static const Color accent2_300 = Color(0xFFB6CBBD);
  static const Color accent2_400 = Color(0xFFA1B5A8);
  static const Color accent2_500 = Color(0xFF8CA592);
  static const Color accent2_600 = Color(0xFF809886);
  static const Color accent2_700 = Color(0xFF6F8575);
  static const Color accent2_800 = Color(0xFF607566);
  static const Color accent2_900 = Color(0xFF4B5E52);
  static const Color accent2 = accent2_500;

  // Neutral ramp.
  static const Color neutral100 = Color(0xFFFBF5E8);
  static const Color neutral200 = Color(0xFFF0E6D2);
  static const Color neutral300 = Color(0xFFDDCFAE);
  static const Color neutral400 = Color(0xFFC2B18A);
  static const Color neutral500 = Color(0xFFA3906C);
  static const Color neutral600 = Color(0xFF83714F);
  static const Color neutral700 = Color(0xFF64553A);
  static const Color neutral800 = Color(0xFF453A27);
  static const Color neutral900 = Color(0xFF2A2216);

  // Single-use highlight (pinned note card).
  static const Color highlight = Color(0xFFFFDE59);
  static const Color highlightText = Color(0xFF4A3A00);

  // Dark theme ground — no mockup coverage; keeps the same accent hues and
  // swaps the neutral base so brand identity carries over.
  static const Color darkBg = neutral900;
  static const Color darkSurface = neutral800;
  static const Color darkText = neutral100;
  static Color get darkDivider => darkText.withValues(alpha: 0.16);

  // Elevation shadows — soft, near-black tinted, tuned to the warm ground.
  static List<BoxShadow> shadowSm(Brightness brightness) => [
    BoxShadow(
      color: (brightness == Brightness.dark ? Colors.black : neutral900)
          .withValues(alpha: 0.14),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> shadowMd(Brightness brightness) => [
    BoxShadow(
      color: (brightness == Brightness.dark ? Colors.black : neutral900)
          .withValues(alpha: 0.16),
      offset: const Offset(0, 3),
      blurRadius: 10,
    ),
  ];

  static List<BoxShadow> shadowLg(Brightness brightness) => [
    BoxShadow(
      color: (brightness == Brightness.dark ? Colors.black : neutral900)
          .withValues(alpha: 0.22),
      offset: const Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  // --- Brightness-aware derivations ---------------------------------------
  //
  // The ramps above are fixed light-mode swatches. Reaching for them directly
  // in a widget produces a near-white chip on a dark card, and pins the widget
  // to gold even when the user has picked sage. These helpers derive a shade
  // from whatever color is actually in play (usually `colorScheme.primary`),
  // so a widget follows both the accent setting and the active brightness.

  /// The same hue at a different lightness.
  static Color shade(Color color, double lightness) =>
      HSLColor.fromColor(color).withLightness(lightness.clamp(0, 1)).toColor();

  /// Soft fill behind a chip/pill of [color] — a pale tint in light mode, a
  /// deep muted one in dark.
  static Color softFill(Color color, Brightness brightness) =>
      brightness == Brightness.dark ? shade(color, 0.24) : shade(color, 0.90);

  /// Legible text/icon color on top of [softFill].
  static Color softInk(Color color, Brightness brightness) =>
      brightness == Brightness.dark ? shade(color, 0.80) : shade(color, 0.32);

  /// Accent-tinted ink that stays legible directly on the page background —
  /// for icons, "See all" links, and kickers.
  static Color accentInk(Color color, Brightness brightness) =>
      brightness == Brightness.dark ? shade(color, 0.70) : shade(color, 0.40);
}
