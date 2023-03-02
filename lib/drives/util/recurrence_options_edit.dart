import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';

import '../../util/locale_manager.dart';
import 'recurrence.dart';
import 'recurrence_options_indicator.dart';
import 'text_with_fields.dart';
import 'week_day.dart';

class RecurrenceOptionsEdit extends StatefulWidget {
  final RecurrenceOptions recurrenceOptions;
  final List<RecurrenceEndChoice> predefinedEndChoices;
  final RecurrenceRule? originalRecurrenceRule;

  const RecurrenceOptionsEdit({
    super.key,
    required this.recurrenceOptions,
    required this.predefinedEndChoices,
    this.originalRecurrenceRule,
  });

  @override
  State<RecurrenceOptionsEdit> createState() => RecurrenceOptionsEditState();
}

class RecurrenceOptionsEditState extends State<RecurrenceOptionsEdit> {
  late final RecurrenceOptions recurrenceOptions;
  late final RecurrenceRule originalRecurrenceRule;
  late List<RecurrenceEndChoice> predefinedEndChoices;

  final TextEditingController recurrenceIntervalSizeController = TextEditingController();
  final TextEditingController recurrenceIntervalTypeController = TextEditingController();
  void setRecurrenceIntervalType(RecurrenceIntervalType type) {
    recurrenceOptions.recurrenceInterval.intervalType = type;
    recurrenceIntervalTypeController.text = type.getName(context);
  }

  late RecurrenceEndChoice _endChoice;

  RecurrenceEndChoiceDate customEndDateChoice = RecurrenceEndChoiceDate(null, isCustom: true);
  final TextEditingController customEndDateController = TextEditingController();
  void setCustomDate(DateTime date) {
    customEndDateChoice.date = date;
    customEndDateController.text = localeManager.formatDate(date);
  }

  RecurrenceEndChoiceInterval customEndIntervalChoice = RecurrenceEndChoiceInterval(null, null, isCustom: true);
  final TextEditingController customEndIntervalSizeController = TextEditingController();
  final TextEditingController customEndIntervalTypeController = TextEditingController();
  void setCustomEndIntervalType(RecurrenceIntervalType type) {
    customEndIntervalChoice.intervalType = type;
    customEndIntervalTypeController.text = type.getName(context);
  }

  RecurrenceEndChoiceOccurrence customEndOccurrenceChoice = RecurrenceEndChoiceOccurrence(null, isCustom: true);
  final TextEditingController customEndOccurrenceController = TextEditingController();

  final TextEditingController endChoiceController = TextEditingController();
  void rebuildEndChoiceController() => endChoiceController.text = _endChoice.getName(context);

  String? validationError;

  @override
  void initState() {
    super.initState();

    recurrenceOptions = widget.recurrenceOptions;
    originalRecurrenceRule = widget.originalRecurrenceRule ?? recurrenceOptions.recurrenceRule;
    predefinedEndChoices = widget.predefinedEndChoices;

    _endChoice = recurrenceOptions.endChoice;
  }

  @override
  void didChangeDependencies() {
    // This is here instead of initState because of the context
    recurrenceIntervalSizeController.text = recurrenceOptions.recurrenceInterval.intervalSize.toString();
    recurrenceIntervalTypeController.text = recurrenceOptions.recurrenceInterval.intervalType.getName(context);
    setEndChoice(_endChoice);
    rebuildEndChoiceController();

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();

    endChoiceController.dispose();
    recurrenceIntervalSizeController.dispose();
    recurrenceIntervalTypeController.dispose();
    customEndDateController.dispose();
    customEndIntervalSizeController.dispose();
    customEndIntervalTypeController.dispose();
    customEndOccurrenceController.dispose();
  }

  bool validate({bool createError = true}) {
    final String? error = _endChoice.validate(context);
    if (createError || error == null) {
      validationError = error;
    }
    return validationError == null;
  }

