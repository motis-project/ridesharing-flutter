import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../account/models/profile.dart';
import '../../util/buttons/button.dart';
import '../../util/buttons/labeled_checkbox.dart';
import '../../util/fields/increment_field.dart';
import '../../util/locale_manager.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/search/start_destination_timeline.dart';
import '../../util/snackbar.dart';
import '../../util/storage_manager.dart';
import '../../util/supabase_manager.dart';
import '../../util/trip/trip.dart';
import '../models/drive.dart';
import '../models/recurring_drive.dart';
import '../pages/drive_detail_page.dart';
import '../util/recurrence.dart';
import '../util/recurrence_options_edit.dart';
import '../util/week_day.dart';
import 'recurring_drive_detail_page.dart';

class CreateDrivePage extends StatefulWidget {
  // This is needed in order to mock the time in tests
  final Clock clock;
  const CreateDrivePage({super.key, this.clock = const Clock()});

  @override
  State<CreateDrivePage> createState() => _CreateDrivePageState();
}

class _CreateDrivePageState extends State<CreateDrivePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageCreateDriveTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SingleChildScrollView(child: CreateDriveForm(clock: widget.clock)),
        ),
      ),
    );
  }
}

class CreateDriveForm extends StatefulWidget {
  final Clock clock;
  const CreateDriveForm({super.key, this.clock = const Clock()});

  @override
  State<CreateDriveForm> createState() => CreateDriveFormState();
}

class CreateDriveFormState extends State<CreateDriveForm> {
  static const String _storageKey = 'expandPreviewCreateDrivePage';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController startController = TextEditingController();
  late AddressSuggestion startSuggestion;
  final TextEditingController destinationController = TextEditingController();
  late AddressSuggestion destinationSuggestion;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late DateTime selectedDate;
  late int seats;

  late RecurrenceOptions recurrenceOptions;
  bool recurringEnabled = false;
  bool? _defaultPreviewExpanded;

