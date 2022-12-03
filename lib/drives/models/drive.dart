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

  static List<Drive> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Drive.fromJson(json as Map<String, dynamic>)).toList();
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

  static Future<Drive?> driveOfUserAtTime(DateTime start, DateTime end, int userId) async {
    //get all drives of user
    final List<Drive> drives = Drive.fromJsonList(await supabaseClient.from('drives').select().eq('driver_id', userId));
    //check if drive overlaps with start and end
    for (Drive drive in drives) {
      if (drive.startTime.isBefore(end) && drive.endTime.isAfter(start)) {
        return drive;
      }
    }
    return null;
  }
}
