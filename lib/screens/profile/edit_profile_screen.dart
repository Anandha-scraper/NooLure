import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppScaffold(
      title: 'Edit profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Name', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          CustomTextField(controller: _nameController),
          const SizedBox(height: 18),
          Text('Email', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 30),
          PrimaryButton(
            label: 'Save changes',
            onPressed: () {
              context.read<AuthProvider>().updateName(_nameController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
