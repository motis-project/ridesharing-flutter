import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/models/ride.dart';
import 'trip.dart';
import 'trip_card.dart';
import 'trip_stream_builder.dart';

class TripPageBuilder {
  const TripPageBuilder();

  static Widget build<T extends Trip>(
    BuildContext context,
    String title,
    Stream<List<T>> trips,
    TripCard<T> Function(T) tripCard,
    FloatingActionButton floatingActionButton,
  ) {
    String name = title.toLowerCase();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.onSurface,
            tabs: [
              Tab(text: S.of(context).widgetTripBuilderTabUpcoming),
              Tab(text: S.of(context).widgetTripBuilderTabPast),
            ],
          ),
        ),
        body: Semantics(
          sortKey: const OrdinalSortKey(1),
          child: TabBarView(
            children: [
              TripStreamBuilder<T>(
                stream: trips,
                emptyMessage: S.of(context).widgetTripBuilderNoUpcoming(name),
                filterTrips: (trips) => trips
                    .where((trip) =>
                        trip.endTime.isAfter(DateTime.now()) &&
                        (trip is! Ride || trip.status != RideStatus.withdrawnByRider))
                    .toList(),
                tripCard: tripCard,
              ),
              TripStreamBuilder<T>(
                stream: trips,
                emptyMessage: S.of(context).widgetTripBuilderNoPast(name),
                filterTrips: (trips) => trips.reversed
                    .where((trip) =>
                        trip.endTime.isBefore(DateTime.now()) &&
                        (trip is! Ride || trip.status != RideStatus.withdrawnByRider))
                    .toList(),
                tripCard: tripCard,
              ),
            ],
          ),
        ),
        floatingActionButton: Semantics(sortKey: const OrdinalSortKey(0), child: floatingActionButton),
      ),
    );
  }
}
