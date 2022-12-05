import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/trip.dart';

import 'trip_card.dart';

class TripStreamBuilder<T extends Trip> extends StreamBuilder<List<T>> {
  TripStreamBuilder({
    Key? key,
    required Stream<List<T>> stream,
    required String emptyMessage,
    required List<T> Function(List<T> trips) filterTrips,
    required TripCard<T> Function(T trip) tripCard,
  }) : super(
          key: key,
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<T> trips = snapshot.data!;
              List<T> filteredTrips = filterTrips(trips);
              return trips.isEmpty
                  ? Center(child: Text(emptyMessage))
                  : ListView.builder(
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
                        return tripCard(trip);
                      },
                    );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
}
