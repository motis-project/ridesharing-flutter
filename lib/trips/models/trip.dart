import 'package:flutter/material.dart';

import 'trip_like.dart';

class Trip extends TripLike {
  //-------------------- Constants --------------//
  // These constants are also defined in the backend

  // How far in the future trips can be created
  // (Also applies to the drives created by recurring drives)
  static const Duration creationInterval = Duration(days: 30);

  // How many seats can be selected at most
  static const int maxSelectableSeats = 8;

  //-------------------- Constants --------------//

  final DateTime startDateTime;
  final DateTime destinationDateTime;
  final bool hideInListView;

  Trip({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required this.startDateTime,
    required super.destination,
    required super.destinationPosition,
    required this.destinationDateTime,
    required super.seats,
    this.hideInListView = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'start_date_time': startDateTime.toString(),
        'destination_date_time': destinationDateTime.toString(),
        'hide_in_list_view': hideInListView,
      });
  }

  @override
  Duration get duration => destinationDateTime.difference(startDateTime);
  bool get isFinished => destinationDateTime.isBefore(DateTime.now());
  bool get isOngoing => startDateTime.isBefore(DateTime.now()) && destinationDateTime.isAfter(DateTime.now());

  @override
  TimeOfDay get startTime => TimeOfDay.fromDateTime(startDateTime);

  @override
  TimeOfDay get destinationTime => TimeOfDay.fromDateTime(destinationDateTime);

  bool overlapsWith(Trip other) {
    return startDateTime.isBefore(other.destinationDateTime) && destinationDateTime.isAfter(other.startDateTime);
  }

  bool overlapsWithTimeRange(DateTimeRange range) {
    return startDateTime.isBefore(range.end) && destinationDateTime.isAfter(range.start);
  }

  /// Returns whether this trip should be shown in the list view given if the list view is for past or future trips:
  ///
  /// - [past] If the trip is finished and the list view is for past trips, it is shown
  /// - ![past] If the trip is not finished and the list view is for future trips, it is shown
  bool shouldShowInListView({required bool past}) {
    return !hideInListView && (past ? isFinished : !isFinished);
  }

  bool equals(Trip other) {
    return id == other.id &&
        createdAt == other.createdAt &&
        start == other.start &&
        startPosition == other.startPosition &&
        startDateTime == other.startDateTime &&
        destination == other.destination &&
        destinationPosition == other.destinationPosition &&
        destinationDateTime == other.destinationDateTime &&
        seats == other.seats &&
        hideInListView == other.hideInListView;
  }
}
