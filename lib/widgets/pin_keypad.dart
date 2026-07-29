import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';

/// 4-dot progress indicator + numeric keypad, shared by PIN setup and
/// unlock. Calls [onComplete] with the 4-digit string once entered; the
/// caller is responsible for clearing/resetting via [errorTick] on failure.
class PinKeypad extends StatefulWidget {
  const PinKeypad({super.key, required this.onComplete, this.errorTick = 0});

  final ValueChanged<String> onComplete;

  /// Bump this (e.g. a counter) to clear the entered digits — used after a
  /// failed unlock attempt so the dots reset for a retry.
  final int errorTick;

  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<PinKeypad> {
  String _digits = '';

  @override
  void didUpdateWidget(covariant PinKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorTick != oldWidget.errorTick) {
      setState(() => _digits = '');
    }
  }

  void _tap(String digit) {
    if (_digits.length >= 4) return;
    setState(() => _digits += digit);
    if (_digits.length == 4) {
      final complete = _digits;
      // Let the last dot render before handing off / clearing.
      Future.microtask(() => widget.onComplete(complete));
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _digits.length
                      ? primary
                      : onSurface.withValues(alpha: 0.15),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) _Key(d, onTap: () => _tap(d))],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 72, height: 72),
              _Key('0', onTap: () => _tap('0')),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  onPressed: _backspace,
                  icon: Icon(
                    LucideIcons.delete,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Material(
          color: AppColors.softFill(theme.colorScheme.primary, theme.brightness),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.softInk(
                    theme.colorScheme.primary,
                    theme.brightness,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
