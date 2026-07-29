import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/card_container.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/tag_chip.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final tripProvider = context.watch<TripProvider>();
    final trips = tripProvider.trips;
    final loadError = tripProvider.loadError;

    return AppScaffold(
      title: 'Trip Planner',
      drawerRoute: AppRoutes.trips,
      titleStyle: TextStyles.h2(color: onSurface),
      floatingActionButton: AppFab(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed(AppRoutes.addTrip);
          if (result is! String || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trip "$result" created')),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            '${trips.length} trip${trips.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13,
              color: onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 18),
          if (loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                "Couldn't load trips — check your connection and pull to retry",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (trips.isEmpty && loadError == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No trips yet — create one or join with an invite code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          for (final trip in trips)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TripCard(trip: trip),
            ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );

    final daysLeft = trip.daysLeft;
    final daysLabel = daysLeft > 0
        ? 'In $daysLeft day${daysLeft == 1 ? '' : 's'}'
        : daysLeft == 0
            ? 'Starts today'
            : 'Started';

    final itemList = trip.itemList;
    final memberCount = trip.members.length;
    final completeCount = itemList.where((i) => i.isComplete(memberCount)).length;

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.tripDetail, arguments: trip.id),
      child: CardContainer(
        elevation: CardElevation.sm,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 16, color: accentInk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.destination,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trip.name,
              style: TextStyles.heading(size: 17, color: onSurface),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagChip(trip.dateRange, variant: TagVariant.neutral),
                TagChip(
                  '${trip.members.length} member${trip.members.length == 1 ? '' : 's'}',
                  variant: TagVariant.accent2,
                ),
                TagChip(daysLabel, variant: TagVariant.accent),
              ],
            ),
            if (itemList.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '$completeCount/${itemList.length} items complete',
                style: TextStyle(
                  fontSize: 11,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
