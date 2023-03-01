import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';

import '../../util/locale_manager.dart';
import 'week_day.dart';

class RecurrenceOptions {
  RecurrenceOptions({
    required this.startedAt,
    required this.recurrenceInterval,
    required this.endChoice,
    this.weekDays = const <WeekDay>[],
  });

  DateTime startedAt;

  RecurrenceEndChoice endChoice;

  List<WeekDay> weekDays;

  RecurrenceInterval recurrenceInterval;

  RecurrenceRule get recurrenceRule {
    final Frequency frequency = recurrenceInterval.intervalType.frequency;
    final int interval = recurrenceInterval.intervalSize!;
    final Set<ByWeekDayEntry> byWeekDays = weekDays.map((WeekDay weekDay) => weekDay.toByWeekDayEntry()).toSet();

    DateTime? until;

    if (endChoice.type == RecurrenceEndType.date) {
      until = (endChoice as RecurrenceEndChoiceDate).date;
    } else if (endChoice.type == RecurrenceEndType.interval) {
      until = (endChoice as RecurrenceEndChoiceInterval).getDate(startedAt);
    } else if (endChoice.type == RecurrenceEndType.occurrence) {
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
      // Make sure the date is at the end of the day to create inclusive dates
      until: until!.copyWith(hour: 23, minute: 59).toUtc(),
    );
  }
}

class RecurrenceInterval {
  int? intervalSize;
  RecurrenceIntervalType intervalType;

  RecurrenceInterval(this.intervalSize, this.intervalType);

  RecurrenceInterval.fromRecurrenceRule(RecurrenceRule recurrenceRule)
      : intervalSize = recurrenceRule.interval,
        intervalType = recurrenceRule.frequency.recurrenceIntervalType;

  String getName(BuildContext context) {
    final String? validationError = validate(context);
    if (validationError != null) return validationError;

    switch (intervalType) {
      case RecurrenceIntervalType.days:
        return S.of(context).recurrenceIntervalEveryDays(intervalSize!);
      case RecurrenceIntervalType.weeks:
        return S.of(context).recurrenceIntervalEveryWeeks(intervalSize!);
      case RecurrenceIntervalType.months:
        return S.of(context).recurrenceIntervalEveryMonths(intervalSize!);
      case RecurrenceIntervalType.years:
        return S.of(context).recurrenceIntervalEveryYears(intervalSize!);
    }
  }

  String? validate(BuildContext context) =>
      intervalSize == null ? S.of(context).recurrenceIntervalValidationIntervalNull : null;
}

abstract class RecurrenceEndChoice {
  final RecurrenceEndType type;
  final bool isCustom;

  const RecurrenceEndChoice({this.type = RecurrenceEndType.occurrence, this.isCustom = false});

  String getName(BuildContext context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecurrenceEndChoice && type == other.type && isCustom == other.isCustom;

  RecurrenceEndChoice copyWith({bool? isCustom});

  @override
  int get hashCode => type.hashCode ^ isCustom.hashCode;

  String? validate(BuildContext context);
}

class RecurrenceEndChoiceDate extends RecurrenceEndChoice {
  DateTime? date;

  RecurrenceEndChoiceDate(this.date, {super.isCustom})
      : assert(date != null || isCustom),
        super(type: RecurrenceEndType.date);

  @override
  String getName(BuildContext context) => S.of(context).recurrenceEndUntilDate(localeManager.formatDate(date!));

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceDate && isCustom == other.isCustom && date == other.date;

  @override
  RecurrenceEndChoice copyWith({bool? isCustom}) => RecurrenceEndChoiceDate(date, isCustom: isCustom ?? this.isCustom);

  @override
  int get hashCode => isCustom.hashCode ^ date.hashCode;

  @override
  String? validate(BuildContext context) => date == null ? S.of(context).recurrenceEndUntilDateValidationNull : null;
}

class RecurrenceEndChoiceInterval extends RecurrenceEndChoice {
  int? intervalSize;
  RecurrenceIntervalType? intervalType;

  RecurrenceEndChoiceInterval(this.intervalSize, this.intervalType, {super.isCustom})
      : assert((intervalSize != null && intervalType != null) || isCustom),
        super(type: RecurrenceEndType.interval);

