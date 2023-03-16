import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/chat/models/chat.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';

import 'model_factory.dart';
import 'profile_factory.dart';
import 'recurring_drive_factory.dart';
import 'ride_factory.dart';
import 'trip_factory.dart';

class DriveFactory extends TripFactory<Drive> {
  @override
  Drive generateFake({
    int? id,
    DateTime? createdAt,
    String? start,
    Position? startPosition,
    DateTime? startDateTime,
    String? destination,
    Position? destinationPosition,
    DateTime? destinationDateTime,
    int? seats,
    DriveStatus? status,
    bool? hideInListView,
    int? driverId,
    NullableParameter<Profile>? driver,
    NullableParameter<int>? recurringDriveId,
    NullableParameter<RecurringDrive>? recurringDrive,
    List<Ride>? rides,
    List<Chat>? chats,
    bool createDependencies = true,
  }) {
    assert(driverId == null || driver?.value == null || driver!.value?.id == driverId);
    assert(recurringDriveId?.value == null ||
        recurringDrive?.value == null ||
        recurringDrive!.value?.id == recurringDriveId!.value);

    final Profile? generatedDriver = getNullableParameterOr(
        driver,
        ProfileFactory().generateFake(
          id: driverId,
          createDependencies: false,
        ));
    final RecurringDrive? generatedRecurringDrive = getNullableParameterOr(
        recurringDrive,
        RecurringDriveFactory().generateFake(
          id: recurringDriveId?.value,
          createDependencies: false,
        ));
    final List<Ride>? generatedRides = rides ??
        (createDependencies
            ? RideFactory().generateFakeList(
                length: random.nextInt(5) + 1,
                createDependencies: false,
              )
            : null);

    final TripTimes tripTimes = generateTimes(startDateTime, destinationDateTime);

    return Drive(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startDateTime: tripTimes.start,
      destination: destination ?? faker.address.city(),
      destinationPosition: destinationPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      destinationDateTime: tripTimes.destination,
      seats: seats ?? random.nextInt(5) + 1,
      status: status ?? DriveStatus.plannedOrFinished,
      hideInListView: hideInListView ?? false,
      driverId: generatedDriver?.id ?? driverId ?? randomId,
      driver: generatedDriver,
      recurringDriveId: generatedRecurringDrive?.id ?? getNullableParameterOr(recurringDriveId, randomId),
      recurringDrive: generatedRecurringDrive,
      rides: generatedRides,
    );
  }
}
