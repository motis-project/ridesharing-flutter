import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';

import '../../util/expandable_section.dart';
import '../../util/locale_manager.dart';
import '../../util/own_theme_fields.dart';
import 'week_day.dart';

class RecurrenceOptionsIndicator extends StatefulWidget {
  final RecurrenceRule? before;
  final RecurrenceRule after;
  final DateTime start;

  final bool showPreview;
  final void Function(bool expanded)? expansionCallback;

  const RecurrenceOptionsIndicator({
    super.key,
    this.before,
    required this.after,
    required this.start,
    required this.showPreview,
    this.expansionCallback,
  });

  @override
  State<RecurrenceOptionsIndicator> createState() => _RecurrenceOptionsIndicatorState();
}

class _RecurrenceOptionsIndicatorState extends State<RecurrenceOptionsIndicator> {
  @override
  Widget build(BuildContext context) {
    final List<DateTime> beforeDays = widget.before?.getAllInstances(start: widget.start.toUtc()) ?? <DateTime>[];
    final List<DateTime> afterDays = widget.after.getAllInstances(start: widget.start.toUtc());
    final List<DateTime> addedDays = afterDays.where((DateTime day) => !beforeDays.contains(day)).toList();
    final List<DateTime> removedDays = beforeDays.where((DateTime day) => !afterDays.contains(day)).toList();
    final List<DateTime> allDays = (beforeDays + afterDays).toSet().toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    if (allDays.isEmpty) {}

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
        max(4, allDays.where((DateTime elem) => elem.difference(widget.start) < const Duration(days: 14)).length);
    final int maxDaysBack = maxDaysFront ~/ 2;

    final List<Widget> daysFront = days.sublist(0, min(maxDaysFront, days.length));

    List<Widget> daysBack = <Widget>[];
    if (maxDaysFront + maxDaysBack < days.length) {
      daysBack = days.sublist(days.length - maxDaysBack);
    }

    return ExpandableSection(
      title: S.of(context).preview,
      expansionCallback: widget.expansionCallback,
      isExpanded: widget.showPreview,
      isExpandable: allDays.isNotEmpty,
      child: allDays.isEmpty
          ? Text(S.of(context).pageRecurringDriveDetailUpcomingDrivesEmpty)
          : Column(
              children: <Widget>[
                Wrap(spacing: 4, runSpacing: 4, children: daysFront),
                if (daysBack.isNotEmpty) ...<Widget>[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Icon(Icons.more_vert, size: 42)),
                  Wrap(spacing: 4, runSpacing: 4, children: daysBack),
                ]
              ],
            ),
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
    final TextStyle dateStyle = TextStyle(color: getForegroundColor(context));
    //Getting the width of the "biggest possible" date so that every date has the same width
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: localeManager.formatDate(DateTime(2022, 12, 22)), style: dateStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return Container(
      width: textPainter.size.width + 10,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.elliptical(10, 10)),
        color: getBackgroundColor(context),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              day.toWeekDay().getAbbreviation(context),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: getForegroundColor(context)),
            ),
            Text(
              localeManager.formatDate(day),
              style: dateStyle,
            )
          ],
        ),
      ),
    );
  }
}

enum RecurrenceOptionsIndicatorType {
  added,
  removed,
  constant,
}