  void setEndChoice(RecurrenceEndChoice value) {
    _endChoice = value;
    if (value.isCustom) {
      if (value is RecurrenceEndChoiceDate) {
        customEndDateChoice = value;
        if (value.date != null) customEndDateController.text = localeManager.formatDate(value.date!);
      } else if (value is RecurrenceEndChoiceInterval) {
        customEndIntervalChoice = value;
        if (value.intervalSize != null) customEndIntervalSizeController.text = value.intervalSize.toString();
        if (value.intervalType != null) customEndIntervalTypeController.text = value.intervalType!.getName(context);
      } else if (value is RecurrenceEndChoiceOccurrence) {
        customEndOccurrenceChoice = value;
        if (value.occurrences != null) customEndOccurrenceController.text = value.occurrences.toString();
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        buildWeekDayPicker(),
        const SizedBox(height: 10),
        buildIntervalPicker(),
        const SizedBox(height: 10),
        buildUntilPicker(),
        if (recurrenceOptions.weekDays.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          buildIndicator(),
        ]
      ],
    );
  }

  Widget buildWeekDayPicker() {
    return WeekDayPicker(
      weekDays: recurrenceOptions.weekDays,
      context: context,
      onChanged: (List<WeekDay> weekDays) => setState(() {
        recurrenceOptions.weekDays = weekDays;
      }),
    );
  }

