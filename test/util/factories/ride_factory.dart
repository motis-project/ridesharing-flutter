import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

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
    DateTime? startTime,
    String? end,
    Position? endPosition,
    DateTime? endTime,
    int? seats,
    NullableParameter<double>? price,
    RideStatus? status,
    bool? hideInListView,
    int? driveId,
    NullableParameter<Drive>? drive,
    int? riderId,
    NullableParameter<Profile>? ride,
    int? chatId,
    NullableParameter<Chat>? chat,
    bool createDependencies = true,
  }) {
    assert(driveId == null || drive?.value == null || drive!.value?.id == driveId);
    assert(riderId == null || ride?.value == null || ride!.value?.id == riderId);
    assert(chatId == null || chat?.value == null || chat!.value?.id == chatId);

    final Drive? generatedDrive =
        getNullableParameterOr(drive, DriveFactory().generateFake(id: driveId, createDependencies: false));
    final Profile? generatedRider =
        getNullableParameterOr(ride, ProfileFactory().generateFake(id: riderId, createDependencies: false));
    final Chat? generatedChat =
        getNullableParameterOr(chat, ChatFactory().generateFake(id: chatId, createDependencies: false));

    final int generatedId = id ?? randomId;

    return Ride(
      id: generatedId,
      createdAt: createdAt ?? DateTime.now(),
      start: start ?? faker.address.city(),
      startPosition: startPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      startTime: startTime ?? DateTime.now(),
      end: end ?? faker.address.city(),
      endPosition: endPosition ?? Position(faker.geo.latitude(), faker.geo.longitude()),
      endTime: endTime ?? DateTime.now(),
      seats: seats ?? random.nextInt(5) + 1,
      price: getNullableParameterOr(price, double.parse((random.nextDouble() * 10).toStringAsFixed(2))),
      status: status ?? RideStatus.values[random.nextInt(RideStatus.values.length)],
      hideInListView: hideInListView ?? false,
      driveId: generatedDrive?.id ?? randomId,
      drive: generatedDrive,
      riderId: generatedRider?.id ?? randomId,
      rider: generatedRider,
      chatId: generatedChat?.id ?? randomId,
      chat: generatedChat,
    );
  }
}
