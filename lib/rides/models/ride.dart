import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../drives/models/drive.dart';
import '../../util/parse_helper.dart';
import '../../util/search/position.dart';
import '../../util/supabase.dart';
import '../../util/trip/trip.dart';

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
    super.hideInListView,
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
      startPosition: Position.fromDynamicValues(json['start_lat'], json['start_lng']),
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      endPosition: Position(json['end_lat'], json['end_lng']),
      endTime: DateTime.parse(json['end_time']),
      seats: json['seats'],
      price: parseHelper.parseDouble(json['end_lng']),
      status: RideStatus.values[json['status']],
      hideInListView: json['hide_in_list_view'],
      riderId: json['rider_id'],
      rider: json.containsKey('rider') ? Profile.fromJson(json['rider']) : null,
      driveId: json['drive_id'],
      drive: json.containsKey('drive') ? Drive.fromJson(json['drive']) : null,
    );
  }

  static List<Ride> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Ride.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        'price': price,
        'status': status.index,
        'drive_id': driveId,
        'rider_id': riderId,
      });
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll({
        'drive': drive?.toJsonForApi(),
        'rider': rider?.toJsonForApi(),
      });
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

  @override
  bool equals(Trip other) {
    if (other is! Ride) return false;
    Ride ride = other;
    return super.equals(other) &&
        status == ride.status &&
        driveId == ride.driveId &&
        price == ride.price &&
        rider == ride.rider &&
        price == ride.price &&
        riderId == ride.riderId;
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

  Future<void> withdraw() async {
    status = RideStatus.withdrawnByRider;
    await SupabaseManager.supabaseClient
        .from('rides')
        .update({'status': status.index, 'hide_in_list_view': true}).eq('id', id);
  }

  @override
  String toString() {
    return 'Ride{id: $id, in: $driveId, from: $start at $startTime, to: $end at $endTime, by: $riderId}';
  }
}

enum RideStatus { preview, pending, approved, rejected, cancelledByDriver, cancelledByRider, withdrawnByRider }

extension RideStatusExtension on RideStatus {
  bool isCancelled() {
    return this == RideStatus.cancelledByDriver || this == RideStatus.cancelledByRider;
  }

  bool isApproved() {
    return this == RideStatus.approved;
  }
}
