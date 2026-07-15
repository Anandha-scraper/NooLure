import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/card_container.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/tag_chip.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final provider = context.watch<TripProvider>();
    final trip = provider.byId(tripId);

    if (trip == null) {
      return const AppScaffold(
        title: 'Trip',
        body: Center(child: Text('Trip not found')),
      );
    }

    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );

    return AppScaffold(
      title: trip.name,
      centerTitle: true,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 16, color: accentInk),
                    const SizedBox(width: 8),
                    Text(
                      trip.destination,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TagChip(trip.dateRange, variant: TagVariant.neutral),
                    TagChip(
                      '${trip.members.length} member${trip.members.length == 1 ? '' : 's'}',
                      variant: TagVariant.accent2,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Invite Code',
                  style: TextStyles.sectionLabel(color: onSurface),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: trip.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                  child: CardContainer(
                    elevation: CardElevation.sm,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          trip.inviteCode,
                          style: TextStyles.heading(
                            size: 18,
                            color: onSurface,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.copy,
                          size: 16,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Members',
                  style: TextStyles.sectionLabel(color: onSurface),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in trip.members)
                      TagChip(m, variant: TagVariant.accent2),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Checklist',
                      style: TextStyles.sectionLabel(color: onSurface),
                    ),
                    const Spacer(),
                    Text(
                      '${trip.items.where((i) => i.done).length}/${trip.items.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in trip.items)
                  _ChecklistRow(
                    item: item,
                    onToggle: () => provider.toggleItem(tripId, item.id),
                    onSurface: onSurface,
                  ),
                const SizedBox(height: 8),
                _AddItemRow(
                  onAdd: (title) => provider.addItem(tripId, title),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SecondaryButton(
              label: 'Delete Trip',
              height: 46,
              onPressed: () {
                provider.deleteTrip(tripId);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.onToggle,
    required this.onSurface,
  });

  final dynamic item;
  final VoidCallback onToggle;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              item.done ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 20,
              color: onSurface.withValues(alpha: item.done ? 0.4 : 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: item.done ? 0.4 : 1),
                  decoration:
                      item.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemRow extends StatefulWidget {
  const _AddItemRow({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<_AddItemRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _controller,
            hintText: 'Add item...',
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(LucideIcons.plus, size: 20),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            widget.onAdd(text);
            _controller.clear();
          },
        ),
      ],
    );
  }
}
