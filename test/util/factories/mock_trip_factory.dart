import 'package:motis_mitfahr_app/util/search/position.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';

import 'trip_factory.dart';

class MockTrip extends Trip {
  MockTrip({
    required int super.id,
    required DateTime super.createdAt,
    required super.start,
    required super.startPosition,
    required super.startTime,
    required super.end,
    required super.endPosition,
    required super.endTime,
    required super.seats,
    required super.hideInListView,
  });
}

class MockTripFactory extends TripFactory<MockTrip> {
  @override
  MockTrip generateFake({
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
    return MockTrip(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startTime: startTime ?? DateTime.now(),
      end: end ?? faker.address.city(),
      endPosition: endPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      endTime: endTime ?? DateTime.now(),
      seats: seats ?? random.nextInt(5) + 1,
      hideInListView: hideInListView,
    );
  }
}
