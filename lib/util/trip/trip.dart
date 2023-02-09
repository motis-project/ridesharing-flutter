import 'package:flutter/material.dart';

import 'trip_like.dart';

class Trip extends TripLike {
  static const int maxSelectableSeats = 8;

  final DateTime startTime;
  final DateTime endTime;
  final bool hideInListView;

  Trip({
    super.id,
    super.createdAt,
    required super.start,
    required super.startPosition,
    required this.startTime,
    required super.end,
    required super.endPosition,
    required this.endTime,
    required super.seats,
    this.hideInListView = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll(<String, dynamic>{
        'start_time': startTime.toString(),
        'end_time': endTime.toString(),
        'hide_in_list_view': hideInListView,
      });
  }

  Duration get duration => endTime.difference(startTime);
  bool get isFinished => endTime.isBefore(DateTime.now());
  bool get isOngoing => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());

  bool overlapsWith(Trip other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  bool overlapsWithTimeRange(DateTimeRange range) {
    return startTime.isBefore(range.end) && endTime.isAfter(range.start);
  }

  bool shouldShowInListView({required bool past}) {
    return !hideInListView && (past ? isFinished : !isFinished);
  }

  bool equals(Trip other) {
    return id == other.id &&
        createdAt == other.createdAt &&
        start == other.start &&
        startPosition == other.startPosition &&
        startTime == other.startTime &&
        end == other.end &&
        endPosition == other.endPosition &&
        endTime == other.endTime &&
        seats == other.seats &&
        hideInListView == other.hideInListView;
  }
}
