import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../rides/models/ride.dart';
import 'model.dart';
import 'supabase.dart';

class RideEvent extends Model {
  RideEventCategory category;
  bool read;
  final int rideId;
  final Ride? ride;

  RideEvent({
    super.id,
    super.createdAt,
    required this.category,
    this.read = false,
    required this.rideId,
    this.ride,
  });

  factory RideEvent.fromJson(Map<String, dynamic> json) {
    return RideEvent(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      rideId: json['ride_id'],
      ride: json.containsKey('ride') ? Ride.fromJson(json['ride']) : null,
      category: RideEventCategory.values.elementAt(json['category'] as int),
      read: json['read'],
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

  bool isForCurrentUser() {
    final int profileId = SupabaseManager.getCurrentProfile()!.id!;
    if (category == RideEventCategory.approved ||
        category == RideEventCategory.cancelledByDriver ||
        category == RideEventCategory.rejected) {
      return ride!.rider!.id == profileId;
    } else {
      return ride!.drive!.driver!.id == profileId;
    }
  }

  String getTitle(BuildContext context) {
    switch (category) {
      case RideEventCategory.pending:
        return S.of(context).rideEventPendingTitle;
      case RideEventCategory.approved:
        return S.of(context).rideEventApprovedTitle;
      case RideEventCategory.rejected:
        return S.of(context).rideEventRejectedTitle;
      case RideEventCategory.cancelledByDriver:
        return S.of(context).rideEventCancelledByDriverTitle;
      case RideEventCategory.cancelledByRider:
        return S.of(context).rideEventCancelledByRiderTitle;
      case RideEventCategory.withdrawn:
        return S.of(context).rideEventWithdrawnTitle;
    }
  }

  String getMessage(BuildContext context) {
    switch (category) {
      case RideEventCategory.pending:
        return S.of(context).rideEventPendingMessage(ride!.rider!.username);
      case RideEventCategory.approved:
        return S.of(context).rideEventApprovedMessage(ride!.drive!.driver!.username);
      case RideEventCategory.rejected:
        return S.of(context).rideEventRejectedMessage(ride!.drive!.driver!.username);
      case RideEventCategory.cancelledByDriver:
        return S.of(context).rideEventCancelledByDriverMessage(ride!.drive!.driver!.username);
      case RideEventCategory.cancelledByRider:
        return S.of(context).rideEventCancelledByRiderMessage(ride!.rider!.username);
      case RideEventCategory.withdrawn:
        return S.of(context).rideEventWithdrawnMessage(ride!.rider!.username);
    }
  }

  @override
  String toString() {
    return 'RideEvent{id: $id, createdAt: $createdAt, read: $read, category: $category, ride_id: $rideId}';
  }
}

// Stored in the database as an integer
// The order of the enum values is important
enum RideEventCategory { pending, approved, rejected, cancelledByDriver, cancelledByRider, withdrawn }

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
      case RideEventCategory.withdrawn:
        return S.of(context).modelProfileFeatureNoSmoking;
    }
  }
}
