import 'package:flutter/material.dart';

import '../../util/supabase_manager.dart';
import '../../util/trip/trip_page_builder.dart';
import '../models/ride.dart';
import 'search_ride_page.dart';

class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  late final Stream<List<Ride>> _rides;

  @override
  void initState() {
    final int userId = supabaseManager.currentProfile!.id!;
    _rides = supabaseManager.supabaseClient
        .from('rides')
        .stream(primaryKey: <String>['id'])
        .eq('rider_id', userId)
        .order('start_time', ascending: true)
        .map((List<Map<String, dynamic>> ride) => Ride.fromJsonList(ride));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TripPageBuilder<Ride>(
      _rides,
      onFabPressed: searchRide,
    );
  }

  void searchRide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const SearchRidePage()),
    );
  }
}