  static final List<RecurrenceEndChoice> predefinedRecurrenceEndChoices = <RecurrenceEndChoice>[
    RecurrenceEndChoiceInterval(1, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(3, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(6, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(1, RecurrenceIntervalType.years),
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.clock.now();
    seats = 1;
    recurrenceOptions = RecurrenceOptions(
      startedAt: selectedDate,
      recurrenceInterval: RecurrenceInterval(1, RecurrenceIntervalType.weeks),
      endChoice: predefinedRecurrenceEndChoices.last,
    );
    loadDefaultPreviewExpanded();
  }

  Future<void> loadDefaultPreviewExpanded() async {
    await storageManager
        .readData<bool>(getStorageKey())
        .then((bool? value) => setState(() => _defaultPreviewExpanded = value));
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    startController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute),
      builder: (BuildContext context, Widget? childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((TimeOfDay? value) {
      setState(() {
        if (value != null) {
          selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, value.hour, value.minute);
          _timeController.text = localeManager.formatTime(selectedDate);
        }
      });
    });
  }

  void _showDatePicker() {
    final DateTime firstDate = widget.clock.now();

    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((DateTime? value) {
      setState(() {
        if (value != null) {
          selectedDate = DateTime(value.year, value.month, value.day, selectedDate.hour, selectedDate.minute);
          recurrenceOptions.startedAt = selectedDate;
          _dateController.text = localeManager.formatDate(selectedDate);
        }
      });
    });
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final DateTime endDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedDate.hour + 2,
          selectedDate.minute,
        );
        final Profile driver = supabaseManager.currentProfile!;

        if (recurringEnabled) {
          final RecurringDrive recurringDrive = RecurringDrive(
            driverId: driver.id!,
            start: startSuggestion.name,
            startPosition: startSuggestion.position,
            end: destinationSuggestion.name,
            endPosition: destinationSuggestion.position,
            seats: seats,
            startTime: TimeOfDay.fromDateTime(selectedDate),
            endTime: TimeOfDay.fromDateTime(endDateTime),
            startedAt: recurrenceOptions.startedAt,
            recurrenceRule: recurrenceOptions.recurrenceRule,
            recurrenceEndType: recurrenceOptions.endChoice.type,
          );
          final Map<String, dynamic> data = await supabaseManager.supabaseClient
              .from('recurring_drives')
              .insert(recurringDrive.toJson())
              .select<Map<String, dynamic>>()
              .single();
          final RecurringDrive insertedRecurringDrive = RecurringDrive.fromJson(data);

          if (mounted) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => RecurringDriveDetailPage.fromRecurringDrive(insertedRecurringDrive),
              ),
            );
          }
        } else {
          final Drive drive = Drive(
            driverId: driver.id!,
            start: startSuggestion.name,
            startPosition: startSuggestion.position,
            end: destinationSuggestion.name,
            endPosition: destinationSuggestion.position,
            seats: seats,
            startDateTime: selectedDate,
            endDateTime: endDateTime,
          );
          final Map<String, dynamic> data = await supabaseManager.supabaseClient
              .from('drives')
              .insert(drive.toJson())
              .select<Map<String, dynamic>>()
              .single();
          final Drive insertedDrive = Drive.fromJson(data);

          if (mounted) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => DriveDetailPage.fromDrive(insertedDrive),
              ),
            );
          }
        }
      } on AuthException {
        showSnackBar(
          context,
          S.of(context).failureSnackBar,
        );
      }
    }
  }

  String? _timeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formTimeValidateEmpty;
    }
    // 59 seconds are added because the selected date's seconds are always 0
    if (selectedDate.add(const Duration(seconds: 59)).isBefore(widget.clock.now()) && !recurringEnabled) {
      return S.of(context).formTimeValidateFuture;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // This needs to happen on rebuild to make sure we pick up locale changes
    _dateController.text = localeManager.formatDate(selectedDate);
    _timeController.text = localeManager.formatTime(selectedDate);

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: StartDestinationTimeline(
              startController: startController,
              destinationController: destinationController,
              onStartSelected: (AddressSuggestion suggestion) => setState(() => startSuggestion = suggestion),
              onDestinationSelected: (AddressSuggestion suggestion) =>
                  setState(() => destinationSuggestion = suggestion),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  button: true,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: recurringEnabled ? S.of(context).formSinceDate : S.of(context).formDate,
                    ),
                    readOnly: true,
                    onTap: _showDatePicker,
                    controller: _dateController,
                    key: const Key('createDriveDatePicker'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: S.of(context).formStartTime,
                    ),
                    readOnly: true,
                    onTap: _showTimePicker,
                    controller: _timeController,
                    validator: _timeValidator,
                    key: const Key('createDriveTimePicker'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 150,
            child: IncrementField(
              initialValue: seats,
              maxValue: Trip.maxSelectableSeats,
              icon: Icon(
                Icons.chair,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              onChanged: (int? value) {
                setState(() {
                  seats = value!;
                });
              },
            ),
          ),
          LabeledCheckbox(
            label: S.of(context).pageCreateDriveRecurringCheckbox,
            value: recurringEnabled,
            onChanged: (bool? value) => setState(() {
              recurringEnabled = value!;
              if (value && recurrenceOptions.weekDays.isEmpty) {
                recurrenceOptions.weekDays = <WeekDay>[selectedDate.toWeekDay()];
              }
            }),
            key: const Key('createDriveRecurringCheckbox'),
          ),
          if (recurringEnabled) ...<Widget>[
            const SizedBox(height: 10),
            RecurrenceOptionsEdit(
              recurrenceOptions: recurrenceOptions,
              predefinedEndChoices: predefinedRecurrenceEndChoices,
              // Empty RecurrenceRule so that every day in the indicator is "new"
              originalRecurrenceRule: RecurrenceRule(frequency: Frequency.yearly, until: DateTime.now().toUtc()),
              showPreview: _defaultPreviewExpanded ?? false,
              expansionCallback: (bool expanded) => storageManager.saveData(getStorageKey(), expanded),
            ),
          ],
          const SizedBox(height: 10),
          Button.submit(
            S.of(context).pageCreateDriveButtonCreate,
            onPressed: _onSubmit,
            key: const Key('createDriveButton'),
          ),
        ],
      ),
    );
  }

  String getStorageKey() {
    return '$_storageKey.${supabaseManager.currentProfile?.id}';
  }
}
