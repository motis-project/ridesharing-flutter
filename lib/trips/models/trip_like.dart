import 'package:flutter/material.dart';

import '../../model.dart';
import '../../search/position.dart';

// Contains the common fields of a trip and a recurring drive
abstract class TripLike extends Model {
  static const int maxSelectableSeats = 8;

  final String start;
  final Position startPosition;
  final String destination;
  final Position destinationPosition;

  final int seats;

  TripLike({
    super.id,
    super.createdAt,
    required this.start,
    required this.startPosition,
    required this.destination,
    required this.destinationPosition,
    required this.seats,
  });

  TimeOfDay get startTime;
  TimeOfDay get destinationTime;
  Duration get duration;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start,
      'start_lat': startPosition.lat,
      'start_lng': startPosition.lng,
      'destination': destination,
      'destination_lat': destinationPosition.lat,
      'destination_lng': destinationPosition.lng,
      'seats': seats,
    };
  }
}
