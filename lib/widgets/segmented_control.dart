import 'package:flutter/material.dart';

/// Pill-shaped multi-option switch — `.seg` / `.seg-opt` in the design
/// system. Used by Tasks (priority/repeat), Profile (Light/Dark), and
/// Home (birthday Month/Week scope).
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
    // The bordered pill is the scrolled *child*, not the scroll view itself —
    // a SingleChildScrollView always claims the full width its parent offers,
    // so putting the border there would stretch it even when every option
    // already fits. Wrapping it this way instead keeps the pill hugging its
    // content when it fits, and only makes the far side reachable by swipe
    // when it doesn't (e.g. Priority/Repeat, which can run past narrow
    // screens with no other way to reach the last option).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
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
      ),
    );
  }
}
