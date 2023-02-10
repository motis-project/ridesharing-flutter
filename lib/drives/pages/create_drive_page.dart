import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../util/supabase_manager.dart';
import '../../util/trip/trip.dart';
import '../models/drive.dart';
import '../models/recurring_drive.dart';
import '../pages/drive_detail_page.dart';

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
    return WeekDaySelector(
      weekDays: _recurrenceOptions.weekDays,
      onWeekDaysChanged: (List<WeekDay> weekDays) => setState(() {
        _recurrenceOptions.weekDays = weekDays;
      }),
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('Every '),
        SizedBox(width: 80, child: intervalSizeField),
        SizedBox(width: 120, child: intervalTypeField),
      ],
    );
  }

  Widget buildUntilPicker() {
    return InkWell(
      onTap: showRecurrenceEndDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(_recurrenceOptions.getEndChoiceName(context)),
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
              _recurrenceOptions.endChoice = value!;
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

                      Widget row;

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
                                  _recurrenceOptions.setCustomDate(value);
                                });
                              }
                            }),
                            controller: _recurrenceOptions.customEndDateController,
                          );

                          row = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('Until '),
                              Flexible(child: datePicker),
                            ],
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

                          row = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('For '),
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
                              });
                            },
                          );

                          row = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('After '),
                              SizedBox(width: 45, child: occurenceField),
                              const Text(' occurrences'),
                            ],
                          );
                          break;
                      }

                      return RadioListTile<RecurrenceEndChoice>(
                        contentPadding: EdgeInsets.zero,
                        title: row,
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

class WeekDaySelector extends FormField<List<WeekDay>> {
  final List<WeekDay> weekDays;
  final ValueChanged<List<WeekDay>> onWeekDaysChanged;

  WeekDaySelector({
    super.key,
    this.weekDays = const <WeekDay>[],
    required this.onWeekDaysChanged,
  }) : super(
          builder: (FormFieldState<List<WeekDay>> state) {
            return Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: WeekDay.values
                      .map(
                        (WeekDay weekDay) => WeekDayButton(
                          weekDay: weekDay,
                          selected: weekDays.contains(weekDay),
                          onPressed: () {
                            if (weekDays.contains(weekDay)) {
                              weekDays.remove(weekDay);
                            } else {
                              weekDays.add(weekDay);
                            }
                            state.didChange(weekDays);
                          },
                        ),
                      )
                      .toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            );
          },
          validator: (List<WeekDay>? value) {
            if (value == null || value.isEmpty) {
              return 'Please select at least one day';
            }
            return null;
          },
        );
}

class WeekDayButton extends StatelessWidget {
  const WeekDayButton({
    super.key,
    required this.weekDay,
    required this.onPressed,
    required this.selected,
  });

  final WeekDay weekDay;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromRadius(15),
          backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        onPressed: onPressed,
        child: Text(weekDay.getAbbreviation(context)),
      ),
    );
  }
}

class RecurrenceOptions {
  bool enabled = false;

  late RecurrenceEndChoice _endChoice;

  RecurrenceEndChoice get endChoice => _endChoice;

  set endChoice(RecurrenceEndChoice value) {
    _endChoice = value;
    if (value.isCustom) {
      if (value is RecurrenceEndChoiceDate) {
        customEndDateChoice = value;
      } else if (value is RecurrenceEndChoiceInterval) {
        customEndIntervalChoice = value;
      } else if (value is RecurrenceEndChoiceOccurrence) {
        customEndOccurrenceChoice = value;
      }
    }
  }

  late final List<WeekDay> weekDays;

  late RecurrenceInterval recurrenceInterval;
  final TextEditingController recurrenceIntervalSizeController = TextEditingController();
  final TextEditingController recurrenceIntervalTypeController = TextEditingController();

  void setRecurrenceIntervalType(RecurrenceIntervalType type, BuildContext context) {
    recurrenceInterval.intervalType = type;
    recurrenceIntervalTypeController.text = type.getName(context);
  }

  RecurrenceEndChoiceDate customEndDateChoice = RecurrenceEndChoiceDate(null, isCustom: true);
  final TextEditingController customEndDateController = TextEditingController();

  void setCustomDate(DateTime date) {
    customEndDateChoice.date = date;
    customEndDateController.text = localeManager.formatDate(date);
  }

  RecurrenceEndChoiceInterval customEndIntervalChoice = RecurrenceEndChoiceInterval(null, null, isCustom: true);
  final TextEditingController customEndIntervalSizeController = TextEditingController();
  final TextEditingController customEndIntervalTypeController = TextEditingController();

  void setCustomEndIntervalType(RecurrenceIntervalType type, BuildContext context) {
    customEndIntervalChoice.intervalType = type;
    customEndIntervalTypeController.text = type.getName(context);
  }

