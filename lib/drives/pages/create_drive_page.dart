import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../util/text_with_fields.dart';
import '../util/week_day.dart';

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
        final DateTime endTime = DateTime(
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
            endTime: TimeOfDay.fromDateTime(endTime),
            recurrenceRule: _recurrenceOptions.recurrenceRule,
          );
          final Map<String, dynamic> data = await supabaseManager.supabaseClient
              .from('recurring_drives')
              .insert(recurringDrive.toJson())
              .select<Map<String, dynamic>>()
              .single();
          final RecurringDrive insertedRecurringDrive = RecurringDrive.fromJson(data);

          if (mounted) {
            Navigator.pop(context, insertedRecurringDrive);
            // await Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute<void>(
            //     builder: (BuildContext context) => RecurringDriveDetailPage(insertedRecurringDrive),
            //   ),
            // );
          }
        } else {
          final Drive drive = Drive(
            driverId: driver.id!,
            start: _startSuggestion.name,
            startPosition: _startSuggestion.position,
            end: _destinationSuggestion.name,
            endPosition: _destinationSuggestion.position,
            seats: _seats,
            startTime: _selectedDate,
            endTime: endTime,
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
            label: 'Recurring',
            value: _recurrenceOptions.enabled,
            onChanged: (bool? value) => setState(() {
              _recurrenceOptions.enabled = value!;
            }),
          ),
          if (_recurrenceOptions.enabled) ...<Widget>[
            buildWeekDayPicker(),
            buildUntilPicker(),
            buildIntervalPicker(),
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

  Widget buildWeekDayPicker() {
    return WeekDayPicker(
      weekDays: _recurrenceOptions.weekDays,
      onWeekDaysChanged: (List<WeekDay> weekDays) => setState(() {
        _recurrenceOptions.weekDays = weekDays;
      }),
      context: context,
    );
  }

  Widget buildIntervalPicker() {
    final Widget intervalSizeField = TextFormField(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      controller: _recurrenceOptions.recurrenceIntervalSizeController,
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        if (int.tryParse(value)! <= 0) {
          return 'Please enter a positive value';
        }
        return null;
      },
      onChanged: (String value) {
        setState(() {
          _recurrenceOptions.recurrenceInterval.intervalSize = int.tryParse(value);
        });
      },
    );

    final Widget intervalTypeField = PopupMenuButton<RecurrenceIntervalType>(
      initialValue: _recurrenceOptions.recurrenceInterval.intervalType,
      onSelected: (RecurrenceIntervalType value) => setState(
        () => _recurrenceOptions.setRecurrenceIntervalType(value, context),
      ),
      itemBuilder: (BuildContext context) => RecurrenceIntervalType.values
          // Days is not a valid interval type for recurring drives, just use weekly and every week day
          .where((RecurrenceIntervalType value) => value != RecurrenceIntervalType.days)
          .map(
            (RecurrenceIntervalType intervalType) => PopupMenuItem<RecurrenceIntervalType>(
              value: intervalType,
              child: Text(intervalType.getName(context)),
            ),
          )
          .toList(),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          readOnly: true,
          controller: _recurrenceOptions.recurrenceIntervalTypeController,
        ),
      ),
    );

    return TextWithFields(
      'Every ${TextWithFields.placeholder}${TextWithFields.placeholder}',
      fields: <Widget>[
        SizedBox(width: 80, child: intervalSizeField),
        SizedBox(width: 120, child: intervalTypeField),
      ],
    );
  }

  Widget buildUntilPicker() {
    return SizedBox(
      width: 200,
      child: TextFormField(
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onTap: showRecurrenceEndDialog,
        readOnly: true,
        controller: _recurrenceOptions.endChoiceController,
      ),
    );
  }

  Future<void> showRecurrenceEndDialog() async {
    await showDialog<RecurrenceEndChoice>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, void Function(VoidCallback) innerSetState) {
          void onChanged(RecurrenceEndChoice? value) {
            innerSetState(() {
              _recurrenceOptions.setEndChoice(value!, context);
            });
          }

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ...List<RadioListTile<RecurrenceEndChoice>>.generate(
                  predefinedRecurrenceEndChoices.length + RecurrenceEndType.values.length,
                  (int index) {
                    if (index < predefinedRecurrenceEndChoices.length) {
                      final RecurrenceEndChoice recurringEndChoice = predefinedRecurrenceEndChoices[index];

                      return RadioListTile<RecurrenceEndChoice>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(recurringEndChoice.getName(context)),
                        value: recurringEndChoice,
                        groupValue: _recurrenceOptions.endChoice,
                        onChanged: onChanged,
                      );
                    } else {
                      final RecurrenceEndType recurrenceEndType =
                          RecurrenceEndType.values[index - predefinedRecurrenceEndChoices.length];
                      final RecurrenceEndChoice recurrenceEndChoiceCustom =
                          _recurrenceOptions.getRecurrenceEndChoice(recurrenceEndType);
                      final bool currentlySelected = _recurrenceOptions.endChoice == recurrenceEndChoiceCustom;

                      Widget content;

                      switch (recurrenceEndType) {
                        case RecurrenceEndType.date:
                          final Widget datePicker = TextFormField(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: S.of(context).formDate,
                            ),
                            readOnly: true,
                            enabled: currentlySelected,
                            onTap: () => showDatePicker(
                              context: context,
                              initialDate: _recurrenceOptions.customEndDateChoice.date ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            ).then((DateTime? value) {
                              if (value != null) {
                                innerSetState(() {
                                  _recurrenceOptions.setCustomDate(value, context);
                                });
                              }
                            }),
                            controller: _recurrenceOptions.customEndDateController,
                          );

                          content = TextWithFields(
                            'Until ${TextWithFields.placeholder}',
                            fields: <Widget>[Flexible(child: datePicker)],
                          );
                          break;
                        case RecurrenceEndType.interval:
                          final Widget intervalSizeField = TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              // Default padding is EdgeInsets.fromLTRB(12, 24, 12, 16)
                              contentPadding: EdgeInsets.fromLTRB(6, 24, 12, 6),
                              hintText: '5',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            enabled: currentlySelected,
                            controller: _recurrenceOptions.customEndIntervalSizeController,
                            onChanged: (String value) {
                              innerSetState(() {
                                _recurrenceOptions.customEndIntervalChoice.intervalSize = int.tryParse(value);
                                _recurrenceOptions.rebuildEndChoiceController(context);
                              });
                            },
                          );

                          final Widget intervalTypeField = PopupMenuButton<RecurrenceIntervalType>(
                            initialValue: _recurrenceOptions.customEndIntervalChoice.intervalType,
                            onSelected: (RecurrenceIntervalType value) => innerSetState(
                              () => _recurrenceOptions.setCustomEndIntervalType(value, context),
                            ),
                            enabled: currentlySelected,
                            itemBuilder: (BuildContext context) => RecurrenceIntervalType.values
                                .map(
                                  (RecurrenceIntervalType intervalType) => PopupMenuItem<RecurrenceIntervalType>(
                                    value: intervalType,
                                    child: Text(intervalType.getName(context)),
                                  ),
                                )
                                .toList(),
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  // Default padding is EdgeInsets.fromLTRB(12, 24, 12, 16)
                                  contentPadding: EdgeInsets.fromLTRB(6, 24, 12, 6),
                                  isDense: true,
                                  hintText: 'Weeks',
                                ),
                                enabled: currentlySelected,
                                readOnly: true,
                                controller: _recurrenceOptions.customEndIntervalTypeController,
                              ),
                            ),
                          );

                          content = TextWithFields(
                            'For ${TextWithFields.placeholder}${TextWithFields.placeholder}',
                            fields: <Widget>[
                              SizedBox(width: 45, child: intervalSizeField),
                              SizedBox(width: 80, child: intervalTypeField),
                            ],
                          );
                          break;
                        case RecurrenceEndType.occurrence:
                          final Widget occurenceField = TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              // Default padding is EdgeInsets.fromLTRB(12, 24, 12, 16)
                              contentPadding: EdgeInsets.fromLTRB(6, 24, 12, 6),
                              hintText: '20',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            enabled: currentlySelected,
                            controller: _recurrenceOptions.customEndOccurrenceController,
                            onChanged: (String value) {
                              innerSetState(() {
                                _recurrenceOptions.customEndOccurrenceChoice.occurrences = int.tryParse(value);
                                _recurrenceOptions.rebuildEndChoiceController(context);
                              });
                            },
                          );

                          content = TextWithFields(
                            'After ${TextWithFields.placeholder} occurrences',
                            fields: <Widget>[SizedBox(width: 45, child: occurenceField)],
                          );
                          break;
                      }

                      return RadioListTile<RecurrenceEndChoice>(
                        contentPadding: EdgeInsets.zero,
                        title: content,
                        value: recurrenceEndChoiceCustom,
                        groupValue: _recurrenceOptions.endChoice,
                        onChanged: onChanged,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                if (!_recurrenceOptions.validate(createError: false) && _recurrenceOptions.validationError != null)
                  Text(
                    'Please select a valid recurrence end option: ${_recurrenceOptions.validationError}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                key: const Key('okButtonRecurrenceEndDialog'),
                child: Text(S.of(context).okay),
                onPressed: () {
                  innerSetState(() {
                    final bool valid = _recurrenceOptions.validate();
                    if (valid) {
                      // Update the recurrence options in the parent widget
                      setState(() {});
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
