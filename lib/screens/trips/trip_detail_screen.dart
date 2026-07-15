import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
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

    final currentUid = context.watch<AuthProvider>().currentUser?.id;
    final isAdmin = trip.isAdmin(currentUid);
    final memberCount = trip.members.length;

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
                      '$memberCount member${memberCount == 1 ? '' : 's'}',
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
                    for (final m in trip.memberList)
                      TagChip(
                        m.name,
                        variant: TagVariant.accent2,
                        onTap: isAdmin && m.uid != trip.createdByUid
                            ? () => _confirmRemoveMember(
                                context,
                                provider,
                                tripId,
                                m,
                                currentUid!,
                              )
                            : null,
                      ),
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
                      '${trip.itemList.where((i) => i.isComplete(memberCount)).length}/${trip.itemList.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in trip.itemList)
                  _ChecklistRow(
                    item: item,
                    memberCount: memberCount,
                    respondedByMe:
                        currentUid != null && item.respondedBy(currentUid),
                    onToggleMine: currentUid == null
                        ? null
                        : () => provider.toggleResponse(
                            tripId,
                            item.id,
                            currentUid,
                          ),
                    isAdmin: isAdmin,
                    onDelete: currentUid == null
                        ? null
                        : () => provider.deleteItem(
                            tripId,
                            item.id,
                            requestingUid: currentUid,
                          ),
                    onSurface: onSurface,
                  ),
                const SizedBox(height: 8),
                if (isAdmin)
                  _AddItemRow(
                    onAdd: (title) => provider.addItem(
                      tripId,
                      title,
                      requestingUid: currentUid!,
                    ),
                  ),
              ],
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SecondaryButton(
                label: 'Delete Trip',
                height: 46,
                onPressed: () {
                  provider.deleteTrip(tripId, requestingUid: currentUid!);
                  Navigator.of(context).pop();
                },
              ),
            )
          else if (currentUid != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SecondaryButton(
                label: 'Leave Trip',
                height: 46,
                onPressed: () {
                  provider.removeMember(
                    tripId,
                    currentUid,
                    requestingUid: currentUid,
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    TripProvider provider,
    String tripId,
    TripMember member,
    String requestingUid,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name} from this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeMember(
                tripId,
                member.uid,
                requestingUid: requestingUid,
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.memberCount,
    required this.respondedByMe,
    required this.onToggleMine,
    required this.isAdmin,
    required this.onDelete,
    required this.onSurface,
  });

  final TripItem item;
  final int memberCount;
  final bool respondedByMe;
  final VoidCallback? onToggleMine;
  final bool isAdmin;
  final VoidCallback? onDelete;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: onToggleMine,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                respondedByMe ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 20,
                color: onSurface.withValues(alpha: respondedByMe ? 0.4 : 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(fontSize: 14, color: onSurface),
            ),
          ),
          Text(
            '${item.responseCount}/$memberCount',
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16),
              tooltip: 'Delete item',
              onPressed: onDelete,
            ),
        ],
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
