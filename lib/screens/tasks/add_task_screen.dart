import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../core/utils/known_categories.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
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
  TaskPriority _priority = TaskPriority.medium;
  TaskRepeat _repeat = TaskRepeat.none;

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
          Text('Repeats', style: TextStyles.sectionLabel(color: onSurface)),
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
          ),
          const SizedBox(height: 30),
          ListenableBuilder(
            listenable: _titleController,
            builder: (context, _) => PrimaryButton(
              label: 'Add task',
              onPressed: _titleController.text.trim().isEmpty ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await pickTaskDueDate(context, _dueAt);
    if (picked == null || !mounted) return;
    setState(() => _dueAt = picked);
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final category = _categoryController.text.trim();
    await context.read<TaskProvider>().addTask(
      title: _titleController.text.trim(),
      dueAt: _dueAt,
      priority: _priority,
      category: category.isEmpty ? 'General' : category,
      description: _descriptionController.text.trim(),
      repeat: _repeat,
    );
    navigator.pop();
  }
}
