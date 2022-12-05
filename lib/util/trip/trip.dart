import 'package:flutter/material.dart';
import 'package:flutter_app/util/model.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:flutter_app/util/trip/trip_stream_builder.dart';

abstract class Trip extends Model {
  final String start;
  final DateTime startTime;
  final String end;
  final DateTime endTime;

  final int seats;
  final int userId;

  Trip({
    super.id,
    super.createdAt,
    required this.start,
    required this.startTime,
    required this.end,
    required this.endTime,
    required this.seats,
    required this.userId,
  });

  //todo: make widget for that
  static Widget buildTripPage<T extends Trip>(
      BuildContext context,
      String title,
      Stream<List<T>> trips,
      TripCard<T> Function(T) tripCard,
      FloatingActionButton floatingActionButton) {
    String name = title.toLowerCase();
    return DefaultTabController(
      length: 3,
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
              Tab(
                text: 'All',
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
            TripStreamBuilder<T>(
              stream: trips,
              emptyMessage: 'No $name',
              //we could reorder the stream her somehow, not shure how it's best
              filterTrips: (trips) => trips,
              tripCard: tripCard,
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
