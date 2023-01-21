import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

import 'chat_factory.dart';
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
    bool? hideInListView,
    int? driverId,
    NullableParameter<Profile>? driver,
    List<Ride>? rides,
    List<Chat>? chats,
    bool createDependencies = true,
  }) {
    assert(driverId == null || driver?.value == null || driver!.value?.id == driverId);

    final Profile? generatedDriver = getNullableParameterOr(
        driver,
        ProfileFactory().generateFake(
          id: driverId,
          createDependencies: false,
        ));
    final List<Ride>? generatedRides = rides ??
        (createDependencies
            ? RideFactory().generateFakeList(
                length: random.nextInt(5) + 1,
                createDependencies: false,
              )
            : null);
    final List<Chat>? generatedChats = chats ??
        (createDependencies
            ? generatedRides
                ?.map((ride) => ChatFactory().generateFake(
                      rideId: ride.id,
                      ride: NullableParameter(ride),
                      createDependencies: false,
                    ))
                .toList()
            : null);

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
      hideInListView: hideInListView ?? false,
      driverId: generatedDriver?.id ?? randomId,
      driver: generatedDriver,
      rides: generatedRides,
      chats: generatedChats,
    );
  }
}
