import 'package:flutter/material.dart';

import 'custom_textfield.dart';
import 'tag_chip.dart';

/// Free-text input with suggestion chips underneath, drawn from
/// `knownCategories()` — shared by Tasks' category field and Notes' tag
/// field so a value typed in one suggests in the other. Tapping a chip
/// replaces the field's text (single value, not multi-select).
class TagInputField extends StatelessWidget {
  const TagInputField({
    super.key,
    required this.controller,
    required this.suggestions,
    this.hintText,
    this.borderless = false,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final String? hintText;

  /// Renders the field without the boxed pill border — a plain, collapsed
  /// TextField instead of [CustomTextField]. Used where the surrounding
  /// screen is already borderless (e.g. the note editor); leave false to
  /// keep the default boxed look.
  final bool borderless;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        borderless
            ? TextField(
                controller: controller,
                decoration: InputDecoration.collapsed(hintText: hintText)
                    .copyWith(
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
              )
            : CustomTextField(controller: controller, hintText: hintText),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final current = controller.text.trim();
            final visible = suggestions.where((s) => s != current).toList();
            if (visible.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in visible)
                    TagChip(s, onTap: () => controller.text = s),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
