import 'package:flutter/material.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:intl/intl.dart';

abstract class TripCard<T extends Trip> extends StatelessWidget {
  final T trip;
  const TripCard(this.trip, {super.key});

  String formatTime(DateTime time) {
    return DateFormat.Hm().format(time.toLocal());
  }

  String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date.toLocal());
  }
}
