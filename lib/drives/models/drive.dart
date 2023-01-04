import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../../util/search/position.dart';

class Drive extends Trip {
  bool cancelled;

  final int driverId;
  final Profile? driver;

  final List<Ride>? rides;

  Drive({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required super.startTime,
    required super.end,
    required super.endPosition,
    required super.endTime,
    required super.seats,
    this.cancelled = false,
    required this.driverId,
    this.driver,
    this.rides,
  });

  @override
  factory Drive.fromJson(Map<String, dynamic> json) {
    return Drive(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      start: json['start'],
      startPosition: Position(json['start_lat'].toDouble(), json['start_lng'].toDouble()),
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      endPosition: Position(json['end_lat'].toDouble(), json['end_lng'].toDouble()),
      endTime: DateTime.parse(json['end_time']),
      seats: json['seats'],
      cancelled: json['cancelled'],
      driverId: json['driver_id'],
      driver: json.containsKey('driver') ? Profile.fromJson(json['driver']) : null,
      rides: json.containsKey('rides') ? Ride.fromJsonList(json['rides']) : null,
    );
  }

  static List<Drive> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Drive.fromJson(json as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'start_lat': startPosition.lat,
      'start_lng': startPosition.lng,
      'start_time': startTime.toString(),
      'end': end,
      'end_lat': endPosition.lat,
      'end_lng': endPosition.lng,
      'end_time': endTime.toString(),
      'cancelled': cancelled,
      'seats': seats,
      'driver_id': driverId,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Drive> drives) {
    return drives.map((drive) => drive.toJson()).toList();
  }

  List<Ride>? get approvedRides => rides?.where((ride) => ride.status == RideStatus.approved).toList();
  List<Ride>? get pendingRides => rides?.where((ride) => ride.status == RideStatus.pending).toList();

  static Future<List<Drive>> getDrivesOfUser(int userId) async {
    return Drive.fromJsonList(
      await SupabaseManager.supabaseClient.from('drives').select().eq('driver_id', '1'),
    );
  }

  static Future<bool> userHasDriveAtTimeRange(DateTimeRange range, int userId) async {
    //get all upcoming drives of user
    List<Drive> drives = await Drive.getDrivesOfUser(userId);
    drives = drives.where((drive) => !drive.cancelled && !drive.isFinished).toList();

    //check if drive overlaps with start and end
    for (Drive drive in drives) {
      if (drive.overlapsWithTimeRange(range)) {
        return true;
      }
    }
    return false;
  }

  int? getMaxUsedSeats() {
    if (rides == null) return null;

    Set<DateTime> times = approvedRides!.map((ride) => [ride.startTime, ride.endTime]).expand((x) => x).toSet();

    int maxUsedSeats = 0;
    for (DateTime time in times) {
      int usedSeats = 0;
      for (Ride ride in approvedRides!) {
        final startTimeBeforeOrEqual = ride.startTime.isBefore(time) || ride.startTime.isAtSameMomentAs(time);
        final endTimeAfter = ride.endTime.isAfter(time);
        if (startTimeBeforeOrEqual && endTimeAfter) {
          usedSeats += ride.seats;
        }
      }

      if (usedSeats > maxUsedSeats) {
        maxUsedSeats = usedSeats;
      }
    }
    return maxUsedSeats;
  }

  bool isRidePossible(Ride ride) {
    List<Ride> consideredRides = approvedRides! + [ride];
    Set<DateTime> times = consideredRides
        .map((consideredRide) => [consideredRide.startTime, consideredRide.endTime])
        .expand((x) => x)
        .toSet();
    for (DateTime time in times) {
      int usedSeats = 0;
      for (Ride consideredRide in consideredRides) {
        final startTimeBeforeOrEqual =
            consideredRide.startTime.isBefore(time) || consideredRide.startTime.isAtSameMomentAs(time);
        final endTimeAfter = consideredRide.endTime.isAfter(time);
        if (startTimeBeforeOrEqual && endTimeAfter) {
          usedSeats += consideredRide.seats;
        }
      }

      if (usedSeats > seats) {
        return false;
      }
    }
    return true;
  }

  Future<void> cancel() async {
    cancelled = true;
    await SupabaseManager.supabaseClient.from('drives').update({'cancelled': true}).eq('id', id);
    //the rides get SupabaseManager.updated automatically by a supabase function.
  }

  @override
  String toString() {
    return 'Drive{id: $id, from: $start at $startTime, to: $end at $endTime, by: $driverId}';
  }
}
