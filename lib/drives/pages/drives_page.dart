import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase_manager.dart';
import '../../util/trip/drive_card.dart';
import '../../util/trip/recurring_drive_card.dart';
import '../../util/trip/trip_page_builder.dart';
import '../../util/trip/trip_stream_builder.dart';
import '../models/drive.dart';
import 'create_drive_page.dart';

class DrivesPage extends StatefulWidget {
  const DrivesPage({super.key});

  @override
  State<DrivesPage> createState() => _DrivesPageState();
}

class _DrivesPageState extends State<DrivesPage> {
  late final Stream<List<Drive>> _drives;

  @override
  void initState() {
    final int userId = supabaseManager.currentProfile!.id!;
    _drives = supabaseManager.supabaseClient
        .from('drives')
        .stream(primaryKey: <String>['id'])
        .eq('driver_id', userId)
        .order('start_time', ascending: true)
        .map(
          (List<Map<String, dynamic>> drive) => Drive.fromJsonList(drive),
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TripPageBuilder<dynamic>(
      title: S.of(context).pageDrivesTitle,
      tabs: <String, TripStreamBuilder<dynamic>>{
        S.of(context).widgetTripBuilderTabUpcoming: TripStreamBuilder<Drive>(
          key: const Key('upcomingTrips'),
          stream: _drives,
          emptyMessage: S.of(context).widgetTripBuilderNoUpcomingDrives,
          filterTrips: (List<Drive> drives) =>
              drives.where((Drive drive) => drive.shouldShowInListView(past: false)).toList(),
          itemBuilder: (Drive trip) => DriveCard(trip),
        ),
        S.of(context).widgetTripBuilderTabPast: TripStreamBuilder<Drive>(
          key: const Key('pastTrips'),
          stream: _drives,
          emptyMessage: S.of(context).widgetTripBuilderNoPastDrives,
          filterTrips: (List<Drive> drives) =>
              drives.reversed.where((Drive drive) => drive.shouldShowInListView(past: true)).toList(),
          itemBuilder: (Drive trip) => DriveCard(trip),
        ),
        S.of(context).widgetTripBuilderTabRecurring: TripStreamBuilder<Drive>(
          key: const Key('recurringDrives'),
          stream: _drives,
          emptyMessage: S.of(context).widgetTripBuilderNoPastDrives,
          filterTrips: (List<Drive> drives) {
            final Set<int> seen = <int>{};

            return drives
                .where((Drive drive) => drive.isUpcomingRecurringDriveInstance && seen.add(drive.recurringDriveId!))
                .toList()
              ..sort(
                (Drive a, Drive b) =>
                    a.status == DriveStatus.cancelledByRecurrenceRule ? 1 : a.startDateTime.compareTo(b.startDateTime),
              );
          },
          itemBuilder: (Drive drive) => RecurringDriveCard(drive.recurringDriveId!),
        )
      },
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: S.of(context).pageDrivesTooltipOfferRide,
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        key: const Key('drivesFAB'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void onPressed() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const CreateDrivePage()),
    );
  }
}
