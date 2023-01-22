import 'dart:math';

import 'package:motis_mitfahr_app/util/ride_event.dart';

import 'model_factory.dart';

class RideEventFactory extends ModelFactory<RideEvent> {
  @override
  RideEvent generateFake({
    int? id,
    DateTime? createdAt,
    RideEventCategory? category,
    bool? read,
    int? rideId,
    bool createDependencies = true,
  }) {
    return RideEvent(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      category: category ?? RideEventCategory.values[random.nextInt(RideEventCategory.values.length)],
      read: read ?? Random().nextBool(),
      rideId: rideId ?? randomId,
    );
  }
}
