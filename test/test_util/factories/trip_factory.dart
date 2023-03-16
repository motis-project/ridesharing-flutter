import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/trip.dart';

import 'model_factory.dart';

class TripFactory<T extends Trip> extends ModelFactory<T> {
  @override
  T generateFake({
    int? id,
    DateTime? createdAt,
    String? start,
    Position? startPosition,
    DateTime? startDateTime,
    String? destination,
    Position? destinationPosition,
    DateTime? destinationDateTime,
    int? seats,
    bool hideInListView = false,
    bool createDependencies = true,
  }) {
    final TripTimes times = generateTimes(startDateTime, destinationDateTime);

    return Trip(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startDateTime: times.start,
      destination: destination ?? faker.address.city(),
      destinationPosition: destinationPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      destinationDateTime: times.destination,
      seats: seats ?? random.nextInt(5) + 1,
      hideInListView: hideInListView,
    ) as T;
  }

  TripTimes generateTimes(DateTime? startTime, DateTime? destinationTime) {
    // Only applied if startTime or destinationTime are null
    final Duration randomDuration = Duration(hours: random.nextInt(5) + 1);

    startTime ??= destinationTime == null ? DateTime.now() : destinationTime.subtract(randomDuration);
    destinationTime ??= startTime.add(randomDuration);

    assert(startTime.isBefore(destinationTime));

    return TripTimes(startTime, destinationTime);
  }
}

class TripTimes {
  final DateTime start;
  final DateTime destination;

  TripTimes(this.start, this.destination);
}
