import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';

import '../../account/models/profile.dart';
import '../../util/parse_helper.dart';
import '../../util/search/position.dart';
import '../../util/supabase_manager.dart';
import '../../util/trip/trip_like.dart';
import 'drive.dart';

class RecurringDrive extends TripLike {
  DateTime? stoppedAt;
  RecurrenceRule recurrenceRule;

  final int driverId;
  final Profile? driver;

  final TimeOfDay startTime;
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
    this.stoppedAt,
    required this.recurrenceRule,
    required this.driverId,
    this.driver,
    this.drives,
  });

  @override
  factory RecurringDrive.fromJson(Map<String, dynamic> json) {
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
      stoppedAt: json['stopped_at'] == null ? null : DateTime.parse(json['stopped_at'] as String),
      recurrenceRule: RecurrenceRule.fromString((json['recurrence_rule'] as String).split('\n')[1]),
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
        'stopped_at': stoppedAt?.toString(),
        'start_time': startTime.formatted,
        'end_time': endTime.formatted,
        'recurrence_rule': 'DTSTART:${(createdAt ?? DateTime.now()).millisecondsSinceEpoch}\n$recurrenceRule',
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

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

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
}
