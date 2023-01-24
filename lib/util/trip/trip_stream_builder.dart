import 'package:flutter/material.dart';

import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import 'drive_card.dart';
import 'ride_card.dart';
import 'trip.dart';

class TripStreamBuilder<T extends Trip> extends StreamBuilder<List<T>> {
  TripStreamBuilder({
    super.key,
    super.stream,
    required String emptyMessage,
    required List<T> Function(List<T> trips) filterTrips,
  }) : super(
          builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
            if (snapshot.hasData) {
              final List<T> trips = snapshot.data!;
              final List<T> filteredTrips = filterTrips(trips);
              return filteredTrips.isEmpty
                  ? Center(key: const Key('emptyMessage'), child: Text(emptyMessage))
                  : ListView.separated(
                      itemCount: filteredTrips.length,
                      itemBuilder: (BuildContext context, int index) {
                        final T trip = filteredTrips[index];

                        return trip is Ride ? RideCard(trip) : DriveCard(trip as Drive);
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
