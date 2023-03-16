import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';

import '../../account/models/profile.dart';
import '../../managers/supabase_manager.dart';
import '../../search/position.dart';
import '../../trips/models/trip_like.dart';
import '../../util/extensions/time_of_day_extension.dart';
import '../../util/parse_helper.dart';
import '../util/recurrence/recurrence.dart';
import '../util/recurrence/week_day.dart';
import 'drive.dart';

class RecurringDrive extends TripLike {
  DateTime startedAt;
  RecurrenceRule recurrenceRule;

  /// A helper field to get display information out of the recurrence rule
  RecurrenceEndType recurrenceEndType;
  DateTime? stoppedAt;

  final int driverId;
  final Profile? driver;

  @override
  final TimeOfDay startTime;
  @override
  final TimeOfDay destinationTime;

  final List<Drive>? drives;

  RecurringDrive({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required this.startTime,
    required super.destination,
    required super.destinationPosition,
    required this.destinationTime,
    required super.seats,
    required this.startedAt,
    required this.recurrenceRule,
    required this.recurrenceEndType,
    this.stoppedAt,
    required this.driverId,
    this.driver,
    this.drives,
  });

  @override
  factory RecurringDrive.fromJson(Map<String, dynamic> json) {
    final PostgresRecurrenceRule postgresRecurrenceRule = PostgresRecurrenceRule.fromString(
      json['recurrence_rule'] as String,
      untilFieldEnteredAsDate: json['until_field_entered_as_date'] as bool,
    );

    return RecurringDrive(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      start: json['start'] as String,
      startPosition: Position.fromDynamicValues(json['start_lat'], json['start_lng']),
      startTime: TimeOfDay.fromDateTime(DateFormat('hh:mm:ss').parse(json['start_time'] as String).toLocal()),
      destination: json['destination'] as String,
      destinationPosition: Position.fromDynamicValues(json['destination_lat'], json['destination_lng']),
      destinationTime:
          TimeOfDay.fromDateTime(DateFormat('hh:mm:ss').parse(json['destination_time'] as String).toLocal()),
      seats: json['seats'] as int,
      startedAt: postgresRecurrenceRule.dtStart,
      recurrenceRule: postgresRecurrenceRule.rule,
      recurrenceEndType: postgresRecurrenceRule.endType,
      stoppedAt: json['stopped_at'] == null ? null : DateTime.parse(json['stopped_at'] as String).toLocal(),
      driverId: json['driver_id'] as int,
      driver: json.containsKey('driver') ? Profile.fromJson(json['driver'] as Map<String, dynamic>) : null,
      drives: json.containsKey('drives') ? Drive.fromJsonList(parseHelper.parseListOfMaps(json['drives'])) : null,
    );
  }

  @override
  Duration get duration => startTime.getDurationUntil(destinationTime);

  List<WeekDay> get weekDays => recurrenceRule.byWeekDays.map((ByWeekDayEntry day) => day.toWeekDay()).toList();

  /// Returns the [RecurrenceEndChoice] according to the [recurrenceEndType] and the [recurrenceRule]
  ///
  /// If [recurrenceEndType] is [RecurrenceEndType.interval], the [recurrenceRule.until] field is used to calculate the [RecurrenceIntervalType].
  /// For example, if the [recurrenceRule.until] is 1 year and 1 month after [startedAt], the [RecurrenceIntervalType] is [RecurrenceIntervalType.months].
  RecurrenceEndChoice get recurrenceEndChoice {
    switch (recurrenceEndType) {
      case RecurrenceEndType.date:
        return RecurrenceEndChoiceDate(recurrenceRule.until);
      case RecurrenceEndType.interval:
        final DateTime until = recurrenceRule.until!;
        final int yearDiff = until.year - startedAt.year;
        final int monthDiff = until.month - startedAt.month;
        final int dayDiff = until.day - startedAt.day;
        if (yearDiff != 0 && monthDiff == 0 && dayDiff == 0) {
          return RecurrenceEndChoiceInterval(yearDiff, RecurrenceIntervalType.years);
        } else if (monthDiff != 0 && dayDiff == 0) {
          return RecurrenceEndChoiceInterval(yearDiff * 12 + monthDiff, RecurrenceIntervalType.months);
        }

        final int differenceInDays = until.difference(startedAt).inDays;
        if (differenceInDays % 7 == 0) {
          return RecurrenceEndChoiceInterval(differenceInDays ~/ 7, RecurrenceIntervalType.weeks);
        } else {
          return RecurrenceEndChoiceInterval(differenceInDays, RecurrenceIntervalType.days);
        }

      case RecurrenceEndType.occurrence:
        return RecurrenceEndChoiceOccurrence(recurrenceRule.count);
    }
  }

