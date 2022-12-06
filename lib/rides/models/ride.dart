import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/supabase.dart';

import '../../drives/models/drive.dart';

class Ride extends Trip {
  final double? price;
  final bool approved;

  final int riderId;
  final int driveId;

  Ride({
    super.id,
    super.createdAt,
    required super.start,
    required super.startTime,
    required super.end,
    required super.endTime,
    required super.seats,
    required this.riderId,
    this.price,
    required this.approved,
    required this.driveId,
  });

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
      approved: json['approved'],
      driveId: json['drive_id'],
      riderId: json['rider_id'],
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
      'approved': approved,
      'drive_id': driveId,
      'rider_id': riderId,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Ride> rides) {
    return rides.map((ride) => ride.toJson()).toList();
  }

  static Future<Ride?> rideOfUserAtTime(DateTime start, DateTime end, int userId) async {
    //get all rides of user
    final List<Ride> rides = await getRidesOfUser(userId);
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
    return Drive.fromJson(await supabaseClient.from('drives').select().eq('id', driveId).single());
  }

  Future<Profile> getDriver() async {
    Drive drive = await getDrive();
    return Profile.fromJson(await supabaseClient.from('profiles').select().eq('id', drive.driverId).single());
  }

  Future<Profile> getRider() async {
    return Profile.fromJson(await supabaseClient.from('profiles').select().eq('id', riderId).single());
  }

  @override
  String toString() {
    return 'Ride{id: $id, in: $driveId, from: $start at $startTime, to: $end at $endTime, by: $riderId}';
  }
}
