import 'package:motis_mitfahr_app/util/search/position.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

import 'model_factory.dart';

class TripFactory<T extends Trip> extends ModelFactory<T> {
  @override
  T generateFake({
    int? id,
    DateTime? createdAt,
    String? start,
    Position? startPosition,
    DateTime? startTime,
    String? end,
    Position? endPosition,
    DateTime? endTime,
    int? seats,
    bool hideInListView = false,
    bool createDependencies = true,
  }) {
    final TripTimes times = generateTimes(startTime, endTime);

    return Trip(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startTime: times.start,
      end: end ?? faker.address.city(),
      endPosition: endPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      endTime: times.end,
      seats: seats ?? random.nextInt(5) + 1,
      hideInListView: hideInListView,
    ) as T;
  }

  TripTimes generateTimes(DateTime? startTime, DateTime? endTime) {
    // Only applied if startTime or endTime are null
    final Duration randomDuration = Duration(hours: random.nextInt(5) + 1);

    startTime ??= endTime == null ? DateTime.now() : endTime.subtract(randomDuration);
    endTime ??= startTime.add(randomDuration);

    assert(startTime.isBefore(endTime));

    return TripTimes(startTime, endTime);
  }
}

class TripTimes {
  final DateTime start;
  final DateTime end;

  TripTimes(this.start, this.end);
}
