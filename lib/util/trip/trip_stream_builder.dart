import 'package:flutter/material.dart';

class TripStreamBuilder<T> extends StreamBuilder<List<T>> {
  TripStreamBuilder({
    super.key,
    super.stream,
    required String emptyMessage,
    List<T> Function(List<T> trips)? filterTrips,
    required Widget Function(T trip) itemBuilder,
  }) : super(
          builder: (BuildContext context, AsyncSnapshot<List<T>> snapshot) {
            if (snapshot.hasData) {
              final List<T> trips = snapshot.data!;
              final List<T> filteredTrips = filterTrips != null ? filterTrips(trips) : trips;
              return filteredTrips.isEmpty
                  ? Center(key: const Key('emptyMessage'), child: Text(emptyMessage))
                  : ListView.separated(
                      itemCount: filteredTrips.length,
                      itemBuilder: (BuildContext context, int index) {
                        final T trip = filteredTrips[index];

                        return itemBuilder(trip);
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