  Widget buildIntervalPicker() {
    final Widget intervalSizeField = TextFormField(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      controller: recurrenceIntervalSizeController,
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return S.of(context).pageCreateDriveIntervalSizeValidationEmpty;
        }
        return null;
      },
      onChanged: (String value) {
        setState(() {
          recurrenceOptions.recurrenceInterval.intervalSize =
              int.tryParse(value) ?? recurrenceOptions.recurrenceInterval.intervalSize;
        });
      },
      key: const Key('intervalSizeField'),
    );

    final Widget intervalTypeField = PopupMenuButton<RecurrenceIntervalType>(
      initialValue: recurrenceOptions.recurrenceInterval.intervalType,
      onSelected: (RecurrenceIntervalType value) {
        setState(
          () => setRecurrenceIntervalType(value),
        );
      },
      itemBuilder: (BuildContext context) => RecurrenceIntervalType.values
          // Days is not a valid interval type for recurring drives, just use weekly and every week day
          .where((RecurrenceIntervalType value) => value != RecurrenceIntervalType.days)
          .map(
            (RecurrenceIntervalType intervalType) => PopupMenuItem<RecurrenceIntervalType>(
              value: intervalType,
              key: Key('intervalType${intervalType.name}'),
              child: Text(intervalType.getName(context)),
            ),
          )
          .toList(),
      key: const Key('intervalTypeField'),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          readOnly: true,
          controller: recurrenceIntervalTypeController,
        ),
      ),
    );

    return TextWithFields(
      S.of(context).pageCreateDriveEveryInterval(TextWithFields.placeholder),
      fields: <Widget>[
        SizedBox(width: 80, child: intervalSizeField),
        SizedBox(width: 120, child: intervalTypeField),
      ],
      separator: const SizedBox(width: 10),
    );
  }

  Widget buildUntilPicker() {
    return SizedBox(
      width: 200,
      child: TextFormField(
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onTap: () => showRecurrenceEndDialog(),
        readOnly: true,
        controller: endChoiceController,
        key: const Key('untilField'),
      ),
    );
  }

  Widget buildIndicator() {
    return RecurrenceOptionsIndicator(
      before: originalRecurrenceRule,
      after: recurrenceOptions.recurrenceRule,
      start: recurrenceOptions.startedAt.isAfter(DateTime.now()) ? recurrenceOptions.startedAt : DateTime.now(),
    );
  }

  Future<void> showRecurrenceEndDialog() async {
    await showDialog<RecurrenceEndChoice>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, void Function(VoidCallback) innerSetState) {
          void onChanged(RecurrenceEndChoice? value) {
            innerSetState(() {
              setEndChoice(value!);
            });
          }

          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ...List<RadioListTile<RecurrenceEndChoice>>.generate(
                    predefinedEndChoices.length + RecurrenceEndType.values.length,
                    (int index) {
                      if (index < predefinedEndChoices.length) {
                        final RecurrenceEndChoice recurringEndChoice = predefinedEndChoices[index];

                        return RadioListTile<RecurrenceEndChoice>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(recurringEndChoice.getName(context)),
                          value: recurringEndChoice,
                          groupValue: _endChoice,
                          onChanged: onChanged,
                          key: Key('predefinedEndChoice$index'),
                        );
                      } else {
                        final RecurrenceEndType recurrenceEndType =
                            RecurrenceEndType.values[index - predefinedEndChoices.length];
                        final RecurrenceEndChoice recurrenceEndChoiceCustom = getRecurrenceEndChoice(recurrenceEndType);
                        final bool currentlySelected = _endChoice == recurrenceEndChoiceCustom;

                        Widget content;

                        switch (recurrenceEndType) {
                          case RecurrenceEndType.date:
                            final Widget datePicker = TextFormField(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: S.of(context).formDate,
                              ),
                              readOnly: true,
                              enabled: currentlySelected,
                              onTap: () => showDatePicker(
                                context: context,
                                initialDate: customEndDateChoice.date ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                              ).then((DateTime? value) {
                                if (value != null) {
                                  innerSetState(() {
                                    setCustomDate(value);
                                  });
                                }
                              }),
                              controller: customEndDateController,
                              key: const Key('customEndDateField'),
                            );

                            content = TextWithFields(
                              S.of(context).pageCreateDriveRecurrenceEndUntil(TextWithFields.placeholder),
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
                              controller: customEndIntervalSizeController,
                              onChanged: (String value) {
                                innerSetState(() {
                                  customEndIntervalChoice.intervalSize = int.tryParse(value);
                                });
                              },
                              key: const Key('customEndIntervalSizeField'),
                            );

                            final Widget intervalTypeField = PopupMenuButton<RecurrenceIntervalType>(
                              initialValue: customEndIntervalChoice.intervalType,
                              onSelected: (RecurrenceIntervalType value) => innerSetState(
                                () => setCustomEndIntervalType(value),
                              ),
                              enabled: currentlySelected,
                              itemBuilder: (BuildContext context) => RecurrenceIntervalType.values
                                  .map(
                                    (RecurrenceIntervalType intervalType) => PopupMenuItem<RecurrenceIntervalType>(
                                      value: intervalType,
                                      key: Key('customEndIntervalType${intervalType.name}'),
                                      child: Text(intervalType.getName(context)),
                                    ),
                                  )
                                  .toList(),
                              key: const Key('customEndIntervalTypeField'),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    // Default padding is EdgeInsets.fromLTRB(12, 24, 12, 16)
                                    contentPadding: const EdgeInsets.fromLTRB(6, 24, 12, 6),
                                    isDense: true,
                                    hintText: RecurrenceIntervalType.weeks.getName(context),
                                  ),
                                  enabled: currentlySelected,
                                  readOnly: true,
                                  controller: customEndIntervalTypeController,
                                ),
                              ),
                            );

                            content = TextWithFields(
                              S.of(context).pageCreateDriveRecurrenceEndFor(TextWithFields.placeholder),
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
                              controller: customEndOccurrenceController,
                              onChanged: (String value) {
                                innerSetState(() {
                                  customEndOccurrenceChoice.occurrences = int.tryParse(value);
                                });
                              },
                              key: const Key('customEndOccurenceField'),
                            );

                            content = TextWithFields(
                              S.of(context).pageCreateDriveRecurrenceEndAfterOccurrences(TextWithFields.placeholder),
                              fields: <Widget>[SizedBox(width: 45, child: occurenceField)],
                            );
                            break;
                        }

                        return RadioListTile<RecurrenceEndChoice>(
                          contentPadding: EdgeInsets.zero,
                          title: content,
                          value: recurrenceEndChoiceCustom,
                          groupValue: _endChoice,
                          onChanged: onChanged,
                          key: Key('recurrenceEndChoice$index'),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (!validate(createError: false))
                    Text(
                      S.of(context).pageCreateDriveRecurrenceEndError(validationError!),
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                key: const Key('okButtonRecurrenceEndDialog'),
                child: Text(S.of(context).okay),
                onPressed: () {
                  innerSetState(() {
                    final bool valid = validate();
                    if (valid) {
                      // Update the recurrence options in the parent widget
                      setState(() {
                        rebuildEndChoiceController();
                        recurrenceOptions.endChoice = _endChoice;
                      });
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
