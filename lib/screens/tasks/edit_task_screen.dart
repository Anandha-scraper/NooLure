import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/date_labels.dart';
import '../../core/utils/known_categories.dart';
import '../../models/routine_config.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/check_circle.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/routine_section.dart';
import '../../widgets/tag_input_field.dart';
import '../../widgets/task_form_fields.dart';

/// Task detail / edit screen — a single read+edit view: title, due date,
/// priority, category, description and routine are all editable, and a
/// completed task can be reopened (with any edited fields applied) via
/// "Reopen & Save".
class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  DateTime? _dueAt;
  bool _clearDueAt = false;
  late bool _hasDueTime;
  late TaskPriority _priority;
  late bool _done;
  bool _seeded = false;

  late bool _isRoutine;
  late RoutineFrequency _routineFrequency;
  late List<DateTime> _customDates;
  TimeOfDay? _preferredStart;
  TimeOfDay? _preferredEnd;

  void _seed(TaskModel task) {
    if (_seeded) return;
    _seeded = true;
    _titleController = TextEditingController(text: task.title);
    _categoryController = TextEditingController(text: task.category);
    _descriptionController = TextEditingController(text: task.description);
    _dueAt = task.dueAt;
    _hasDueTime = task.hasDueTime;
    _priority = task.priority;
    _done = task.done;
    _isRoutine = task.routine != null;
    _routineFrequency = task.routine?.frequency ?? RoutineFrequency.daily;
    _customDates = [...?task.routine?.customDates];
    _preferredStart = _minuteToTimeOfDay(task.routine?.preferredStartMinute);
    _preferredEnd = _minuteToTimeOfDay(task.routine?.preferredEndMinute);
  }

  static TimeOfDay? _minuteToTimeOfDay(int? minute) =>
      minute == null ? null : TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

  @override
  void dispose() {
    if (_seeded) {
      _titleController.dispose();
      _categoryController.dispose();
      _descriptionController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.byId(widget.taskId);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (task == null) {
      return const AppScaffold(
        title: 'Task',
        body: Center(child: Text('Task not found')),
      );
    }

    _seed(task);

    return AppScaffold(
      title: 'Task',
      centerTitle: true,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Row(
                  children: [
                    CheckCircle(
                      checked: _done,
                      onTap: () => setState(() => _done = !_done),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _done ? 'Completed' : 'Active',
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                  onPick: () async {
                    final picked = await pickTaskDueDate(
                      context,
                      _dueAt,
                      currentHasTime: _hasDueTime,
                    );
                    if (picked == null || !mounted) return;
                    if (isDueDateInPast(picked.dueAt, picked.hasTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Pick a date and time that hasn't passed yet",
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _dueAt = picked.dueAt;
                      _hasDueTime = picked.hasTime;
                      _clearDueAt = false;
                    });
                  },
                  onClear: () => setState(() {
                    _dueAt = null;
                    _clearDueAt = true;
                  }),
                ),
                const SizedBox(height: 18),
                Text(
                  'Priority',
                  style: TextStyles.sectionLabel(color: onSurface),
                ),
                const SizedBox(height: 8),
                PriorityField(
                  value: _priority,
                  onChanged: (v) => setState(() => _priority = v),
                ),
                const SizedBox(height: 18),
                Text(
                  'Category',
                  style: TextStyles.sectionLabel(color: onSurface),
                ),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Delete',
                    height: 46,
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await provider.trashTask(task.id);
                      navigator.pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: task.done && !_done ? 'Reopen & Save' : 'Save',
                    height: 46,
                    onPressed: () => _save(provider, task),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMissingDueDateSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Choose a due date to use Routine')),
    );
  }

  /// Preserves the original routine's completion log across edits — tweaking
  /// frequency/dates/window should never wipe out past Day-N history.
  RoutineConfig? _buildRoutine(TaskModel original) {
    if (!_isRoutine) return null;
    return RoutineConfig(
      frequency: _routineFrequency,
      startDate: original.routine?.startDate ?? DateLabels.dateOnly(original.createdAt),
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
      log: original.routine?.log ?? const [],
    );
  }

  Future<void> _save(TaskProvider provider, TaskModel task) async {
    if (_dueAt != null && isDueDateInPast(_dueAt!, _hasDueTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pick a date and time that hasn't passed yet"),
        ),
      );
      return;
    }
    if (_isRoutine && _dueAt == null) {
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
    await provider.updateTask(
      task.copyWith(
        title: _titleController.text.trim(),
        dueAt: _dueAt,
        clearDueAt: _clearDueAt,
        hasDueTime: _hasDueTime,
        priority: _priority,
        category: category.isEmpty ? 'General' : category,
        description: _descriptionController.text.trim(),
        routine: _buildRoutine(task),
        clearRoutine: !_isRoutine,
        done: _done,
      ),
    );
    navigator.pop();
  }
}
