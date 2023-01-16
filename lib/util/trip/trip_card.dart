import 'package:flutter/material.dart';
import 'trip.dart';

abstract class TripCard<T extends Trip> extends StatelessWidget {
  final T trip;
  const TripCard(this.trip, {super.key});
}
