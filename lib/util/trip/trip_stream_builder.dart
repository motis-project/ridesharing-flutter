import 'package:flutter/material.dart';

import 'trip.dart';
import 'trip_card.dart';

class TripStreamBuilder<T extends Trip> extends StreamBuilder<List<T>> {
  TripStreamBuilder({
    super.key,
    required Stream<List<T>> stream,
    required String emptyMessage,
    required List<T> Function(List<T> trips) filterTrips,
    required TripCard<T> Function(T trip) tripCard,
  }) : super(
          stream: stream,
          builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
            if (snapshot.hasData) {
              final List<T> trips = snapshot.data!;
              final List<T> filteredTrips = filterTrips(trips);
              return filteredTrips.isEmpty
                  ? Center(child: Text(emptyMessage))
                  : ListView.separated(
                      itemCount: filteredTrips.length,
                      itemBuilder: (BuildContext context, int index) {
                        final T trip = filteredTrips[index];

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
