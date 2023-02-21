import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'recurrence.dart';
import 'text_with_fields.dart';
import 'week_day.dart';

class RecurrenceOptionsEdit extends StatelessWidget {
  final RecurrenceOptions recurrenceOptions;
  final void Function(VoidCallback) setState;

  const RecurrenceOptionsEdit({
    super.key,
    required this.recurrenceOptions,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        buildWeekDayPicker(context),
        buildIntervalPicker(context),
        buildUntilPicker(context),
      ],
    );
  }

  Widget buildWeekDayPicker(BuildContext context) {
    return WeekDayPicker(
      weekDays: recurrenceOptions.weekDays,
      context: context,
    );
  }

  Widget buildIntervalPicker(BuildContext context) {
    final Widget intervalSizeField = TextFormField(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      controller: recurrenceOptions.recurrenceIntervalSizeController,
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return S.of(context).pageCreateDriveIntervalSizeValidationEmpty;
        }
        return null;
      },
      onChanged: (String value) {
        setState(() {
          recurrenceOptions.recurrenceInterval.intervalSize = int.tryParse(value);
        });
      },
      key: const Key('intervalSizeField'),
    );

    final Widget intervalTypeField = PopupMenuButton<RecurrenceIntervalType>(
      initialValue: recurrenceOptions.recurrenceInterval.intervalType,
      onSelected: (RecurrenceIntervalType value) {
        print('Hello Wordle');
        setState(
          () => recurrenceOptions.setRecurrenceIntervalType(value, context),
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
          controller: recurrenceOptions.recurrenceIntervalTypeController,
        ),
      ),
    );

    return TextWithFields(
      S.of(context).pageCreateDriveEveryInterval(TextWithFields.placeholder),
      fields: <Widget>[
        SizedBox(width: 80, child: intervalSizeField),
        SizedBox(width: 120, child: intervalTypeField),
      ],
    );
  }

  Widget buildUntilPicker(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextFormField(
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onTap: () => showRecurrenceEndDialog(context),
        readOnly: true,
        controller: recurrenceOptions.endChoiceController,
        key: const Key('untilField'),
      ),
    );
  }

  Future<void> showRecurrenceEndDialog(BuildContext context) async {
    await showDialog<RecurrenceEndChoice>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, void Function(VoidCallback) innerSetState) {
          void onChanged(RecurrenceEndChoice? value) {
            innerSetState(() {
              recurrenceOptions.setEndChoice(value!, context);
            });
          }

          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ...List<RadioListTile<RecurrenceEndChoice>>.generate(
                    recurrenceOptions.predefinedEndChoices.length + RecurrenceEndType.values.length,
                    (int index) {
                      if (index < recurrenceOptions.predefinedEndChoices.length) {
                        final RecurrenceEndChoice recurringEndChoice = recurrenceOptions.predefinedEndChoices[index];

                        return RadioListTile<RecurrenceEndChoice>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(recurringEndChoice.getName(context)),
                          value: recurringEndChoice,
                          groupValue: recurrenceOptions.endChoice,
                          onChanged: onChanged,
                          key: Key('predefinedEndChoice$index'),
                        );
                      } else {
                        final RecurrenceEndType recurrenceEndType =
                            RecurrenceEndType.values[index - recurrenceOptions.predefinedEndChoices.length];
                        final RecurrenceEndChoice recurrenceEndChoiceCustom =
                            recurrenceOptions.getRecurrenceEndChoice(recurrenceEndType);
                        final bool currentlySelected = recurrenceOptions.endChoice == recurrenceEndChoiceCustom;

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
                                initialDate: recurrenceOptions.customEndDateChoice.date ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                              ).then((DateTime? value) {
                                if (value != null) {
                                  innerSetState(() {
                                    recurrenceOptions.setCustomDate(value, context);
                                  });
                                }
                              }),
                              controller: recurrenceOptions.customEndDateController,
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
                              controller: recurrenceOptions.customEndIntervalSizeController,
                              onChanged: (String value) {
                                innerSetState(() {
                                  recurrenceOptions.customEndIntervalChoice.intervalSize = int.tryParse(value);
                                  recurrenceOptions.rebuildEndChoiceController(context);
                                });
                              },
                              key: const Key('customEndIntervalSizeField'),
                            );

                            final Widget intervalTypeField = PopupMenuButton<RecurrenceIntervalType>(
                              initialValue: recurrenceOptions.customEndIntervalChoice.intervalType,
                              onSelected: (RecurrenceIntervalType value) => innerSetState(
                                () => recurrenceOptions.setCustomEndIntervalType(value, context),
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
                                  controller: recurrenceOptions.customEndIntervalTypeController,
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
                              controller: recurrenceOptions.customEndOccurrenceController,
                              onChanged: (String value) {
                                innerSetState(() {
                                  recurrenceOptions.customEndOccurrenceChoice.occurrences = int.tryParse(value);
                                  recurrenceOptions.rebuildEndChoiceController(context);
                                });
                              },
                              key: const Key('customEndOccurrenceField'),
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
                          groupValue: recurrenceOptions.endChoice,
                          onChanged: onChanged,
                          key: Key('recurrenceEndChoice$index'),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (!recurrenceOptions.validate(context, createError: false) &&
                      recurrenceOptions.validationError != null)
                    Text(
                      S.of(context).pageCreateDriveRecurrenceEndError(recurrenceOptions.validationError!),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
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
                    final bool valid = recurrenceOptions.validate(context);
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
