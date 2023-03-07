import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase_manager.dart';
import '../../util/trip/drive_card.dart';
import '../../util/trip/trip_overview.dart';
import '../models/drive.dart';
import '../models/recurring_drive.dart';
import '../util/week_day.dart';
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
  static const int shownDrivesCountDefault = 5;

  RecurringDrive? _recurringDrive;
  int _shownDrivesCount = shownDrivesCountDefault;
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
      _shownDrivesCount = max(_shownDrivesCount, 1);
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

      widgets.add(
        Text(_recurringDrive!.recurrenceEndChoice.getName(context)),
      );
      widgets.add(
        Text(_recurringDrive!.recurrenceInterval.getName(context)),
      );
    }

    if (_fullyLoaded) {
      final RecurringDrive recurringDrive = _recurringDrive!;

      final List<Drive> upcomingDrives = recurringDrive.upcomingDrives
        ..sort((Drive a, Drive b) => a.startDateTime.compareTo(b.startDateTime));
      _shownDrivesCount = min(_shownDrivesCount, upcomingDrives.length);
      if (upcomingDrives.isNotEmpty) {
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
          ...upcomingDrives.take(_shownDrivesCount).map((Drive drive) => DriveCard(drive, loadData: false)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (_shownDrivesCount > 1)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _shownDrivesCount = max(_shownDrivesCount - shownDrivesCountDefault, 1);
                    });
                  },
                  key: const Key('showLessButton'),
                  child: Text(S.of(context).showLess),
                )
              else
                const SizedBox(),
              if (_shownDrivesCount < upcomingDrives.length)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _shownDrivesCount = _shownDrivesCount + shownDrivesCountDefault;
                    });
                  },
                  key: const Key('showMoreButton'),
                  child: Text(S.of(context).showMore),
                )
              else
                const SizedBox(),
            ],
          ),
        ];
        widgets.addAll(upcomingDrivesColumn);
      } else {
        widgets.add(const SizedBox(height: 10));
        widgets.add(
          Text(
            _recurringDrive!.stoppedAt == null
                ? S.of(context).pageRecurringDriveDetailUpcomingDrivesEmpty
                : S.of(context).pageRecurringDriveDetailUpcomingDrivesStopped,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageRecurringDriveDetailTitle),
        actions: _recurringDrive?.stoppedAt == null ? <Widget>[buildEditButton()] : null,
      ),
      body: _recurringDrive == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRecurringDrive,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widgets,
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildEditButton() {
    return IconButton(
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
    );
  }
}
