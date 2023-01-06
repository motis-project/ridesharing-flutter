import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

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
              return filteredTrips.isEmpty
                  ? Center(child: Text(emptyMessage))
                  : ListView.separated(
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
                        return tripCard(trip);
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 10);
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
