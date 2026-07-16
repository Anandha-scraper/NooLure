import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/text_styles.dart';
import '../../models/trip_model.dart';
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
  bool _saving = false;

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
          onPressed: _saving ? null : _createTrip,
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
          onPressed: _saving ? null : _joinTrip,
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

  Future<void> _createTrip() async {
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
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    TripModel? trip;
    Object? error;
    try {
      trip = await context.read<TripProvider>().createTrip(
        name: name,
        destination: destination,
        startDate: _startDate!,
        endDate: _endDate!,
        creatorUid: user.id,
        creatorName: user.name,
      );
    } catch (e) {
      debugPrint('Create trip failed: $e');
      trip = null;
      error = e;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error != null
                ? 'Could not create trip: ${_describe(error)}'
                : 'Could not create trip — check your connection and try again',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(trip.name);
  }

  String _describe(Object error) =>
      error is FirebaseException ? error.message ?? error.code : error.toString();

  Future<void> _joinTrip() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an invite code')),
      );
      return;
    }
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    bool joined;
    Object? error;
    try {
      joined = await context.read<TripProvider>().joinTrip(
        code,
        uid: user.id,
        name: user.name,
      );
    } catch (e) {
      debugPrint('Join trip failed: $e');
      joined = false;
      error = e;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (!joined) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error != null
                ? 'Could not join trip: ${_describe(error)}'
                : 'No trip found with that code',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }
}
