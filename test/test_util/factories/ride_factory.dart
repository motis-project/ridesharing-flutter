import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/chat/models/chat.dart';
import 'package:motis_mitfahr_app/search/position.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';

import 'chat_factory.dart';
import 'drive_factory.dart';
import 'model_factory.dart';
import 'profile_factory.dart';
import 'trip_factory.dart';

class RideFactory extends TripFactory<Ride> {
  @override
  Ride generateFake({
    int? id,
    DateTime? createdAt,
    String? start,
    Position? startPosition,
    DateTime? startDateTime,
    String? destination,
    Position? destinationPosition,
    DateTime? destinationDateTime,
    int? seats,
    NullableParameter<double>? price,
    RideStatus? status,
    bool? hideInListView,
    int? driveId,
    NullableParameter<Drive>? drive,
    int? riderId,
    NullableParameter<Profile>? rider,
    int? chatId,
    NullableParameter<Chat>? chat,
    bool createDependencies = true,
  }) {
    assert(driveId == null || drive?.value == null || drive!.value?.id == driveId);
    assert(riderId == null || rider?.value == null || rider!.value?.id == riderId);
    assert(chatId == null || chat?.value == null || chat!.value?.id == chatId);

    final Drive? generatedDrive =
        getNullableParameterOr(drive, DriveFactory().generateFake(id: driveId, createDependencies: false));
    final Profile? generatedRider =
        getNullableParameterOr(rider, ProfileFactory().generateFake(id: riderId, createDependencies: false));
    final Chat? generatedChat =
        getNullableParameterOr(chat, ChatFactory().generateFake(id: chatId, createDependencies: false));

    final int generatedId = id ?? randomId;

    final TripTimes tripTimes = generateTimes(startDateTime, destinationDateTime);

    return Ride(
      id: generatedId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startDateTime: tripTimes.start,
      destination: destination ?? faker.address.city(),
      destinationPosition: destinationPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      destinationDateTime: tripTimes.destination,
      seats: seats ?? random.nextInt(5) + 1,
      price: getNullableParameterOr(price, double.parse((random.nextDouble() * 10).toStringAsFixed(2))),
      status: status ?? RideStatus.values[random.nextInt(RideStatus.values.length)],
      hideInListView: hideInListView ?? false,
      driveId: generatedDrive?.id ?? driveId ?? randomId,
      drive: generatedDrive,
      riderId: generatedRider?.id ?? riderId ?? randomId,
      rider: generatedRider,
      chatId: generatedChat?.id ?? chatId ?? randomId,
      chat: generatedChat,
    );
  }
}