  /// Sets the [recurrenceRule] and the [recurrenceEndType] according to the given [options] and updates the database entry.
  Future<void> setRecurrence(RecurrenceOptions options) async {
    recurrenceEndType = options.endChoice.type;
    recurrenceRule = options.recurrenceRule;

    await supabaseManager.supabaseClient.from('recurring_drives').update(toJson()).eq('id', id);
  }

  static List<RecurringDrive> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => RecurringDrive.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'start_time': startTime.formatted,
        'destination_time': destinationTime.formatted,
        'recurrence_rule': PostgresRecurrenceRule(recurrenceRule, startedAt).toString(),
        'until_field_entered_as_date': recurrenceEndType == RecurrenceEndType.date,
        'stopped_at': stoppedAt?.toUtc().toString(),
        'driver_id': driverId,
      });
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'driver': driver?.toJsonForApi(),
        'drives': drives?.map((Drive drive) => drive.toJsonForApi()).toList() ?? <Map<String, dynamic>>[],
      });
  }

  @override
  String toString() {
    return 'RecurringDrive{id: $id, from: $start at $startTime, to: $destination at $destinationTime, by: $driverId, rule: $recurrenceRule}';
  }

  /// Returns the upcoming drive instances of this recurring drive which should be shown in the ListView.
  ///
  /// Expects [drives] to be not null
  List<Drive> get upcomingDrives => drives!.where((Drive drive) => drive.isUpcomingRecurringDriveInstance).toList();

  /// Sets the [stoppedAt] field to the given [stoppedAt] date and updates the database entry.
  Future<void> stop(DateTime stoppedAt) async {
    this.stoppedAt = stoppedAt;
    await supabaseManager.supabaseClient
        .from('recurring_drives')
        .update(<String, dynamic>{'stopped_at': stoppedAt.toUtc().toString()}).eq('id', id);
  }

  bool get isStopped => stoppedAt != null;
}

class PostgresRecurrenceRule {
  final RecurrenceRule rule;
  final DateTime dtStart;
  final bool untilFieldEnteredAsDate;

  PostgresRecurrenceRule(this.rule, this.dtStart, {this.untilFieldEnteredAsDate = false});

  RecurrenceEndType get endType => rule.until == null
      ? RecurrenceEndType.occurrence
      : untilFieldEnteredAsDate
          ? RecurrenceEndType.date
          : RecurrenceEndType.interval;

  PostgresRecurrenceRule.fromString(String recurrenceRuleString, {this.untilFieldEnteredAsDate = false})
      : rule = RecurrenceRule.fromString(recurrenceRuleString.split('\n')[1]),
        dtStart = DateTime.parse(recurrenceRuleString.split('\n')[0].split(':')[1]);

  @override
  String toString() {
    final DateTime dtStart = this.dtStart.toUtc();
    final String dtStartString = '${DateFormat('yyyyMMdd').format(dtStart)}T${DateFormat('HHmmss').format(dtStart)}Z';
    return 'DTSTART:$dtStartString\n$rule';
  }
}
