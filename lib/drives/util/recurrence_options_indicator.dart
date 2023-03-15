import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rrule/rrule.dart';

import '../../util/expandable_section.dart';
import '../../util/locale_manager.dart';
import '../../util/own_theme_fields.dart';
import 'week_day.dart';

class RecurrenceOptionsIndicator extends StatefulWidget {
  final RecurrenceRule? previousRule;
  final RecurrenceRule newRule;
  final DateTime startedAt;

  final bool showPreview;
  final void Function(bool expanded)? expansionCallback;

  const RecurrenceOptionsIndicator({
    super.key,
    this.previousRule,
    required this.newRule,
    required this.startedAt,
    required this.showPreview,
    this.expansionCallback,
  });

  @override
  State<RecurrenceOptionsIndicator> createState() => _RecurrenceOptionsIndicatorState();
}

class _RecurrenceOptionsIndicatorState extends State<RecurrenceOptionsIndicator> {
  @override
  Widget build(BuildContext context) {
    final DateTime after = widget.startedAt.isAfter(DateTime.now()) ? widget.startedAt : DateTime.now();

    final Set<DateTime> previousDays =
        widget.previousRule?.getAllInstances(start: widget.startedAt.toUtc(), after: after.toUtc()).toSet() ??
            <DateTime>{};
    final Set<DateTime> newDays =
        widget.newRule.getAllInstances(start: widget.startedAt.toUtc(), after: after.toUtc()).toSet();
    final Set<DateTime> addedDays = newDays.difference(previousDays);
    final Set<DateTime> removedDays = previousDays.difference(newDays);
    final List<DateTime> allDays = (previousDays.union(newDays)).toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    final List<Widget> dayIndicators = allDays
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

    final int maxDaysBeforeGapCount = allDays
        .where((DateTime elem) => elem.difference(widget.startedAt) < const Duration(days: 14))
        .length
        .clamp(4, 8);
    final int maxDaysAfterGapCount = maxDaysBeforeGapCount ~/ 2;

    List<Widget> dayIndicatorsBeforeGap = dayIndicators;
    List<Widget> dayIndicatorsAfterGap = <Widget>[];
    if (maxDaysBeforeGapCount + maxDaysAfterGapCount < dayIndicators.length) {
      dayIndicatorsBeforeGap = dayIndicators.take(maxDaysBeforeGapCount).toList();
      dayIndicatorsAfterGap = dayIndicators.sublist(dayIndicators.length - maxDaysAfterGapCount);
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
                Wrap(spacing: 4, runSpacing: 4, children: dayIndicatorsBeforeGap),
                if (dayIndicatorsAfterGap.isNotEmpty) ...<Widget>[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Icon(Icons.more_vert, size: 42)),
                  Wrap(spacing: 4, runSpacing: 4, children: dayIndicatorsAfterGap),
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
