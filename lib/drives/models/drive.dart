import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/supabase.dart';

class Drive extends Trip {
  Drive({
    super.id,
    super.createdAt,
    required super.start,
    required super.startTime,
    required super.end,
    required super.endTime,
    required super.seats,
    required super.userId,
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
      userId: json['driver_id'],
    );
  }

  static List<Drive> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Drive.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'start_time': startTime.toString(),
      'end': end,
      'end_time': endTime.toString(),
      'seats': seats,
      'driver_id': userId,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Drive> drives) {
    return drives.map((drive) => drive.toJson()).toList();
  }

  @override
  String toString() {
    return 'Drive{id: $id, from: $start at $startTime, to: $end at $endTime, by: $userId}';
  }

  static Future<List<Drive>> getDrivesOfUser(int userId) async {
    return Drive.fromJsonList(
        await supabaseClient.from('drives').select().eq('driver_id', userId));
  }

  static Future<Drive?> driveOfUserAtTime(
      DateTime start, DateTime end, int userId) async {
    //get all drives of user
    final List<Drive> drives = await Drive.getDrivesOfUser(userId);
    //check if drive overlaps with start and end
    for (Drive drive in drives) {
      if (drive.startTime.isBefore(end) && drive.endTime.isAfter(start)) {
        return drive;
      }
    }
    return null;
  }
}
