import 'package:motis_mitfahr_app/home/models/ride_event.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';

import 'model_factory.dart';
import 'ride_factory.dart';

class RideEventFactory extends ModelFactory<RideEvent> {
  @override
  RideEvent generateFake({
    int? id,
    DateTime? createdAt,
    RideEventCategory? category,
    bool? read,
    int? rideId,
    NullableParameter<Ride>? ride,
    bool createDependencies = true,
  }) {
    assert(rideId == null || ride?.value == null || ride!.value!.id! == rideId, 'rideId musst be equal to ride.id');
    final Ride? generatedRide = createDependencies
        ? getNullableParameterOr(ride, RideFactory().generateFake(id: rideId, createDependencies: false))
        : null;

    return RideEvent(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      category: category ?? RideEventCategory.values[random.nextInt(RideEventCategory.values.length)],
      read: read ?? false,
      rideId: generatedRide?.id ?? rideId ?? randomId,
      ride: generatedRide,
    );
  }
}
