import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:flutter_app/util/trip/trip_stream_builder.dart';

class TripPageBuilder {
  const TripPageBuilder();

  static Widget build<T extends Trip>(
      BuildContext context,
      String title,
      Stream<List<T>> trips,
      TripCard<T> Function(T) tripCard,
      FloatingActionButton floatingActionButton) {
    String name = title.toLowerCase();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: 'Upcoming',
              ),
              Tab(
                text: 'Past',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TripStreamBuilder<T>(
              stream: trips,
              emptyMessage: 'No upcoming $name',
              filterTrips: (trips) => trips
                  //we could change this to trip.starttime the question is what we are doing with
                  //trips that are in progress
                  .where((trip) => trip.endTime.isAfter(DateTime.now()))
                  .toList(),
              tripCard: tripCard,
            ),
            TripStreamBuilder<T>(
              stream: trips,
              emptyMessage: 'No past $name',
              filterTrips: (trips) => trips.reversed
                  .where((trip) => trip.endTime.isBefore(DateTime.now()))
                  .toList(),
              tripCard: tripCard,
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
