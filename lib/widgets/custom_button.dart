import 'package:flutter/material.dart';

/// Solid pill button — `.btn-primary` in the design system.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.height = 48,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(label),
          ],
        ),
      ),
    );
    return child;
  }
}

/// Outlined pill button — `.btn-secondary`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.height = 48,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// 58px circular FAB — matches the mockup's accent-filled floating button
/// (the default Material FAB is 56px, so this pins an exact size).
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed, this.icon = Icons.add});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: FloatingActionButton(
        onPressed: onPressed,
        shape: const CircleBorder(),
        child: Icon(icon, size: 26),
      ),
    );
  }
}

/// The Google "G" lettermark badge shown on the onboarding sign-in button —
/// a stand-in since the real multicolor Google glyph isn't available as a
/// bundled asset.
class GoogleLettermark extends StatelessWidget {
  const GoogleLettermark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
