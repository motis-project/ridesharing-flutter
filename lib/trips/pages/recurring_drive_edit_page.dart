import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../managers/storage_manager.dart';
import '../../managers/supabase_manager.dart';
import '../../trips/util/trip_overview.dart';
import '../../util/buttons/button.dart';
import '../../util/snackbar.dart';
import '../models/recurring_drive.dart';
import '../util/recurrence/edit_recurrence_options.dart';
import '../util/recurrence/recurrence.dart';

class RecurringDriveEditPage extends StatefulWidget {
  final Clock clock;
  final RecurringDrive recurringDrive;

  const RecurringDriveEditPage(this.recurringDrive, {super.key, this.clock = const Clock()});

  @override
  State<RecurringDriveEditPage> createState() => RecurringDriveEditPageState();
}

class RecurringDriveEditPageState extends State<RecurringDriveEditPage> {
  static const String _storageKey = 'expandPreviewEditRecurringDrivePage';

  late RecurringDrive _recurringDrive;
  late RecurrenceOptions recurrenceOptions;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool? _defaultPreviewExpanded;

  @override
  void initState() {
    super.initState();

    setState(() {
      _recurringDrive = widget.recurringDrive;
    });

    recurrenceOptions = RecurrenceOptions(
      startedAt: _recurringDrive.startedAt,
      recurrenceIntervalSize: _recurringDrive.recurrenceRule.interval,
      weekDays: _recurringDrive.weekDays,
      endChoice: _recurringDrive.recurrenceEndChoice.copyWith(isCustom: true),
    );

    loadDefaultPreviewExpanded();
  }

  Future<void> loadDefaultPreviewExpanded() async {
    await storageManager
        .readData<bool>(getStorageKey())
        .then((bool? value) => setState(() => _defaultPreviewExpanded = value));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    widgets.add(TripOverview(_recurringDrive));
    widgets.add(const Divider(thickness: 1));

    widgets.add(
      Form(
        key: _formKey,
        child: EditRecurrenceOptions(
          recurrenceOptions: recurrenceOptions,
          predefinedEndChoices: const <RecurrenceEndChoice>[],
          showPreview: _defaultPreviewExpanded ?? true,
          expansionCallback: (bool expanded) => storageManager.saveData(getStorageKey(), expanded),
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

    return WillPopScope(
      child: Scaffold(
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
      ),
      onWillPop: () async {
        final List<DateTime> previousInstances = getPreviousInstances();
        final List<DateTime> newInstances = getNewInstances();

        final int changedDrivesCount =
            newInstances.where((DateTime instance) => !previousInstances.contains(instance)).length +
                previousInstances.where((DateTime instance) => !newInstances.contains(instance)).length;

        if (changedDrivesCount == 0) return true;

        return showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(S.of(context).pageRecurringDriveSaveChangesDialogTitle),
            content: Text(S.of(context).pageRecurringDriveSaveChangesDialogContent),
            actions: <Widget>[
              TextButton(
                key: const Key('saveChangesLeaveButton'),
                child: Text(S.of(context).pageRecurringDriveSaveChangesDialogButtonLeave),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              TextButton(
                key: const Key('saveChangesStayButton'),
                child: Text(S.of(context).pageRecurringDriveSaveChangesDialogButtonStay),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ).then((bool? value) => value ?? false);
      },
    );
  }

  List<DateTime> getPreviousInstances() {
    final DateTime after =
        _recurringDrive.startedAt.isAfter(DateTime.now()) ? _recurringDrive.startedAt : DateTime.now();

    return _recurringDrive.recurrenceRule
        .getAllInstances(start: _recurringDrive.startedAt.toUtc(), after: after.toUtc(), includeAfter: true);
  }

  List<DateTime> getNewInstances() {
    final DateTime after =
        recurrenceOptions.startedAt.isAfter(DateTime.now()) ? recurrenceOptions.startedAt : DateTime.now();

    return recurrenceOptions.recurrenceRule
        .getAllInstances(start: recurrenceOptions.startedAt.toUtc(), after: after.toUtc(), includeAfter: true);
  }

  Future<void> _changeRecurringDrive() async {
    await _recurringDrive.setRecurrence(recurrenceOptions);
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

    final List<DateTime> previousInstances = getPreviousInstances();
    final List<DateTime> newInstances = getNewInstances();

    final int cancelledDrivesCount =
        previousInstances.where((DateTime instance) => !newInstances.contains(instance)).length;

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
    if (mounted) {
      Navigator.of(context).pop();
    }
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
              _stopRecurringDrive(widget.clock.now());

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

  String getStorageKey() {
    return '$_storageKey.${supabaseManager.currentProfile?.id}';
  }
}
