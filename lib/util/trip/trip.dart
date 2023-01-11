import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/model.dart';

abstract class Trip extends Model {
  final String start;
  final DateTime startTime;
  final String end;
  final DateTime endTime;
  final bool show;

  final int seats;

  Trip(
      {super.id,
      super.createdAt,
      required this.start,
      required this.startTime,
      required this.end,
      required this.endTime,
      required this.seats,
      this.show = true});

  bool get isFinished => endTime.isBefore(DateTime.now());
  bool get isOngoing => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());

  bool overlapsWith(Trip other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  bool overlapsWithTimeRange(DateTimeRange range) {
    return startTime.isBefore(range.end) && endTime.isAfter(range.start);
  }
}
