import 'dart:math';

import 'package:flutter/material.dart';

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
  State<RecurringDriveDetailPage> createState() => _RecurringDriveDetailPageState();
}

class _RecurringDriveDetailPageState extends State<RecurringDriveDetailPage> {
  static const int _maxShownDrivesDefault = 5;

  RecurringDrive? _recurringDrive;
  int _maxShownDrives = _maxShownDrivesDefault;
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
      _maxShownDrives = min(_maxShownDrives, 1);
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

      final List<Drive> upcomingDrives = recurringDrive.upcomingDrives;
      _maxShownDrives = min(_maxShownDrives, upcomingDrives.length);
      if (upcomingDrives.isNotEmpty) {
        final List<Widget> upcomingDrivesColumn = <Widget>[
          const SizedBox(height: 5.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Upcoming drives',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 10.0),
          ...upcomingDrives.take(_maxShownDrives).map((Drive drive) => DriveCard(drive)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (_maxShownDrives > 1)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _maxShownDrives = max(_maxShownDrives - _maxShownDrivesDefault, 1);
                    });
                  },
                  child: const Text('Show less'),
                )
              else
                const SizedBox(),
              if (_maxShownDrives < upcomingDrives.length)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _maxShownDrives = _maxShownDrives + _maxShownDrivesDefault;
                    });
                  },
                  child: const Text('Show more'),
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
            'There are no upcoming drives for this recurring drive. Try changing the recurrence rule to plan new drives.',
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
        title: const Text('Recurring Drive Detail'),
        actions: <Widget>[buildEditButton()],
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
