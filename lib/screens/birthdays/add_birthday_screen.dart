import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/date_labels.dart';
import '../../providers/birthday_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddBirthdayScreen extends StatefulWidget {
  const AddBirthdayScreen({super.key});

  @override
  State<AddBirthdayScreen> createState() => _AddBirthdayScreenState();
}

class _AddBirthdayScreenState extends State<AddBirthdayScreen> {
  final _nameController = TextEditingController();
  final _relationController = TextEditingController(text: 'Friend');
  final _notesController = TextEditingController();

  DateTime? _birthDate;

  /// Whether the picked date's year is meaningful. Plenty of people know the
  /// day but not the year, so the year is stored separately and optionally.
  bool _knowsYear = true;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final date = _birthDate;

    return AppScaffold(
      title: 'New birthday',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Name', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _nameController,
            hintText: 'e.g. Maya Kapoor',
          ),
          const SizedBox(height: 18),
          Text('Relation', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _relationController,
            hintText: 'e.g. Sister',
          ),
          const SizedBox(height: 18),
          Text('Birthday', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.cake,
                    size: 18,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    date == null
                        ? 'Tap to pick a date'
                        : DateLabels.monthDayLabel(date.month, date.day),
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withValues(
                        alpha: date == null ? 0.5 : 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: _knowsYear,
            onChanged: (v) => setState(() => _knowsYear = v ?? true),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'I know the birth year',
              style: TextStyle(fontSize: 13, color: onSurface),
            ),
            subtitle: Text(
              _knowsYear && date != null
                  ? 'Will show "Turning ${DateLabels.nextOccurrence(date.month, date.day).year - date.year}"'
                  : 'Leave off to track only the day',
              style: TextStyle(
                fontSize: 11,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Notes', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _notesController,
            hintText: 'Gift ideas, favourite cake…',
            maxLines: 4,
          ),
          const SizedBox(height: 30),
          ListenableBuilder(
            listenable: _nameController,
            builder: (context, _) => PrimaryButton(
              label: 'Add birthday',
              onPressed:
                  _nameController.text.trim().isEmpty || _birthDate == null
                  ? null
                  : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select birthday',
    );
    if (picked == null) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    final date = _birthDate;
    if (date == null) return;

    final navigator = Navigator.of(context);
    await context.read<BirthdayProvider>().addBirthday(
      name: _nameController.text.trim(),
      relation: _relationController.text.trim().isEmpty
          ? 'Friend'
          : _relationController.text.trim(),
      month: date.month,
      day: date.day,
      birthYear: _knowsYear ? date.year : null,
      notes: _notesController.text.trim(),
    );
    navigator.pop();
  }
}
