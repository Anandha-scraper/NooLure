import 'package:flutter/material.dart';

/// Pill-shaped multi-option switch — `.seg` / `.seg-opt` in the design
/// system. Used by Calendar (Month/Week/Agenda) and Profile (Light/Dark/
/// System).
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T value, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    final onSurface = scheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, option) in options.indexed)
            InkWell(
              onTap: () => onChanged(option.$1),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: option.$1 == value ? scheme.primary : null,
                  borderRadius: BorderRadius.circular(999),
                  border: i > 0
                      ? Border(left: BorderSide(color: divider))
                      : null,
                ),
                child: Text(
                  option.$2,
                  style: TextStyle(
                    fontSize: 13,
                    color: option.$1 == value ? scheme.onPrimary : onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
