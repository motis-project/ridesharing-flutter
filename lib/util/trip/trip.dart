import 'package:flutter_app/util/model.dart';

abstract class Trip extends Model {
  final String start;
  final DateTime startTime;
  final String end;
  final DateTime endTime;

  final int seats;

  Trip({
    super.id,
    super.createdAt,
    required this.start,
    required this.startTime,
    required this.end,
    required this.endTime,
    required this.seats,
  });
}
