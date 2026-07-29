import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/date_labels.dart';
import '../../core/utils/known_categories.dart';
import '../../models/routine_config.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/routine_section.dart';
import '../../widgets/tag_input_field.dart';
import '../../widgets/task_form_fields.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Work');
  final _descriptionController = TextEditingController();

  /// Null means "someday" — a task with no date, rather than the old free-text
  /// time field that got stored verbatim and never meant anything.
  DateTime? _dueAt;
  bool _hasDueTime = true;
  TaskPriority _priority = TaskPriority.medium;
  bool _saving = false;

  bool _isRoutine = false;
  RoutineFrequency _routineFrequency = RoutineFrequency.daily;
  List<DateTime> _customDates = [];
  TimeOfDay? _preferredStart;
  TimeOfDay? _preferredEnd;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppScaffold(
      title: 'New task',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Title', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _titleController,
            hintText: 'e.g. Call mom',
          ),
          const SizedBox(height: 18),
          Text('Due', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          DueField(
            dueAt: _dueAt,
            hasDueTime: _hasDueTime,
            onPick: _pickDueDate,
            onClear: () => setState(() => _dueAt = null),
          ),
          const SizedBox(height: 18),
          Text('Priority', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          PriorityField(
            value: _priority,
            onChanged: (v) => setState(() => _priority = v),
          ),
          const SizedBox(height: 18),
          Text('Category', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          TagInputField(
            controller: _categoryController,
            suggestions: knownCategories(context),
            hintText: 'e.g. Work',
          ),
          const SizedBox(height: 18),
          RoutineSection(
            enabled: _isRoutine,
            onToggle: (v) {
              if (v && _dueAt == null) {
                _showMissingDueDateSnackBar();
                return;
              }
              setState(() => _isRoutine = v);
            },
            frequency: _routineFrequency,
            onFrequencyChanged: (v) => setState(() => _routineFrequency = v),
            customDates: _customDates,
            onCustomDatesChanged: (v) => setState(() => _customDates = v),
            preferredStart: _preferredStart,
            onPreferredStartChanged: (v) => setState(() => _preferredStart = v),
            preferredEnd: _preferredEnd,
            onPreferredEndChanged: (v) => setState(() => _preferredEnd = v),
            dueAt: _dueAt,
            onMissingDueDate: _showMissingDueDateSnackBar,
          ),
          const SizedBox(height: 18),
          Text(
            'Description',
            style: TextStyles.sectionLabel(color: onSurface),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _descriptionController,
            hintText: 'Add a description (optional)',
            maxLines: 3,
            borderRadius: BorderRadius.circular(22),
          ),
          const SizedBox(height: 30),
          ListenableBuilder(
            listenable: _titleController,
            builder: (context, _) => PrimaryButton(
              label: 'Add task',
              onPressed: _saving || _titleController.text.trim().isEmpty
                  ? null
                  : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await pickTaskDueDate(
      context,
      _dueAt,
      currentHasTime: _hasDueTime,
    );
    if (picked == null || !mounted) return;
    if (isDueDateInPast(picked.dueAt, picked.hasTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pick a date and time that hasn't passed yet"),
        ),
      );
      return;
    }
    setState(() {
      _dueAt = picked.dueAt;
      _hasDueTime = picked.hasTime;
    });
  }

  void _showMissingDueDateSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Choose a due date to use Routine')),
    );
  }

  RoutineConfig? _buildRoutine() {
    if (!_isRoutine) return null;
    return RoutineConfig(
      frequency: _routineFrequency,
      startDate: DateLabels.dateOnly(DateTime.now()),
      endDate: DateLabels.dateOnly(_dueAt!),
      customDates: _routineFrequency == RoutineFrequency.custom
          ? ([..._customDates]..sort())
          : const [],
      preferredStartMinute: _preferredStart == null
          ? null
          : _preferredStart!.hour * 60 + _preferredStart!.minute,
      preferredEndMinute: _preferredEnd == null
          ? null
          : _preferredEnd!.hour * 60 + _preferredEnd!.minute,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    final dueAt = _dueAt;
    if (dueAt != null && isDueDateInPast(dueAt, _hasDueTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pick a date and time that hasn't passed yet"),
        ),
      );
      return;
    }
    if (_isRoutine && dueAt == null) {
      _showMissingDueDateSnackBar();
      return;
    }
    if (_isRoutine &&
        _routineFrequency == RoutineFrequency.custom &&
        _customDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one date for this routine')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final category = _categoryController.text.trim();
    setState(() => _saving = true);
    await context.read<TaskProvider>().addTask(
      title: _titleController.text.trim(),
      dueAt: _dueAt,
      hasDueTime: _hasDueTime,
      priority: _priority,
      category: category.isEmpty ? 'General' : category,
      description: _descriptionController.text.trim(),
      routine: _buildRoutine(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    navigator.pop();
  }
}
