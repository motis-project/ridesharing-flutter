import 'package:flutter/material.dart';
import 'package:flutter_app/rides/pages/search_ride_page.dart';
import 'package:flutter_app/util/trip/trip_page_builder.dart';

import '../../util/supabase.dart';
import '../../util/trip/ride_card.dart';
import '../models/ride.dart';
import 'package:flutter_app/rides/pages/search_ride_page.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/trip/trip_page_builder.dart';

import '../../util/supabase.dart';
import '../../util/trip/ride_card.dart';
import '../models/ride.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  late final Stream<List<Ride>> _rides;

  @override
  void initState() {
    //todo: method to get userId
    int userId = SupabaseManager.getCurrentProfile()!.id!;
    _rides = supabaseClient
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('rider_id', userId)
        .order('start_time', ascending: true)
        .map((ride) => Ride.fromJsonList(ride));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TripPageBuilder.build(
      context, //context
      'Rides', //title
      _rides, //trips
      (ride) => RideCard(trip: ride), //tripCard
      FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SearchRidePage()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.search),
      ),
    );
  }
}
