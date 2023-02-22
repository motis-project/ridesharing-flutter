import 'package:flutter/material.dart';

import 'trip_like.dart';

class Trip extends TripLike {
  static const int maxSelectableSeats = 8;

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
