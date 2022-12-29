import 'package:flutter/material.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/trip/ride_card_state.dart';
import 'package:flutter_app/util/trip/trip_card.dart';

class RideCard extends TripCard<Ride> {
  const RideCard(super.trip, {super.key});

  @override
  State<RideCard> createState() => RideCardState();
}
