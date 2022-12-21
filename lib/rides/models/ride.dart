import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/supabase.dart';

import '../../drives/models/drive.dart';

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
    required super.startTime,
    required super.end,
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
    String end,
    DateTime startTime,
    DateTime endTime,
    int seats,
    int riderId,
    double price,
  ) {
    return Ride(
      start: start,
      end: end,
      startTime: startTime,
      endTime: endTime,
      seats: seats,
      riderId: riderId,
      status: RideStatus.preview,
      driveId: drive.driverId,
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
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
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
      'start_time': startTime.toString(),
      'end': end,
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

  static Future<Ride?> rideOfUserAtTime(DateTime start, DateTime end, int userId) async {
    //get all rides of user
    final List<Ride> rides = Ride.fromJsonList(await supabaseClient.from('rides').select().eq('rider_id', userId));
    //check if ride overlaps with start and end
    for (Ride ride in rides) {
      if (ride.startTime.isBefore(end) && ride.endTime.isAfter(start)) {
        return ride;
      }
    }
    return null;
  }

  static Future<List<Ride>> getRidesOfUser(int userId) async {
    return Ride.fromJsonList(await supabaseClient.from('rides').select().eq('rider_id', userId));
  }

  Future<Drive> getDrive() async {
    drive ??= Drive.fromJson(await supabaseClient.from('drives').select().eq('id', driveId).single());
    return drive!;
  }

  Future<Profile> getDriver() async {
    Drive drive = await getDrive();
    return Profile.fromJson(await supabaseClient.from('profiles').select().eq('id', drive.driverId).single());
  }

  Future<Profile> getRider() async {
    rider ??= Profile.fromJson(await supabaseClient.from('profiles').select().eq('id', riderId).single());
    return rider!;
  }

  Future<void> cancel() async {
    status = RideStatus.cancelledByRider;
    await supabaseClient.from('rides').update({'status': status.index}).eq('id', id);
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
}
