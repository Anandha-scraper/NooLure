import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/task_form_fields.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _codeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _destinationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return AppScaffold(
      title: 'New Trip',
      centerTitle: true,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: onSurface,
            unselectedLabelColor: onSurface.withValues(alpha: 0.5),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Create'),
              Tab(text: 'Join'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _createTab(onSurface),
                _joinTab(onSurface),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createTab(Color onSurface) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Text('Trip Name', style: TextStyles.sectionLabel(color: onSurface)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _nameController,
          hintText: 'e.g. Goa Beach Getaway',
        ),
        const SizedBox(height: 18),
        Text('Destination', style: TextStyles.sectionLabel(color: onSurface)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _destinationController,
          hintText: 'e.g. Goa, India',
        ),
        const SizedBox(height: 18),
        Text('Start Date', style: TextStyles.sectionLabel(color: onSurface)),
        const SizedBox(height: 8),
        DueField(
          dueAt: _startDate,
          onPick: () => _pickDate(isStart: true),
          onClear: () => setState(() => _startDate = null),
        ),
        const SizedBox(height: 18),
        Text('End Date', style: TextStyles.sectionLabel(color: onSurface)),
        const SizedBox(height: 8),
        DueField(
          dueAt: _endDate,
          onPick: () => _pickDate(isStart: false),
          onClear: () => setState(() => _endDate = null),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Create Trip',
          height: 46,
          onPressed: _createTrip,
        ),
      ],
    );
  }

  Widget _joinTab(Color onSurface) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        const SizedBox(height: 20),
        Text(
          'Enter the invite code shared by the trip organiser.',
          style: TextStyle(
            fontSize: 14,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Text('Invite Code', style: TextStyles.sectionLabel(color: onSurface)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _codeController,
          hintText: 'e.g. GOA2026',
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Join Trip',
          height: 46,
          onPressed: _joinTrip,
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = isStart ? _startDate : _endDate;
    final firstDate = isStart ? today : (_startDate ?? today);

    final date = await showDatePicker(
      context: context,
      initialDate: current ?? (isStart ? today : (_startDate ?? today)),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(date)) _endDate = null;
      } else {
        _endDate = date;
      }
    });
  }

  void _createTrip() {
    final name = _nameController.text.trim();
    final destination = _destinationController.text.trim();
    if (name.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and destination are required')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick both start and end dates')),
      );
      return;
    }
    final userName =
        context.read<AuthProvider>().currentUser?.name ?? 'You';
    context.read<TripProvider>().addTrip(
      name: name,
      destination: destination,
      startDate: _startDate!,
      endDate: _endDate!,
      createdBy: userName,
    );
    Navigator.of(context).pop();
  }

  void _joinTrip() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an invite code')),
      );
      return;
    }
    final userName =
        context.read<AuthProvider>().currentUser?.name ?? 'You';
    final joined = context.read<TripProvider>().joinTrip(code, userName);
    if (!joined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trip found with that code')),
      );
      return;
    }
    Navigator.of(context).pop();
  }
}
