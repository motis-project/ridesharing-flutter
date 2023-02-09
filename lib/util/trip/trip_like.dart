import '../model.dart';
import '../search/position.dart';

// Contains the common fields of a trip and a recurring drive
abstract class TripLike extends Model {
  static const int maxSelectableSeats = 8;

  final String start;
  final Position startPosition;
  final String end;
  final Position endPosition;

  final int seats;

  TripLike({
    super.id,
    super.createdAt,
    required this.start,
    required this.startPosition,
    required this.end,
    required this.endPosition,
    required this.seats,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start': start,
      'start_lat': startPosition.lat,
      'start_lng': startPosition.lng,
      'end': end,
      'end_lat': endPosition.lat,
      'end_lng': endPosition.lng,
      'seats': seats,
    };
  }
}
