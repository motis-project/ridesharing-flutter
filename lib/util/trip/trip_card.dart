import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

abstract class TripCard<T extends Trip> extends StatefulWidget {
  final T trip;
  const TripCard(this.trip, {super.key});
}
