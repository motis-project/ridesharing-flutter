import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';

import '../../util/locale_manager.dart';
import '../../util/own_theme_fields.dart';
import 'week_day.dart';

class RecurrenceOptionsIndicator extends StatelessWidget {
  final RecurrenceRule? before;
  final RecurrenceRule after;
  final DateTime start;
  const RecurrenceOptionsIndicator({super.key, this.before, required this.after, required this.start});

  @override
  Widget build(BuildContext context) {
    final List<DateTime> beforeDays = before?.getAllInstances(start: start.toUtc()) ?? <DateTime>[];
    final List<DateTime> afterDays = after.getAllInstances(start: start.toUtc());
    final List<DateTime> addedDays = afterDays.where((DateTime day) => !beforeDays.contains(day)).toList();
    final List<DateTime> removedDays = beforeDays.where((DateTime day) => !afterDays.contains(day)).toList();
    final List<DateTime> allDays = (beforeDays + afterDays).toSet().toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    if (allDays.isEmpty) {
      return Text(S.of(context).pageRecurringDriveDetailUpcomingDrivesEmpty);
    }

    final List<Widget> days = allDays
        .map<Widget>(
          (DateTime elem) => RecurrenceOptionsIndicatorDay(
            day: elem,
            type: addedDays.contains(elem)
                ? RecurrenceOptionsIndicatorType.added
                : removedDays.contains(elem)
                    ? RecurrenceOptionsIndicatorType.removed
                    : RecurrenceOptionsIndicatorType.constant,
          ),
        )
        .toList();

    final int maxDaysFront =
        max(4, allDays.where((DateTime elem) => elem.difference(start) < const Duration(days: 14)).length);
    final int maxDaysBack = maxDaysFront ~/ 2;

    final List<Widget> daysFront = days.sublist(0, min(maxDaysFront, days.length));

    List<Widget> daysBack = <Widget>[];
    if (maxDaysFront + maxDaysBack < days.length) {
      daysBack = days.sublist(days.length - maxDaysBack);
    }

    return Column(
      children: <Widget>[
        Wrap(spacing: 4, runSpacing: 4, children: daysFront),
        if (daysBack.isNotEmpty) ...<Widget>[
          const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Icon(Icons.more_vert, size: 42)),
          Wrap(spacing: 4, runSpacing: 4, children: daysBack),
        ]
      ],
    );
  }
}

class RecurrenceOptionsIndicatorDay extends StatelessWidget {
  final DateTime day;
  final RecurrenceOptionsIndicatorType type;

  const RecurrenceOptionsIndicatorDay({super.key, required this.day, required this.type});

  Color getBackgroundColor(BuildContext context) => type == RecurrenceOptionsIndicatorType.added
      ? Theme.of(context).own().success
      : type == RecurrenceOptionsIndicatorType.removed
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary;

  Color getForegroundColor(BuildContext context) => type == RecurrenceOptionsIndicatorType.added
      ? Theme.of(context).own().onSuccess
      : type == RecurrenceOptionsIndicatorType.removed
          ? Theme.of(context).colorScheme.onError
          : Theme.of(context).colorScheme.onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.elliptical(10, 10)),
        color: getBackgroundColor(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            day.toWeekDay().getAbbreviation(context),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: getForegroundColor(context)),
          ),
          Text(
            localeManager.formatDate(day),
            style: TextStyle(color: getForegroundColor(context)),
          )
        ],
      ),
    );
  }
}

enum RecurrenceOptionsIndicatorType {
  added,
  removed,
  constant,
}
