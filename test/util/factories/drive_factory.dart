import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

import 'model_factory.dart';
import 'profile_factory.dart';
import 'ride_factory.dart';
import 'trip_factory.dart';

class DriveFactory extends TripFactory<Drive> {
  @override
  Drive generateFake({
    int? id,
    DateTime? createdAt,
    String? start,
    Position? startPosition,
    DateTime? startTime,
    String? end,
    Position? endPosition,
    DateTime? endTime,
    int? seats,
    bool? cancelled,
    int? driverId,
    NullableParameter<Profile>? driver,
    List<Ride>? rides,
    bool createDependencies = true,
  }) {
    assert(driverId == null || driver?.value == null || driver!.value?.id == driverId);

    Profile? generatedDriver =
        getNullableParameterOr(driver, ProfileFactory().generateFake(id: driverId, createDependencies: false));

    return Drive(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startTime: startTime ?? DateTime.now(),
      end: end ?? faker.address.city(),
      endPosition: endPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      endTime: endTime ?? DateTime.now(),
      seats: seats ?? random.nextInt(5) + 1,
      cancelled: cancelled ?? false,
      driverId: generatedDriver?.id ?? randomId,
      driver: generatedDriver,
      rides: rides ?? (createDependencies ? RideFactory().generateFakeList(length: random.nextInt(5) + 1) : null),
    );
  }
}
