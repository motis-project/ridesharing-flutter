import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../chat/models/chat.dart';
import '../../managers/supabase_manager.dart';
import '../../search/position.dart';
import '../../util/parse_helper.dart';
import 'drive.dart';
import 'trip.dart';

class Ride extends Trip {
  final double? price;
  RideStatus status;

  final int riderId;
  Profile? rider;

  final int driveId;
  Drive? drive;

  // Nullable for preview rides
  final int? chatId;
  Chat? chat;

  Ride({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required super.startDateTime,
    required super.end,
    required super.endPosition,
    required super.endDateTime,
    required super.seats,
    this.price,
    required this.status,
    super.hideInListView,
    required this.driveId,
    this.drive,
    required this.riderId,
    this.rider,
    this.chatId,
    this.chat,
  });

  factory Ride.previewFromDrive(
    Drive drive, {
    required String start,
    required Position startPosition,
    required String end,
    required Position endPosition,
    required int seats,
    required int riderId,
  }) {
    return Ride(
      start: start,
      startPosition: startPosition,
      startDateTime: drive.startDateTime,
      end: end,
      endPosition: endPosition,
      endDateTime: drive.endDateTime,
      seats: seats,
      riderId: riderId,
      status: RideStatus.preview,
      driveId: drive.id!,
      drive: drive,
      price: double.parse(drive.startPosition.distanceTo(drive.endPosition).toStringAsFixed(2)),
    );
  }

  @override
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      start: json['start'] as String,
      startPosition: Position.fromDynamicValues(json['start_lat'], json['start_lng']),
      startDateTime: DateTime.parse(json['start_time'] as String),
      end: json['end'] as String,
      endPosition: Position.fromDynamicValues(json['end_lat'], json['end_lng']),
      endDateTime: DateTime.parse(json['end_time'] as String),
      seats: json['seats'] as int,
      price: parseHelper.parseDouble(json['price']),
      status: RideStatus.values[json['status'] as int],
      hideInListView: json['hide_in_list_view'] as bool,
      riderId: json['rider_id'] as int,
      rider: json.containsKey('rider') ? Profile.fromJson(json['rider'] as Map<String, dynamic>) : null,
      driveId: json['drive_id'] as int,
      drive: json.containsKey('drive') ? Drive.fromJson(json['drive'] as Map<String, dynamic>) : null,
      chatId: json['chat_id'] as int?,
      chat: json.containsKey('chat') ? Chat.fromJson(json['chat'] as Map<String, dynamic>) : null,
    );
  }

  static List<Ride> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => Ride.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'price': price,
        'status': status.index,
        'drive_id': driveId,
        'rider_id': riderId,
        'chat_id': chatId,
      });
  }

  @override
  Map<String, dynamic> toJsonForApi() {
    return super.toJsonForApi()
      ..addAll(<String, dynamic>{
        ...drive == null ? <String, dynamic>{} : <String, dynamic>{'drive': drive?.toJsonForApi()},
        ...rider == null ? <String, dynamic>{} : <String, dynamic>{'rider': rider?.toJsonForApi()},
        ...chat == null ? <String, dynamic>{} : <String, dynamic>{'chat': chat?.toJsonForApi()},
      });
  }

  /// Returns true if the user has another approved ride that is not finished in the given [range]
  static Future<bool> userHasRideAtTimeRange(DateTimeRange range, int userId) async {
    final List<Map<String, dynamic>> jsonList =
        await supabaseManager.supabaseClient.from('rides').select<List<Map<String, dynamic>>>().eq('rider_id', userId);
    final List<Ride> rides =
        Ride.fromJsonList(jsonList).where((Ride ride) => ride.status.isApproved() && !ride.isFinished).toList();

    //check if ride overlaps with start and end
    for (final Ride ride in rides) {
      if (ride.overlapsWithTimeRange(range)) {
        return true;
      }
    }
    return false;
  }

  /// Returns whether this trip should be shown in the list view given if the list view is for past or future trips:
  ///
  /// - [past] rides should not show pending or withdrawn rides
  @override
  bool shouldShowInListView({required bool past}) {
    return super.shouldShowInListView(past: past) &&
        (!past || (status != RideStatus.pending && status != RideStatus.withdrawnByRider));
  }

  @override
  bool equals(Trip other) {
    if (other is! Ride) return false;
    final Ride ride = other;
    return super.equals(other) &&
        status == ride.status &&
        driveId == ride.driveId &&
        price == ride.price &&
        rider == ride.rider &&
        price == ride.price &&
        riderId == ride.riderId &&
        chatId == ride.chatId;
  }

  /// Cancels the ride and updates the database
  Future<void> cancel() async {
    status = RideStatus.cancelledByRider;
    await supabaseManager.supabaseClient.from('rides').update(<String, dynamic>{'status': status.index}).eq('id', id);
  }

  /// Withdraws the ride and updates the database
  Future<void> withdraw() async {
    status = RideStatus.withdrawnByRider;
    await supabaseManager.supabaseClient
        .from('rides')
        .update(<String, dynamic>{'status': status.index, 'hide_in_list_view': true}).eq('id', id);
  }

  @override
  String toString() {
    return 'Ride{id: $id, in: $driveId, from: $start at $startDateTime, to: $end at $endDateTime, by: $riderId}';
  }

  Ride copyWith({int? id, RideStatus? status}) {
    return Ride(
      id: id ?? this.id,
      createdAt: createdAt,
      start: start,
      startPosition: startPosition,
      startDateTime: startDateTime,
      end: end,
      endPosition: endPosition,
      endDateTime: endDateTime,
      seats: seats,
      price: price,
      status: status ?? this.status,
      hideInListView: hideInListView,
      riderId: riderId,
      rider: rider,
      driveId: driveId,
      drive: drive,
      chatId: chatId,
      chat: chat,
    );
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

  /// Whether the rider can see and be seen in the riders list
  ///
  /// - [approved] and [cancelledByDriver] are real riders
  bool isRealRider() {
    return this == RideStatus.approved || this == RideStatus.cancelledByDriver;
  }

  /// Whether the ride's chat is active
  ///
  /// - [approved], [cancelledByDriver] and [cancelledByRider] are active
  bool activeChat() {
    return this == RideStatus.approved || this == RideStatus.cancelledByDriver || this == RideStatus.cancelledByRider;
  }
}
