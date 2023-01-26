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
                key: const Key('upcomingTrips'),
                stream: trips,
                emptyMessage: isRide
                    ? S.of(context).widgetTripBuilderNoUpcomingRides
                    : S.of(context).widgetTripBuilderNoUpcomingDrives,
                filterTrips: getFilterTrips(past: false),
              ),
              TripStreamBuilder<T>(
                key: const Key('pastTrips'),
                stream: trips,
                emptyMessage:
                    isRide ? S.of(context).widgetTripBuilderNoPastRides : S.of(context).widgetTripBuilderNoPastDrives,
                filterTrips: getFilterTrips(past: true),
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

  List<T> Function(List<T>) getFilterTrips({required bool past}) => (List<T> trips) {
        if (past) trips = trips.reversed.toList();
        return trips.where((T trip) => trip.shouldShowInListView(past: past)).toList();
      };

  Widget getFloatingActionButton(BuildContext context, {required bool isRide}) {
    final String heroTag = isRide ? 'RideFAB' : 'DriveFAB';
    final String tooltip = isRide ? S.of(context).pageRidesTooltipSearchRide : S.of(context).pageDrivesTooltipOfferRide;
    final Icon icon = isRide ? const Icon(Icons.search) : const Icon(Icons.add);
    final Key key = isRide ? const Key('ridesFAB') : const Key('drivesFAB');

    return Hero(
      tag: heroTag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return Stack(
          children: <Widget>[
            Positioned.fill(child: fromHeroContext.widget),
            Positioned.fill(child: toHeroContext.widget),
          ],
        );
      },
      child: FadeTransition(
        opacity: ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation<double>(1),
        child: FadeTransition(
          opacity:
              ReverseAnimation(ModalRoute.of(context)?.secondaryAnimation ?? const AlwaysStoppedAnimation<double>(1)),
          child: FloatingActionButton(
            heroTag: null,
            tooltip: tooltip,
            onPressed: onFabPressed,
            backgroundColor: Theme.of(context).colorScheme.primary,
            key: key,
            child: icon,
          ),
        ),
      ),
    );
  }
}