  RecurrenceEndChoiceOccurrence customEndOccurrenceChoice = RecurrenceEndChoiceOccurrence(null, isCustom: true);
  final TextEditingController customEndOccurrenceController = TextEditingController();

  void setCustomEndOccurrence(int occurrence) {
    customEndOccurrenceChoice.occurrences = occurrence;
    customEndOccurrenceController.text = occurrence.toString();
  }

  String? validationError;

  RecurrenceEndChoice getRecurrenceEndChoice(RecurrenceEndType type) {
    switch (type) {
      case RecurrenceEndType.date:
        return customEndDateChoice;
      case RecurrenceEndType.interval:
        return customEndIntervalChoice;
      case RecurrenceEndType.occurrence:
        return customEndOccurrenceChoice;
    }
  }

  String getEndChoiceName(BuildContext context) => endChoice.getName(context, weekDays: weekDays);

  RecurrenceOptions({
    required RecurrenceEndChoice endChoice,
    required this.recurrenceInterval,
    List<WeekDay>? weekDays,
    required BuildContext context,
  }) {
    _endChoice = endChoice;
    recurrenceIntervalSizeController.text = recurrenceInterval.intervalSize.toString();
    recurrenceIntervalTypeController.text = recurrenceInterval.intervalType.getName(context);
    this.weekDays = weekDays ?? <WeekDay>[];
  }

  void dispose() {
    recurrenceIntervalSizeController.dispose();
    recurrenceIntervalTypeController.dispose();
    customEndDateController.dispose();
    customEndIntervalSizeController.dispose();
    customEndIntervalTypeController.dispose();
    customEndOccurrenceController.dispose();
  }

  bool validate({bool createError = true}) {
    final String? error = endChoice.validate(weekDays: weekDays);
    if (createError || error == null) {
      validationError = error;
    }
    return error == null;
  }

  RecurrenceRule get recurrenceRule {
    final Frequency frequency = recurrenceInterval.intervalType.frequency;
    final int interval = recurrenceInterval.intervalSize!;
    final Set<ByWeekDayEntry> byWeekDays = weekDays.map((WeekDay weekDay) => ByWeekDayEntry(weekDay.index + 1)).toSet();

    DateTime? until;

    if (_endChoice.type == RecurrenceEndType.date) {
      until = (endChoice as RecurrenceEndChoiceDate).date;
    } else if (_endChoice.type == RecurrenceEndType.interval) {
      until = (endChoice as RecurrenceEndChoiceInterval).date;
    } else if (_endChoice.type == RecurrenceEndType.occurrence) {
      return RecurrenceRule(
        frequency: frequency,
        interval: interval,
        byWeekDays: byWeekDays,
        count: (endChoice as RecurrenceEndChoiceOccurrence).occurrences,
      );
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      byWeekDays: byWeekDays,
      until: until!.toUtc(),
    );
  }
}

class RecurrenceInterval {
  int? intervalSize;
  RecurrenceIntervalType intervalType;

  RecurrenceInterval(this.intervalSize, this.intervalType);

  String getName(BuildContext context, {List<WeekDay>? weekDays}) {
    final String? validationError = validate();
    if (validationError != null) return validationError;

    switch (intervalType) {
      case RecurrenceIntervalType.days:
        return 'Every $intervalSize ${intervalSize == 1 ? 'day' : 'days'}';
      case RecurrenceIntervalType.weeks:
        return 'Every $intervalSize ${intervalSize == 1 ? 'week' : 'weeks'}';
      case RecurrenceIntervalType.months:
        return 'Every $intervalSize ${intervalSize == 1 ? 'month' : 'months'}';
      case RecurrenceIntervalType.years:
        return 'Every $intervalSize ${intervalSize == 1 ? 'year' : 'years'}';
    }
  }

  String? validate() => intervalSize == null ? 'Interval size needed' : null;
}

abstract class RecurrenceEndChoice {
  RecurrenceEndType type;
  final bool isCustom;

  RecurrenceEndChoice({this.type = RecurrenceEndType.occurrence, this.isCustom = false});

  String getName(BuildContext context, {List<WeekDay>? weekDays});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecurrenceEndChoice && type == other.type && isCustom == other.isCustom;

  @override
  int get hashCode => type.hashCode ^ isCustom.hashCode;

  String? validate({List<WeekDay>? weekDays});
}

class RecurrenceEndChoiceDate extends RecurrenceEndChoice {
  DateTime? date;

  RecurrenceEndChoiceDate(this.date, {super.isCustom})
      : assert(date != null || isCustom),
        super(type: RecurrenceEndType.date);

