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
  bool stopped;
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
    this.stopped = false,
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
      stopped: json['stopped'] as bool,
      recurrenceRule: RecurrenceRule.fromString((json['recurring_rule'] as String).split('\n')[1]),
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
        'stopped': stopped,
        'start_time': startTime.toString(),
        'end_time': endTime.toString(),
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

  Future<void> stop() async {
    stopped = true;
    await supabaseManager.supabaseClient
        .from('recurring_drives')
        .update(<String, dynamic>{'stopped': true}).eq('id', id);
  }
}
