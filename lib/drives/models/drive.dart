import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/parse_helper.dart';
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
      rides: json.containsKey('rides') ? Ride.fromJsonList(parseHelper.parseListOfMaps(json['rides'])) : null,
    );
  }

  static List<Drive> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Drive.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'cancelled': cancelled,
        'driver_id': driverId,
      });
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        'driver': driver?.toJsonForApi(),
        'rides': rides?.map((Ride ride) => ride.toJsonForApi()).toList() ?? <Map<String, dynamic>>[],
      });
  }

  List<Ride>? get approvedRides => rides?.where((Ride ride) => ride.status == RideStatus.approved).toList();
  List<Ride>? get pendingRides => rides?.where((Ride ride) => ride.status == RideStatus.pending).toList();
  List<Ride>? get ridesWithChat => rides?.where((Ride ride) => ride.status.activeChat()).toList();

  static Future<bool> userHasDriveAtTimeRange(DateTimeRange range, int userId) async {
    final List<Map<String, dynamic>> data = parseHelper.parseListOfMaps(
      await SupabaseManager.supabaseClient.from('drives').select().eq('driver_id', userId),
    );
    List<Drive> drives = Drive.fromJsonList(data);
    drives = drives.where((Drive drive) => !drive.cancelled && !drive.isFinished).toList();

    //check if drive overlaps with start and end
    for (final Drive drive in drives) {
      if (drive.overlapsWithTimeRange(range)) {
        return true;
      }
    }
    return false;
  }

  int? getMaxUsedSeats() {
    if (rides == null) return null;

    final Set<DateTime> times = approvedRides!
        .map((Ride ride) => <DateTime>[ride.startTime, ride.endTime])
        .expand((List<DateTime> x) => x)
        .toSet();

    int maxUsedSeats = 0;
    for (final DateTime time in times) {
      int usedSeats = 0;
      for (final Ride ride in approvedRides!) {
        final bool startTimeBeforeOrEqual = ride.startTime.isBefore(time) || ride.startTime.isAtSameMomentAs(time);
        final bool endTimeAfter = ride.endTime.isAfter(time);
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
    final List<Ride> consideredRides = approvedRides!..add(ride);
    final Set<DateTime> times = consideredRides
        .map((Ride consideredRide) => <DateTime>[consideredRide.startTime, consideredRide.endTime])
        .expand((List<DateTime> x) => x)
        .toSet();
    for (final DateTime time in times) {
      int usedSeats = 0;
      for (final Ride consideredRide in consideredRides) {
        final bool startTimeBeforeOrEqual =
            consideredRide.startTime.isBefore(time) || consideredRide.startTime.isAtSameMomentAs(time);
        final bool endTimeAfter = consideredRide.endTime.isAfter(time);
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
    await SupabaseManager.supabaseClient.from('drives').update(<String, dynamic>{'cancelled': true}).eq('id', id);
    //the rides get updated automatically by a supabase function.
  }

  int getUnreadMessagesCount() {
    return ridesWithChat!.where((Ride ride) => ride.chat!.getUnreadMessagesCount() > 0).length;
  }

  @override
  String toString() {
    return 'Drive{id: $id, from: $start at $startTime, to: $end at $endTime, by: $driverId}';
  }

  @override
  bool equals(Trip other) {
    if (other is! Drive) return false;
    final Drive drive = other;
    return super.equals(other) && cancelled == drive.cancelled && driverId == drive.driverId;
  }
}
