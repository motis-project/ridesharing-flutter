import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/buttons/button.dart';
import '../../util/snackbar.dart';
import '../../util/trip/trip_overview.dart';
import '../models/recurring_drive.dart';
import '../util/recurrence.dart';
import '../util/recurrence_options_edit.dart';

class RecurringDriveEditPage extends StatefulWidget {
  final RecurringDrive recurringDrive;

  const RecurringDriveEditPage(this.recurringDrive, {super.key});

  @override
  State<RecurringDriveEditPage> createState() => _RecurringDriveEditPageState();
}

class _RecurringDriveEditPageState extends State<RecurringDriveEditPage> {
  late RecurringDrive _recurringDrive;
  late RecurrenceOptions _recurrenceOptions;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    setState(() {
      _recurringDrive = widget.recurringDrive;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This is here instead of initState
    // because the context is needed for the recurrence options
    _recurrenceOptions = RecurrenceOptions(
      startedAt: _recurringDrive.startedAt,
      endChoice: _recurringDrive.recurrenceEndChoice,
      predefinedEndChoices: <RecurrenceEndChoice>[],
      recurrenceInterval: _recurringDrive.recurrenceInterval,
      weekDays: _recurringDrive.weekDays,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    widgets.add(TripOverview(_recurringDrive));
    widgets.add(const Divider(thickness: 1));

    widgets.add(
      Form(
        key: _formKey,
        child: RecurrenceOptionsEdit(
          recurrenceOptions: _recurrenceOptions,
          setState: setState,
        ),
      ),
    );

    widgets.add(const SizedBox(height: 20));

    widgets.add(
      Button(
        S.of(context).pageRecurringDriveEditButtonSaveChanges,
        onPressed: _showChangeDialog,
        key: const Key('saveRecurringDriveButton'),
      ),
    );

    widgets.add(const SizedBox(height: 10));

    widgets.add(
      Button.error(
        S.of(context).pageRecurringDriveEditButtonStop,
        onPressed: _showStopDialog,
        key: const Key('stopRecurringDriveButton'),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageRecurringDriveEditTitle),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets,
          ),
        ),
      ),
    );
  }

  Future<void> _changeRecurringDrive() async {
    await _recurringDrive.setRecurrence(_recurrenceOptions);
    if (mounted) {
      Navigator.of(context).pop();
      showSnackBar(
        context,
        S.of(context).pageRecurringDriveEditChangeDialogSnackBar,
        durationType: SnackBarDurationType.medium,
      );
    }
  }

  void _showChangeDialog() {
    if (!_formKey.currentState!.validate()) return;

    final List<DateTime> previousInstances =
        _recurringDrive.recurrenceRule.getAllInstances(start: _recurringDrive.startedAt.toUtc());
    final List<DateTime> newInstances =
        _recurrenceOptions.recurrenceRule.getAllInstances(start: _recurringDrive.startedAt.toUtc());

    final int cancelledDrivesCount = previousInstances
        .where((DateTime instance) => instance.isAfter(DateTime.now()) && !newInstances.contains(instance))
        .length;

    if (cancelledDrivesCount == 0) return unawaited(_changeRecurringDrive());

    showDialog<void>(
      context: context,
      builder: (BuildContext innerContext) => AlertDialog(
        title: Text(S.of(context).pageRecurringDriveEditChangeDialogTitle),
        content: Text(S.of(context).pageRecurringDriveEditChangeDialogContent(cancelledDrivesCount)),
        actions: <Widget>[
          TextButton(
            key: const Key('changeRecurringDriveNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(innerContext).pop(),
          ),
          TextButton(
            key: const Key('changeRecurringDriveYesButton'),
            onPressed: () {
              Navigator.of(innerContext).pop();
              _changeRecurringDrive();
            },
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecurringDrive(DateTime date) async {
    await _recurringDrive.stop(date);
    setState(() {});
  }

  void _showStopDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.of(context).pageRecurringDriveEditStopDialogTitle),
        content: Text(S.of(context).pageRecurringDriveEditStopDialogContent),
        actions: <Widget>[
          TextButton(
            key: const Key('stopRecurringDriveNoButton'),
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            key: const Key('stopRecurringDriveYesButton'),
            child: Text(S.of(context).yes),
            onPressed: () {
              _stopRecurringDrive(DateTime.now());

              Navigator.of(context).pop();
              showSnackBar(
                context,
                S.of(context).pageRecurringDriveEditStopDialogSnackBar,
                durationType: SnackBarDurationType.medium,
              );
            },
          ),
        ],
      ),
    );
  }
}