import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../account/models/profile.dart';
import '../../util/buttons/button.dart';
import '../../util/buttons/labeled_checkbox.dart';
import '../../util/fields/increment_field.dart';
import '../../util/locale_manager.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/search/start_destination_timeline.dart';
import '../../util/snackbar.dart';
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
  const CreateDrivePage({super.key});

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
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SingleChildScrollView(child: CreateDriveForm()),
      ),
    );
  }
}

class CreateDriveForm extends StatefulWidget {
  const CreateDriveForm({super.key});

  @override
  State<CreateDriveForm> createState() => _CreateDriveFormState();
}

class _CreateDriveFormState extends State<CreateDriveForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startController = TextEditingController();
  late AddressSuggestion _startSuggestion;
  final TextEditingController _destinationController = TextEditingController();
  late AddressSuggestion _destinationSuggestion;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late DateTime _selectedDate;
  late int _seats;

  late RecurrenceOptions _recurrenceOptions;

  static List<RecurrenceEndChoice> predefinedRecurrenceEndChoices = <RecurrenceEndChoice>[
    RecurrenceEndChoiceInterval(1, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(3, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(6, RecurrenceIntervalType.months),
    RecurrenceEndChoiceInterval(1, RecurrenceIntervalType.years),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _seats = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This is here instead of initState
    // because the context is needed for the recurrence options
    _recurrenceOptions = RecurrenceOptions(
      endChoice: predefinedRecurrenceEndChoices.last,
      recurrenceInterval: RecurrenceInterval(1, RecurrenceIntervalType.weeks),
      context: context,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    _recurrenceOptions.dispose();
    super.dispose();
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (BuildContext context, Widget? childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((TimeOfDay? value) {
      setState(() {
        if (value != null) {
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, value.hour, value.minute);
          _timeController.text = localeManager.formatTime(_selectedDate);
        }
      });
    });
  }

  void _showDatePicker() {
    final DateTime firstDate = DateTime.now();

    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((DateTime? value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(value.year, value.month, value.day, _selectedDate.hour, _selectedDate.minute);
          _dateController.text = localeManager.formatDate(_selectedDate);
        }
      });
    });
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final DateTime endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedDate.hour + 2,
          _selectedDate.minute,
        );
        final Profile driver = supabaseManager.currentProfile!;

        if (_recurrenceOptions.enabled) {
          final RecurringDrive recurringDrive = RecurringDrive(
            driverId: driver.id!,
            start: _startSuggestion.name,
            startPosition: _startSuggestion.position,
            end: _destinationSuggestion.name,
            endPosition: _destinationSuggestion.position,
            seats: _seats,
            startTime: TimeOfDay.fromDateTime(_selectedDate),
            endTime: TimeOfDay.fromDateTime(endDateTime),
            startedAt: _selectedDate,
            recurrenceRule: _recurrenceOptions.recurrenceRule,
            recurrenceEndType: _recurrenceOptions.endChoice.type,
          );
          final Map<String, dynamic> data = await supabaseManager.supabaseClient
              .from('recurring_drives')
              .insert(recurringDrive.toJson())
              .select<Map<String, dynamic>>()
              .single();
          final RecurringDrive insertedRecurringDrive = RecurringDrive.fromJson(data);

          if (mounted) {
            Navigator.pop(context, insertedRecurringDrive);
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
            start: _startSuggestion.name,
            startPosition: _startSuggestion.position,
            end: _destinationSuggestion.name,
            endPosition: _destinationSuggestion.position,
            seats: _seats,
            startDateTime: _selectedDate,
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
    if (_selectedDate.isBefore(DateTime.now())) {
      return S.of(context).formTimeValidateFuture;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // This needs to happen on rebuild to make sure we pick up locale changes
    _dateController.text = localeManager.formatDate(_selectedDate);
    _timeController.text = localeManager.formatTime(_selectedDate);

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: StartDestinationTimeline(
              startController: _startController,
              destinationController: _destinationController,
              onStartSelected: (AddressSuggestion suggestion) => setState(() => _startSuggestion = suggestion),
              onDestinationSelected: (AddressSuggestion suggestion) =>
                  setState(() => _destinationSuggestion = suggestion),
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
                      labelText: S.of(context).formDate,
                    ),
                    readOnly: true,
                    onTap: _showDatePicker,
                    controller: _dateController,
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
                      labelText: S.of(context).formTime,
                    ),
                    readOnly: true,
                    onTap: _showTimePicker,
                    controller: _timeController,
                    validator: _timeValidator,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 150,
            child: IncrementField(
              initialValue: _seats,
              maxValue: Trip.maxSelectableSeats,
              icon: Icon(
                Icons.chair,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              onChanged: (int? value) {
                setState(() {
                  _seats = value!;
                });
              },
            ),
          ),
          LabeledCheckbox(
            label: S.of(context).pageCreateDriveRecurringCheckbox,
            value: _recurrenceOptions.enabled,
            onChanged: (bool? value) => setState(() {
              _recurrenceOptions.enabled = value!;
              if (value && _recurrenceOptions.weekDays.isEmpty) {
                _recurrenceOptions.weekDays.add(_selectedDate.toWeekDay());
              }
            }),
          ),
          if (_recurrenceOptions.enabled) ...<Widget>[
            const SizedBox(height: 10),
            RecurrenceOptionsEdit(
              predefinedRecurrenceEndChoices: predefinedRecurrenceEndChoices,
              recurrenceOptions: _recurrenceOptions,
              setState: setState,
            ),
          ],
          const SizedBox(height: 10),
          Button.submit(
            S.of(context).pageCreateDriveButtonCreate,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }
}
