import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/supabase_manager.dart';
import '../../trips/cards/drive_card.dart';
import '../../trips/models/trip.dart';
import '../../trips/util/trip_overview.dart';
import '../../util/buttons/custom_banner.dart';
import '../models/drive.dart';
import '../models/recurring_drive.dart';
import '../models/ride.dart';
import '../util/recurrence/week_day.dart';
import 'recurring_drive_edit_page.dart';

class RecurringDriveDetailPage extends StatefulWidget {
  final int id;
  final RecurringDrive? recurringDrive;

  const RecurringDriveDetailPage({super.key, required this.id}) : recurringDrive = null;
  RecurringDriveDetailPage.fromRecurringDrive(this.recurringDrive, {super.key}) : id = recurringDrive!.id!;

  @override
  State<RecurringDriveDetailPage> createState() => RecurringDriveDetailPageState();
}

class RecurringDriveDetailPageState extends State<RecurringDriveDetailPage> {
  RecurringDrive? _recurringDrive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _recurringDrive = widget.recurringDrive;
    });

    loadRecurringDrive();
  }

  Future<void> loadRecurringDrive() async {
    final Map<String, dynamic> data =
        await supabaseManager.supabaseClient.from('recurring_drives').select<Map<String, dynamic>>('''
      *,    
      drives(
        *,
        rides(
          *,
          rider: rider_id(*),
          chat: chat_id(
            *,
            messages: messages!messages_chat_id_fkey(*)
          )
        )
      )
    ''').eq('id', widget.id).single();

    setState(() {
      _recurringDrive = RecurringDrive.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    if (_recurringDrive != null) {
      widgets.add(TripOverview(_recurringDrive!));
      widgets.add(const Divider(thickness: 1));

      widgets.add(WeekDayPicker(context: context, enabled: false, weekDays: _recurringDrive!.weekDays));

      widgets.add(const SizedBox(height: 5.0));

      widgets.add(
        Text(
          S.of(context).recurrenceIntervalEveryWeeks(_recurringDrive!.recurrenceRule.interval!),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );

      widgets.add(const SizedBox(height: 5.0));

      widgets.add(
        Text(
          _recurringDrive!.recurrenceEndChoice.getName(context),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );

      widgets.add(const SizedBox(height: 10.0));
    }

    if (_fullyLoaded) {
      final RecurringDrive recurringDrive = _recurringDrive!;

      final List<Drive> upcomingDrives = recurringDrive.upcomingDrives
        ..sort((Drive a, Drive b) => a.startDateTime.compareTo(b.startDateTime));

      final List<Drive> previewedDrives = recurringDrive.recurrenceRule
          .getAllInstances(
        start: recurringDrive.startedAt.toUtc(),
        after: DateTime.now().add(Trip.creationInterval).toUtc(),
      )
          .map(
        (DateTime date) {
          final DateTime startDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            recurringDrive.startTime.hour,
            recurringDrive.startTime.minute,
          );

          return Drive(
            start: recurringDrive.start,
            startPosition: recurringDrive.startPosition,
            startDateTime: startDateTime,
            end: recurringDrive.end,
            endPosition: recurringDrive.endPosition,
            endDateTime: startDateTime.add(recurringDrive.duration),
            seats: recurringDrive.seats,
            driver: recurringDrive.driver,
            driverId: recurringDrive.driverId,
            rides: <Ride>[],
            status: DriveStatus.preview,
          );
        },
      ).toList();

      if (!recurringDrive.isStopped && (upcomingDrives.isNotEmpty || previewedDrives.isNotEmpty)) {
        final List<Widget> upcomingDrivesColumn = <Widget>[
          const SizedBox(height: 5.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              S.of(context).pageRecurringDriveDetailUpcomingDrives,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 10.0),
          ...upcomingDrives.map((Drive drive) => DriveCard(drive, loadData: false)),
          const SizedBox(height: 10.0),
          const Divider(thickness: 1),
          const SizedBox(height: 10.0),
          ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return DriveCard(previewedDrives[index], loadData: false);
            },
            itemCount: previewedDrives.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ];
        widgets.addAll(upcomingDrivesColumn);
      } else {
        widgets.add(const SizedBox(height: 10));
        widgets.add(
          Text(
            recurringDrive.isStopped
                ? S.of(context).pageRecurringDriveDetailUpcomingDrivesStopped
                : S.of(context).pageRecurringDriveDetailUpcomingDrivesEmpty,
            key: const Key('noUpcomingDrives'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
      widgets.add(const SizedBox(height: 5));
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    final Widget content = Column(
      children: <Widget>[
        if (_recurringDrive?.isStopped ?? false)
          CustomBanner.error(
            S.of(context).pageRecurringDriveDetailBannerStopped,
            key: const Key('stoppedRecurringDriveBanner'),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageRecurringDriveDetailTitle),
        actions: buildActions(),
      ),
      body: _recurringDrive == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRecurringDrive,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              ),
            ),
    );
  }

  List<Widget> buildActions() {
    if (_recurringDrive?.isStopped ?? false) return <Widget>[];

    return <Widget>[
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => RecurringDriveEditPage(_recurringDrive!),
                ),
              )
              .then((_) => loadRecurringDrive());
        },
      )
    ];
  }
}
