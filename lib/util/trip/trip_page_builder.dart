import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:flutter_app/util/trip/trip_stream_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        body: TabBarView(
          children: [
            TripStreamBuilder<T>(
              stream: trips,
              emptyMessage: S.of(context).widgetTripBuilderNoUpcoming(name),
              filterTrips: (trips) => trips.where((trip) => trip.endTime.isAfter(DateTime.now())).toList(),
              tripCard: tripCard,
            ),
            TripStreamBuilder<T>(
              stream: trips,
              emptyMessage: S.of(context).widgetTripBuilderNoPast(name),
              filterTrips: (trips) => trips.reversed.where((trip) => trip.endTime.isBefore(DateTime.now())).toList(),
              tripCard: tripCard,
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
