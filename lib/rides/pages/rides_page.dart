import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase_manager.dart';
import '../../util/trip/ride_card.dart';
import '../../util/trip/trip_page_builder.dart';
import '../../util/trip/trip_stream_builder.dart';
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
      title: S.of(context).pageRidesTitle,
      tabs: <String, TripStreamBuilder<Ride>>{
        S.of(context).widgetTripBuilderTabUpcoming: TripStreamBuilder<Ride>(
          key: const Key('upcomingTrips'),
          stream: _rides,
          emptyMessage: S.of(context).widgetTripBuilderNoUpcomingRides,
          filterTrips: (List<Ride> rides) =>
              rides.where((Ride ride) => ride.shouldShowInListView(past: false)).toList(),
          itemBuilder: (Ride trip) => RideCard(trip),
        ),
        S.of(context).widgetTripBuilderTabPast: TripStreamBuilder<Ride>(
          key: const Key('pastTrips'),
          stream: _rides,
          emptyMessage: S.of(context).widgetTripBuilderNoPastRides,
          filterTrips: (List<Ride> rides) =>
              rides.reversed.where((Ride ride) => ride.shouldShowInListView(past: true)).toList(),
          itemBuilder: (Ride trip) => RideCard(trip),
        )
      },
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: S.of(context).pageRidesTooltipSearchRide,
        onPressed: searchRide,
        backgroundColor: Theme.of(context).colorScheme.primary,
        key: const Key('ridesFAB'),
        child: const Icon(Icons.search),
      ),
    );
  }

  void searchRide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const SearchRidePage()),
    );
  }
}
