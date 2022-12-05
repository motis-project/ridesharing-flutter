import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RideCard extends TripCard<Ride> {
  const RideCard({super.key, required super.trip});
}
