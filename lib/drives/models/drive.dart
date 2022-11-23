import 'package:flutter_app/util/supabase.dart';

import '../../util/model.dart';

class Drive extends Model {
  final String start;
  final DateTime startTime;
  final String end;
  final DateTime endTime;

  final int seats;
  final int driverId;

  Drive({
    super.id,
    super.createdAt,
    required this.start,
    required this.startTime,
    required this.end,
    required this.endTime,
    required this.seats,
    required this.driverId,
  });

  @override
  factory Drive.fromJson(Map<String, dynamic> json) {
    return Drive(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      start: json['start'],
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      endTime: DateTime.parse(json['end_time']),
      seats: json['seats'],
      driverId: json['driver_id'],
    );
  }

  static List<Drive> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => Drive.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'start_time': startTime.toString(),
      'end': end,
      'end_time': endTime.toString(),
      'seats': seats,
      'driver_id': driverId,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Drive> drives) {
    return drives.map((drive) => drive.toJson()).toList();
  }

  @override
  String toString() {
    return 'Drive{id: $id, from: $start at $startTime, to: $end at $endTime, by: $driverId}';
  }

  static Future<Drive?> userAlreadyHasDrive(
      DateTime start, DateTime end, int userId) async {
    final List<dynamic> drivesList =
        await supabaseClient.from('drives').select().eq('driver_id', userId);
    final List<Drive> drives = drivesList
        .map((drive) => Drive.fromJson(drive as Map<String, dynamic>))
        .toList();
    for (Drive drive in drives) {
      if (drive.startTime.isBefore(start) && drive.endTime.isAfter(start)) {
        return drive;
      }
      if (drive.startTime.isBefore(end) && drive.endTime.isAfter(end)) {
        return drive;
      }
      if (drive.startTime.isAfter(start) && drive.endTime.isBefore(end)) {
        return drive;
      }
    }
    return null;
  }
}
