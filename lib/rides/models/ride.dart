import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../../drives/models/drive.dart';
import '../../util/search/position.dart';

class Ride extends Trip {
  final double? price;
  RideStatus status;

  final int riderId;
  Profile? rider;

  final int driveId;
  Drive? drive;

  Ride({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required super.startTime,
    required super.end,
    required super.endPosition,
    required super.endTime,
    required super.seats,
    this.price,
    required this.status,
    required this.driveId,
    this.drive,
    required this.riderId,
    this.rider,
  });

  factory Ride.previewFromDrive(
    Drive drive,
    String start,
    Position startPosition,
    DateTime startTime,
    String end,
    Position endPosition,
    DateTime endTime,
    int seats,
    int riderId,
    double price,
  ) {
    return Ride(
      start: start,
      startPosition: startPosition,
      startTime: startTime,
      end: end,
      endPosition: endPosition,
      endTime: endTime,
      seats: seats,
      riderId: riderId,
      status: RideStatus.preview,
      driveId: drive.id!,
      drive: drive,
      price: price,
    );
  }

  @override
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      start: json['start'],
      startPosition: Position(json['start_lat'].toDouble(), json['start_lng'].toDouble()),
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      endPosition: Position(json['end_lat'].toDouble(), json['end_lng'].toDouble()),
      endTime: DateTime.parse(json['end_time']),
      seats: json['seats'],
      price: json['price'],
      status: RideStatus.values[json['status']],
      riderId: json['rider_id'],
      rider: json.containsKey('rider') ? Profile.fromJson(json['rider']) : null,
      driveId: json['drive_id'],
      drive: json.containsKey('drive') ? Drive.fromJson(json['drive']) : null,
    );
  }

  static List<Ride> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Ride.fromJson(json as Map<String, dynamic>)).toList();
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
      'seats': seats,
      'price': price,
      'status': status.index,
      'drive_id': driveId,
      'rider_id': riderId,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Ride> rides) {
    return rides.map((ride) => ride.toJson()).toList();
  }

  static Future<bool> userHasRideAtTimeRange(DateTimeRange range, int userId) async {
    //get all approved and upcoming rides of user
    List<Ride> rides = await getRidesOfUser(userId);
    rides = rides.where((ride) => ride.status.isApproved() && !ride.isFinished).toList();

    //check if ride overlaps with start and end
    for (Ride ride in rides) {
      if (ride.overlapsWithTimeRange(range)) {
        return true;
      }
    }
    return false;
  }

  static Future<List<Ride>> getRidesOfUser(int userId) async {
    return Ride.fromJsonList(await SupabaseManager.supabaseClient.from('rides').select().eq('rider_id', userId));
  }

  Future<Drive> getDrive() async {
    drive ??= Drive.fromJson(await SupabaseManager.supabaseClient.from('drives').select().eq('id', driveId).single());
    return drive!;
  }

  Future<Profile> getDriver() async {
    Drive drive = await getDrive();
    return Profile.fromJson(
        await SupabaseManager.supabaseClient.from('profiles').select().eq('id', drive.driverId).single());
  }

  Future<Profile> getRider() async {
    rider ??=
        Profile.fromJson(await SupabaseManager.supabaseClient.from('profiles').select().eq('id', riderId).single());
    return rider!;
  }

  Future<void> cancel() async {
    status = RideStatus.cancelledByRider;
    await SupabaseManager.supabaseClient.from('rides').update({'status': status.index}).eq('id', id);
  }

  @override
  String toString() {
    return 'Ride{id: $id, in: $driveId, from: $start at $startTime, to: $end at $endTime, by: $riderId}';
  }
}

enum RideStatus { preview, pending, approved, rejected, cancelledByDriver, cancelledByRider }

extension RideStatusExtension on RideStatus {
  bool isCancelled() {
    return this == RideStatus.cancelledByDriver || this == RideStatus.cancelledByRider;
  }

  bool isApproved() {
    return this == RideStatus.approved;
  }
}
