import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/search/position.dart';
import '../../util/supabase.dart';
import '../../util/trip/trip.dart';

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
    super.hideInListView,
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
      startPosition: Position.fromDynamicValues(json['start_lat'], json['start_lng']),
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      endPosition: Position.fromDynamicValues(json['end_lat'], json['end_lng']),
      endTime: DateTime.parse(json['end_time']),
      seats: json['seats'],
      cancelled: json['cancelled'],
      hideInListView: json['hide_in_list_view'],
      driverId: json['driver_id'],
      driver: json.containsKey('driver') ? Profile.fromJson(json['driver']) : null,
      rides: json.containsKey('rides') ? Ride.fromJsonList(json['rides']) : null,
    );
  }

  static List<Drive> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Drive.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        'cancelled': cancelled,
        'driver_id': driverId,
      });
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll({
        'driver': driver?.toJsonForApi(),
        'rides': rides?.map((ride) => ride.toJsonForApi()).toList() ?? [],
      });
  }

  List<Ride>? get approvedRides => rides?.where((ride) => ride.status == RideStatus.approved).toList();
  List<Ride>? get pendingRides => rides?.where((ride) => ride.status == RideStatus.pending).toList();

  static Future<List<Drive>> getDrivesOfUser(int userId) async {
    return Drive.fromJsonList(await SupabaseManager.supabaseClient.from('drives').select().eq('driver_id', userId));
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
    //the rides get updated automatically by a supabase function.
  }

  @override
  String toString() {
    return 'Drive{id: $id, from: $start at $startTime, to: $end at $endTime, by: $driverId}';
  }

  @override
  bool equals(Trip other) {
    if (other is! Drive) return false;
    Drive drive = other;
    return super.equals(other) && cancelled == drive.cancelled && driverId == drive.driverId;
  }
}
