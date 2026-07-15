import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/known_categories.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/check_circle.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/tag_input_field.dart';
import '../../widgets/task_form_fields.dart';

/// Task detail / edit screen — a single read+edit view: title, due date,
/// priority, category, description and repeat are all editable, and a
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
  late TaskPriority _priority;
  late TaskRepeat _repeat;
  late bool _done;
  bool _seeded = false;

  void _seed(TaskModel task) {
    if (_seeded) return;
    _seeded = true;
    _titleController = TextEditingController(text: task.title);
    _categoryController = TextEditingController(text: task.category);
    _descriptionController = TextEditingController(text: task.description);
    _dueAt = task.dueAt;
    _priority = task.priority;
    _repeat = task.repeat;
    _done = task.done;
  }

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
                  onPick: () async {
                    final picked = await pickTaskDueDate(context, _dueAt);
                    if (picked == null || !mounted) return;
                    if (picked.isBefore(DateTime.now())) {
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
                      _dueAt = picked;
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
                Text(
                  'Repeats',
                  style: TextStyles.sectionLabel(color: onSurface),
                ),
                const SizedBox(height: 8),
                RepeatField(
                  value: _repeat,
                  onChanged: (v) => setState(() => _repeat = v),
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

  Future<void> _save(TaskProvider provider, TaskModel task) async {
    if (_dueAt != null && _dueAt!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pick a date and time that hasn't passed yet"),
        ),
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
        priority: _priority,
        category: category.isEmpty ? 'General' : category,
        description: _descriptionController.text.trim(),
        repeat: _repeat,
        done: _done,
      ),
    );
    navigator.pop();
  }
}
