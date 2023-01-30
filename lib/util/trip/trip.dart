import 'package:flutter/material.dart';

import '../model.dart';
import '../search/position.dart';

class Trip extends Model {
  static const int maxSelectableSeats = 8;

  final String start;
  final Position startPosition;
  final DateTime startTime;
  final String end;
  final Position endPosition;
  final DateTime endTime;
  final bool hideInListView;

  final int seats;

  Trip({
    super.id,
    super.createdAt,
    required this.start,
    required this.startPosition,
    required this.startTime,
    required this.end,
    required this.endPosition,
    required this.endTime,
    required this.seats,
    this.hideInListView = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start,
      'start_lat': startPosition.lat,
      'start_lng': startPosition.lng,
      'start_time': startTime.toString(),
      'end': end,
      'end_lat': endPosition.lat,
      'end_lng': endPosition.lng,
      'end_time': endTime.toString(),
      'seats': seats,
      'hide_in_list_view': hideInListView,
    };
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
