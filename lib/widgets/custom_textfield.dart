import 'package:flutter/material.dart';

/// Pill-shaped text input — `.input` in the design system. Wraps the themed
/// [InputDecorationTheme] set up in `app_theme.dart`.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
    this.borderRadius,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final bool obscureText;
  final VoidCallback? onTap;

  /// Overrides the themed pill (999) radius — e.g. for a multiline field
  /// where a fully round border reads oddly. Leave null to inherit the
  /// shared [InputDecorationTheme].
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    final divider = Theme.of(context).dividerColor;
    final accent = Theme.of(context).colorScheme.primary;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      obscureText: obscureText,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: radius == null
            ? null
            : OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: divider),
              ),
        enabledBorder: radius == null
            ? null
            : OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: divider),
              ),
        focusedBorder: radius == null
            ? null
            : OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: accent, width: 2),
              ),
      ),
    );
  }
}
