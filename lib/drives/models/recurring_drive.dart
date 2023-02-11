import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';

import '../../account/models/profile.dart';
import '../../util/parse_helper.dart';
import '../../util/search/position.dart';
import '../../util/supabase_manager.dart';
import '../../util/trip/trip_like.dart';
import 'drive.dart';

class RecurringDrive extends TripLike {
  DateTime startedAt;
  RecurrenceRule recurrenceRule;
  DateTime? stoppedAt;

  final int driverId;
  final Profile? driver;

  @override
  final TimeOfDay startTime;
  @override
  final TimeOfDay endTime;

  final List<Drive>? drives;

  RecurringDrive({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required this.startTime,
    required super.end,
    required super.endPosition,
    required this.endTime,
    required super.seats,
    required this.startedAt,
    required this.recurrenceRule,
    this.stoppedAt,
    required this.driverId,
    this.driver,
    this.drives,
  });

  @override
  factory RecurringDrive.fromJson(Map<String, dynamic> json) {
    final PostgresRecurrenceRule postgresRecurrenceRule =
        PostgresRecurrenceRule.fromString(json['recurrence_rule'] as String);

    return RecurringDrive(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      start: json['start'] as String,
      startPosition: Position.fromDynamicValues(json['start_lat'], json['start_lng']),
      startTime: TimeOfDay.fromDateTime(DateFormat('hh:mm:ss').parse(json['start_time'] as String)),
      end: json['end'] as String,
      endPosition: Position.fromDynamicValues(json['end_lat'], json['end_lng']),
      endTime: TimeOfDay.fromDateTime(DateFormat('hh:mm:ss').parse(json['end_time'] as String)),
      seats: json['seats'] as int,
      startedAt: postgresRecurrenceRule.dtStart,
      recurrenceRule: postgresRecurrenceRule.recurrenceRule,
      stoppedAt: json['stopped_at'] == null ? null : DateTime.parse(json['stopped_at'] as String),
      driverId: json['driver_id'] as int,
      driver: json.containsKey('driver') ? Profile.fromJson(json['driver'] as Map<String, dynamic>) : null,
      drives: json.containsKey('drives') ? Drive.fromJsonList(parseHelper.parseListOfMaps(json['drives'])) : null,
    );
  }

  static List<RecurringDrive> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => RecurringDrive.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'start_time': startTime.formatted,
        'end_time': endTime.formatted,
        'recurrence_rule': PostgresRecurrenceRule(recurrenceRule, startedAt).toString(),
        'stopped_at': stoppedAt?.toString(),
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
    return 'RecurringDrive{id: $id, from: $start at $startTime, to: $end at $endTime, by: $driverId, rule: $recurrenceRule}';
  }

  List<Drive> get upcomingDrives =>
      drives!.where((Drive drive) => drive.startDateTime.isAfter(DateTime.now()) && !drive.hideInListView).toList();

  Future<void> stop(DateTime stoppedAt) async {
    this.stoppedAt = stoppedAt;
    await supabaseManager.supabaseClient
        .from('recurring_drives')
        .update(<String, dynamic>{'stopped_at': stoppedAt.toString()}).eq('id', id);
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }
}

class PostgresRecurrenceRule {
  final RecurrenceRule recurrenceRule;
  final DateTime dtStart;

  PostgresRecurrenceRule(this.recurrenceRule, this.dtStart);

  PostgresRecurrenceRule.fromString(String recurrenceRuleString)
      : recurrenceRule = RecurrenceRule.fromString(recurrenceRuleString.split('\n')[1]),
        dtStart = DateTime.parse(recurrenceRuleString.split('\n')[0].split(':')[1]);

  @override
  String toString() {
    final String dtStartString = '${DateFormat('yyyyMMdd').format(dtStart)}T${DateFormat('HHmmss').format(dtStart)}Z';
    return 'DTSTART:$dtStartString\n$recurrenceRule';
  }
}
