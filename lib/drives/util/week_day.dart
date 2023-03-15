import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';

class WeekDayPicker extends FormField<List<WeekDay>> {
  final List<WeekDay> weekDays;
  final BuildContext context;
  final void Function(List<WeekDay>)? onChanged;

  WeekDayPicker({
    super.key,
    required this.weekDays,
    required this.context,
    this.onChanged,
    super.enabled,
  }) : super(
          builder: (FormFieldState<List<WeekDay>> state) {
            return Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: WeekDay.values
                      .map(
                        (WeekDay weekDay) => WeekDayButton(
                          weekDay: weekDay,
                          selected: weekDays.contains(weekDay),
                          onPressed: enabled
                              ? () {
                                  if (weekDays.contains(weekDay)) {
                                    weekDays.remove(weekDay);
                                  } else {
                                    weekDays.add(weekDay);
                                  }
                                  onChanged?.call(weekDays);
                                }
                              : null,
                        ),
                      )
                      .toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
          validator: (List<WeekDay>? _) {
            if (weekDays.isEmpty) {
              return S.of(context).weekDayPickerValidationEmpty;
            }
            return null;
          },
        );
}

class WeekDayButton extends StatelessWidget {
  const WeekDayButton({
    super.key,
    required this.weekDay,
    this.onPressed,
    required this.selected,
  });

  final WeekDay weekDay;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: onPressed,
      fillColor: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
      shape: const CircleBorder(),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      key: Key('weekDayButton${weekDay.name}'),
      child: Text(weekDay.getAbbreviation(context), style: const TextStyle(color: Colors.white)),
    );
  }
}

enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension WeekDayExtension on WeekDay {
  String getAbbreviation(BuildContext context) {
    switch (this) {
      case WeekDay.monday:
        return S.of(context).weekDayMondayAbbreviation;
      case WeekDay.tuesday:
        return S.of(context).weekDayTuesdayAbbreviation;
      case WeekDay.wednesday:
        return S.of(context).weekDayWednesdayAbbreviation;
      case WeekDay.thursday:
        return S.of(context).weekDayThursdayAbbreviation;
      case WeekDay.friday:
        return S.of(context).weekDayFridayAbbreviation;
      case WeekDay.saturday:
        return S.of(context).weekDaySaturdayAbbreviation;
      case WeekDay.sunday:
        return S.of(context).weekDaySundayAbbreviation;
    }
  }

  ByWeekDayEntry toByWeekDayEntry() => ByWeekDayEntry(index + 1);
}

extension ByWeekDayEntryExtension on ByWeekDayEntry {
  WeekDay toWeekDay() => WeekDay.values[day - 1];
}

extension DateTimeExtension on DateTime {
  WeekDay toWeekDay() => WeekDay.values[weekday - 1];
}
