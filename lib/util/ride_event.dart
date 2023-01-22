import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'model.dart';
import 'supabase.dart';

class RideEvent extends Model {
  RideEventCategory category;
  bool read;
  int rideId;
  int senderId;

  RideEvent({
    super.id,
    super.createdAt,
    required this.category,
    this.read = false,
    required this.rideId,
    required this.senderId,
  });

  factory RideEvent.fromJson(Map<String, dynamic> json) {
    return RideEvent(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      rideId: json['ride_id'],
      category: RideEventCategory.values.elementAt(json['category'] as int),
      read: json['read'],
      senderId: json['sender_id'],
    );
  }

  static List<RideEvent> fromJsonList(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((Map<String, dynamic> json) => RideEvent.fromJson(json)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ride_id': read,
      'category': category,
      'read': read,
    };
  }

  Future<void> markAsRead() async {
    read = true;
    //custom rpc call to mark rideEvent as read, so the user does not need the write permission on the ride_events table
    await SupabaseManager.supabaseClient.rpc('mark_ride_event_as_read', params: <String, dynamic>{'ride_event_id': id});
  }

  Future<bool> isForCurrentUser() async {
    final int profileId = SupabaseManager.getCurrentProfile()!.id!;
    if (category == RideEventCategory.approved ||
        category == RideEventCategory.cancelledByDriver ||
        category == RideEventCategory.rejected) {
      final int riderId =
          await SupabaseManager.supabaseClient.from('rides').select('rider_id').eq('id', rideId).single();
      return profileId != riderId;
    } else {
      final int driveId =
          await SupabaseManager.supabaseClient.from('rides').select('drive_id').eq('id', rideId).single();
      final int driverId =
          await SupabaseManager.supabaseClient.from('drives').select('driver_id').eq('id', driveId).single();
      return driverId != profileId;
    }
  }

  @override
  String toString() {
    return 'RideEvent{id: $id, createdAt: $createdAt, read: $read, category: $category, ride_id: $rideId}';
  }
}

// Stored in the database as an integer
// The order of the enum values is important
enum RideEventCategory { pending, approved, rejected, cancelledByDriver, cancelledByRider, withdrawnByRider }

extension CategoryExtension on RideEventCategory {
  String getDescription(BuildContext context) {
    switch (this) {
      case RideEventCategory.pending:
        return S.of(context).modelProfileFeatureNoSmoking;
      case RideEventCategory.approved:
        return S.of(context).modelProfileFeatureNoSmoking;
      case RideEventCategory.rejected:
        return S.of(context).modelProfileFeatureNoSmoking;
      case RideEventCategory.cancelledByDriver:
        return S.of(context).modelProfileFeatureNoSmoking;
      case RideEventCategory.cancelledByRider:
        return S.of(context).modelProfileFeatureNoSmoking;
      case RideEventCategory.withdrawnByRider:
        return S.of(context).modelProfileFeatureNoSmoking;
    }
  }
}