  @override
  String getName(BuildContext context, {List<WeekDay>? weekDays}) =>
      validate(weekDays: weekDays) ?? 'Until ${localeManager.formatDate(date!)}';

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceDate && isCustom == other.isCustom && date == other.date;

  @override
  int get hashCode => isCustom.hashCode ^ date.hashCode;

  @override
  String? validate({List<WeekDay>? weekDays}) => date == null
      ? 'Date needed'
      : date!.isAfter(DateTime.now().add(const Duration(days: 10 * 365)))
          ? 'Date too far in the future'
          : null;
}

class RecurrenceEndChoiceInterval extends RecurrenceEndChoice {
  int? intervalSize;
  RecurrenceIntervalType? intervalType;

  RecurrenceEndChoiceInterval(this.intervalSize, this.intervalType, {super.isCustom})
      : assert((intervalSize != null && intervalType != null) || isCustom),
        super(type: RecurrenceEndType.interval);

  DateTime get date {
    final DateTime now = DateTime.now();
    switch (intervalType!) {
      case RecurrenceIntervalType.days:
        return now.add(Duration(days: intervalSize!));
      case RecurrenceIntervalType.weeks:
        return now.add(Duration(days: intervalSize! * 7));
      case RecurrenceIntervalType.months:
        final int nextMonth = now.month + intervalSize!;
        return DateTime(now.year + (nextMonth + 1) ~/ 12, (nextMonth + 1) % 12 - 1, now.day);
      case RecurrenceIntervalType.years:
        return DateTime(now.year + intervalSize!, now.month, now.day);
    }
  }

  @override
  String getName(BuildContext context, {List<WeekDay>? weekDays}) {
    final String? validationError = validate(weekDays: weekDays);
    if (validationError != null) return validationError;

    switch (intervalType!) {
      case RecurrenceIntervalType.days:
        return 'For $intervalSize ${intervalSize == 1 ? 'day' : 'days'}';
      case RecurrenceIntervalType.weeks:
        return 'For $intervalSize ${intervalSize == 1 ? 'week' : 'weeks'}';
      case RecurrenceIntervalType.months:
        return 'For $intervalSize ${intervalSize == 1 ? 'month' : 'months'}';
      case RecurrenceIntervalType.years:
        return 'For $intervalSize ${intervalSize == 1 ? 'year' : 'years'}';
    }
  }

  @override
  String? validate({List<WeekDay>? weekDays}) {
    if (intervalSize == null) return 'Interval size needed';
    if (intervalType == null) return 'Interval type needed';
    if (intervalSize! >= 100) return 'Interval too large';
    if (intervalSize! <= 0) return 'Interval is negative';
    if (intervalType == RecurrenceIntervalType.years && intervalSize! > 10) return 'Interval too large';
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceInterval &&
      isCustom == other.isCustom &&
      intervalSize == other.intervalSize &&
      intervalType == other.intervalType;

  @override
  int get hashCode => isCustom.hashCode ^ intervalSize.hashCode ^ intervalType.hashCode;
}

enum RecurrenceIntervalType { days, weeks, months, years }

extension RecurrenceEndIntervalTypeExtension on RecurrenceIntervalType {
  String getName(BuildContext context) {
    switch (this) {
      case RecurrenceIntervalType.days:
        return 'Days';
      case RecurrenceIntervalType.weeks:
        return 'Weeks';
      case RecurrenceIntervalType.months:
        return 'Months';
      case RecurrenceIntervalType.years:
        return 'Years';
    }
  }

  Frequency get frequency {
    switch (this) {
      case RecurrenceIntervalType.days:
        return Frequency.daily;
      case RecurrenceIntervalType.weeks:
        return Frequency.weekly;
      case RecurrenceIntervalType.months:
        return Frequency.monthly;
      case RecurrenceIntervalType.years:
        return Frequency.yearly;
    }
  }
}

class RecurrenceEndChoiceOccurrence extends RecurrenceEndChoice {
  int? occurrences;

  RecurrenceEndChoiceOccurrence(this.occurrences, {super.isCustom})
      : assert(occurrences != null || isCustom),
        super(type: RecurrenceEndType.occurrence);

  @override
  String getName(BuildContext context, {List<WeekDay>? weekDays}) =>
      validate(weekDays: weekDays) ?? 'After $occurrences ${occurrences == 1 ? 'occurrence' : 'occurrences'}';

  @override
  String? validate({List<WeekDay>? weekDays}) => occurrences == null
      ? 'Occurrences needed'
      : occurrences! >= 100
          ? 'Too many occurrences'
          : null;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceOccurrence && isCustom == other.isCustom && occurrences == other.occurrences;

  @override
  int get hashCode => isCustom.hashCode ^ occurrences.hashCode;
}

enum RecurrenceEndType { date, interval, occurrence }
