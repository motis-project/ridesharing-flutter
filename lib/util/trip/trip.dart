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
  final DateTime endDateTime;
  final bool hideInListView;

  Trip({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required this.startDateTime,
    required super.end,
    required super.endPosition,
    required this.endDateTime,
    required super.seats,
    this.hideInListView = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'start_time': startDateTime.toString(),
        'end_time': endDateTime.toString(),
        'hide_in_list_view': hideInListView,
      });
  }

  @override
  Duration get duration => endDateTime.difference(startDateTime);
  bool get isFinished => endDateTime.isBefore(DateTime.now());
  bool get isOngoing => startDateTime.isBefore(DateTime.now()) && endDateTime.isAfter(DateTime.now());

  @override
  TimeOfDay get startTime => TimeOfDay.fromDateTime(startDateTime);

  @override
  TimeOfDay get endTime => TimeOfDay.fromDateTime(endDateTime);

  bool overlapsWith(Trip other) {
    return startDateTime.isBefore(other.endDateTime) && endDateTime.isAfter(other.startDateTime);
  }

  bool overlapsWithTimeRange(DateTimeRange range) {
    return startDateTime.isBefore(range.end) && endDateTime.isAfter(range.start);
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
        end == other.end &&
        endPosition == other.endPosition &&
        endDateTime == other.endDateTime &&
        seats == other.seats &&
        hideInListView == other.hideInListView;
  }
}
