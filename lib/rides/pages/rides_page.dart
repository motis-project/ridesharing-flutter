import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/rides/pages/search_ride_page.dart';
import 'package:motis_mitfahr_app/util/trip/trip_page_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    _rides = SupabaseManager.supabaseClient
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
      S.of(context).pageRidesTitle, //title
      _rides, //trips
      (ride) => RideCard(ride),
      FloatingActionButton(
        heroTag: 'RideFAB',
        tooltip: S.of(context).pageRidesTooltipSearchRide,
        onPressed: searchRide,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.search),
      ),
    );
  }

  void searchRide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SearchRidePage()),
    );
  }
}
