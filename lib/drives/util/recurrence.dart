import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

import '../../util/locale_manager.dart';
import 'week_day.dart';

class RecurrenceOptions {
  RecurrenceOptions({
    required RecurrenceEndChoice endChoice,
    required this.recurrenceInterval,
    List<WeekDay>? weekDays,
    required BuildContext context,
  }) {
    _endChoice = endChoice;
    endChoiceController.text = endChoice.getName(context);
    recurrenceIntervalSizeController.text = recurrenceInterval.intervalSize.toString();
    recurrenceIntervalTypeController.text = recurrenceInterval.intervalType.getName(context);
    this.weekDays = weekDays ?? <WeekDay>[];
  }

  bool enabled = false;

  late RecurrenceEndChoice _endChoice;
  final TextEditingController endChoiceController = TextEditingController();
  void rebuildEndChoiceController(BuildContext context) => endChoiceController.text = _endChoice.getName(context);

  RecurrenceEndChoice get endChoice => _endChoice;

  void setEndChoice(RecurrenceEndChoice value, BuildContext context) {
    _endChoice = value;
    rebuildEndChoiceController(context);
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
    rebuildEndChoiceController(context);
  }

  RecurrenceEndChoiceDate customEndDateChoice = RecurrenceEndChoiceDate(null, isCustom: true);
  final TextEditingController customEndDateController = TextEditingController();

  void setCustomDate(DateTime date, BuildContext context) {
    customEndDateChoice.date = date;
    customEndDateController.text = localeManager.formatDate(date);
    rebuildEndChoiceController(context);
  }

  RecurrenceEndChoiceInterval customEndIntervalChoice = RecurrenceEndChoiceInterval(null, null, isCustom: true);
  final TextEditingController customEndIntervalSizeController = TextEditingController();
  final TextEditingController customEndIntervalTypeController = TextEditingController();

  void setCustomEndIntervalType(RecurrenceIntervalType type, BuildContext context) {
    customEndIntervalChoice.intervalType = type;
    customEndIntervalTypeController.text = type.getName(context);
    rebuildEndChoiceController(context);
  }

  RecurrenceEndChoiceOccurrence customEndOccurrenceChoice = RecurrenceEndChoiceOccurrence(null, isCustom: true);
  final TextEditingController customEndOccurrenceController = TextEditingController();

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

  String getEndChoiceName(BuildContext context) => endChoice.getName(context);

  void dispose() {
    endChoiceController.dispose();
    recurrenceIntervalSizeController.dispose();
    recurrenceIntervalTypeController.dispose();
    customEndDateController.dispose();
    customEndIntervalSizeController.dispose();
    customEndIntervalTypeController.dispose();
    customEndOccurrenceController.dispose();
  }

  bool validate({bool createError = true}) {
    final String? error = endChoice.validate();
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
      // Make sure the date is at the end of the day to create inclusive dates
      until: until!.copyWith(hour: 23, minute: 59).toUtc(),
    );
  }
}

class RecurrenceInterval {
  int? intervalSize;
  RecurrenceIntervalType intervalType;

  RecurrenceInterval(this.intervalSize, this.intervalType);

  String getName(BuildContext context) {
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

  String getName(BuildContext context);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecurrenceEndChoice && type == other.type && isCustom == other.isCustom;

  @override
  int get hashCode => type.hashCode ^ isCustom.hashCode;

  String? validate();
}

class RecurrenceEndChoiceDate extends RecurrenceEndChoice {
  DateTime? date;

  RecurrenceEndChoiceDate(this.date, {super.isCustom})
      : assert(date != null || isCustom),
        super(type: RecurrenceEndType.date);

  @override
  String getName(BuildContext context) => validate() ?? 'Until ${localeManager.formatDate(date!)}';

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEndChoiceDate && isCustom == other.isCustom && date == other.date;

  @override
  int get hashCode => isCustom.hashCode ^ date.hashCode;

  @override
  String? validate() => date == null
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
    final String? validationError = validate();
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
  String? validate() {
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

class RecurrenceEndChoiceOccurrence extends RecurrenceEndChoice {
  int? occurrences;

  RecurrenceEndChoiceOccurrence(this.occurrences, {super.isCustom})
      : assert(occurrences != null || isCustom),
        super(type: RecurrenceEndType.occurrence);

  @override
  String getName(BuildContext context) =>
      validate() ?? 'After $occurrences ${occurrences == 1 ? 'occurrence' : 'occurrences'}';

  @override
  String? validate() => occurrences == null
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