import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/models/ride.dart';
import 'trip.dart';
import 'trip_stream_builder.dart';

class TripPageBuilder<T extends Trip> extends StatelessWidget {
  final Stream<List<T>> trips;
  final Function() onFabPressed;

  const TripPageBuilder(this.trips, {super.key, required this.onFabPressed});

  @override
  Widget build(BuildContext context) {
    final bool isRide = T == Ride;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRide ? S.of(context).pageRidesTitle : S.of(context).pageDrivesTitle),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onSurface,
            tabs: <Tab>[
              Tab(text: S.of(context).widgetTripBuilderTabUpcoming),
              Tab(text: S.of(context).widgetTripBuilderTabPast),
            ],
          ),
        ),
        body: Semantics(
          sortKey: const OrdinalSortKey(1),
          child: TabBarView(
            children: <Widget>[
              TripStreamBuilder<T>(
                stream: trips,
                emptyMessage: isRide
                    ? S.of(context).widgetTripBuilderNoUpcomingRides
                    : S.of(context).widgetTripBuilderNoUpcomingDrives,
                filterTrips: (List<T> trips) =>
                    trips.where((T trip) => trip.shouldShowInListView(past: false)).toList(),
              ),
              TripStreamBuilder<T>(
                stream: trips,
                emptyMessage:
                    isRide ? S.of(context).widgetTripBuilderNoPastRides : S.of(context).widgetTripBuilderNoPastDrives,
                filterTrips: (List<T> trips) =>
                    trips.reversed.where((T trip) => trip.shouldShowInListView(past: true)).toList(),
              ),
            ],
          ),
        ),
        floatingActionButton: Semantics(
          sortKey: const OrdinalSortKey(0),
          child: getFloatingActionButton(context, isRide: isRide),
        ),
      ),
    );
  }

  Widget getFloatingActionButton(BuildContext context, {required bool isRide}) {
    if (isRide) {
      return FloatingActionButton(
        heroTag: 'RideFAB',
        tooltip: S.of(context).pageRidesTooltipSearchRide,
        onPressed: onFabPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.search),
      );
    } else {
      return FloatingActionButton(
        heroTag: 'DriveFAB',
        tooltip: S.of(context).pageDrivesTooltipOfferRide,
        onPressed: onFabPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      );
    }
  }
}