  DateTime getDate(DateTime startedAt) {
    switch (intervalType!) {
      case RecurrenceIntervalType.days:
        return startedAt.add(Duration(days: intervalSize!));
      case RecurrenceIntervalType.weeks:
        return startedAt.add(Duration(days: intervalSize! * 7));
      case RecurrenceIntervalType.months:
        final int nextMonth = startedAt.month + intervalSize!;
        return DateTime(startedAt.year + (nextMonth + 1) ~/ 12, (nextMonth + 1) % 12 - 1, startedAt.day);
      case RecurrenceIntervalType.years:
        return DateTime(startedAt.year + intervalSize!, startedAt.month, startedAt.day);
    }
  }

  @override
  String getName(BuildContext context) {
    switch (intervalType!) {
      case RecurrenceIntervalType.days:
        return S.of(context).recurrenceEndForDays(intervalSize!);
      case RecurrenceIntervalType.weeks:
        return S.of(context).recurrenceEndForWeeks(intervalSize!);
      case RecurrenceIntervalType.months:
        return S.of(context).recurrenceEndForMonths(intervalSize!);
      case RecurrenceIntervalType.years:
        return S.of(context).recurrenceEndForYears(intervalSize!);
    }
  }

  @override
  String? validate(BuildContext context) {
    if (intervalSize == null) return S.of(context).recurrenceEndForValidationIntervalSizeNull;
    if (intervalType == null) return S.of(context).recurrenceEndForValidationIntervalTypeNull;
    if (intervalType == RecurrenceIntervalType.years && intervalSize! >= 10 || intervalSize! >= 100) {
      return S.of(context).recurrenceEndForValidationIntervalTooLarge;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceInterval &&
      isCustom == other.isCustom &&
      intervalSize == other.intervalSize &&
      intervalType == other.intervalType;

  @override
  RecurrenceEndChoice copyWith({bool? isCustom}) =>
      RecurrenceEndChoiceInterval(intervalSize, intervalType, isCustom: isCustom ?? this.isCustom);

  @override
  int get hashCode => isCustom.hashCode ^ intervalSize.hashCode ^ intervalType.hashCode;
}

class RecurrenceEndChoiceOccurrence extends RecurrenceEndChoice {
  int? occurrences;

  RecurrenceEndChoiceOccurrence(this.occurrences, {super.isCustom})
      : assert(occurrences != null || isCustom),
        super(type: RecurrenceEndType.occurrence);

  @override
  String getName(BuildContext context) => S.of(context).recurrenceEndAfterOccurrences(occurrences!);

  @override
  String? validate(BuildContext context) => occurrences == null
      ? S.of(context).recurrenceEndOccurrencesValidationNull
      : occurrences! >= 100
          ? S.of(context).recurrenceEndValidationOccurrencesTooMany
          : null;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceOccurrence && isCustom == other.isCustom && occurrences == other.occurrences;

  @override
  RecurrenceEndChoice copyWith({bool? isCustom}) =>
      RecurrenceEndChoiceOccurrence(occurrences, isCustom: isCustom ?? this.isCustom);

  @override
  int get hashCode => isCustom.hashCode ^ occurrences.hashCode;
}

enum RecurrenceEndType { date, interval, occurrence }

enum RecurrenceIntervalType { days, weeks, months, years }

extension RecurrenceIntervalTypeExtension on RecurrenceIntervalType {
  String getName(BuildContext context) {
    switch (this) {
      case RecurrenceIntervalType.days:
        return S.of(context).recurrenceIntervalDays;
      case RecurrenceIntervalType.weeks:
        return S.of(context).recurrenceIntervalWeeks;
      case RecurrenceIntervalType.months:
        return S.of(context).recurrenceIntervalMonths;
      case RecurrenceIntervalType.years:
        return S.of(context).recurrenceIntervalYears;
    }
  }

  Frequency get frequency {
    switch (this) {
      // This case is not possible, but the analyzer doesn't know that
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

extension FrequencyExtension on Frequency {
  RecurrenceIntervalType get recurrenceIntervalType {
    if (this == Frequency.daily) return RecurrenceIntervalType.days;
    if (this == Frequency.weekly) return RecurrenceIntervalType.weeks;
    if (this == Frequency.monthly) return RecurrenceIntervalType.months;
    if (this == Frequency.yearly) return RecurrenceIntervalType.years;
    throw Exception('Unknown frequency: $this');
  }
}
