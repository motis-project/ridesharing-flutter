import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';

import 'drive_factory.dart';
import 'message_factory.dart';
import 'model_factory.dart';
import 'ride_factory.dart';

class ChatFactory extends ModelFactory<Chat> {
  @override
  Chat generateFake({
    int? id,
    DateTime? createdAt,
    int? rideId,
    NullableParameter<Ride>? ride,
    int? driveId,
    NullableParameter<Drive>? drive,
    NullableParameter<List<Message>>? messages,
    bool createDependencies = true,
  }) {
    assert(rideId == null || ride?.value == null || ride!.value?.id == rideId, "riderId and rider.id must be equal");
    assert(
        driveId == null || drive?.value == null || drive!.value?.id == driveId, "driveId and drive.id must be equal");

    Ride? generatedRide =
        getNullableParameterOr(ride, RideFactory().generateFake(id: rideId, createDependencies: false));
    Drive? generatedDrive =
        getNullableParameterOr(drive, DriveFactory().generateFake(id: driveId, createDependencies: false));
    List<Message>? generatedMessages =
        getNullableParameterOr(messages, MessageFactory().generateFakeList(length: 20, createDependencies: false));

    return Chat(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      rideId: generatedRide?.id ?? randomId,
      ride: generatedRide,
      driveId: generatedDrive?.id ?? randomId,
      drive: generatedDrive,
      messages: generatedMessages,
    );
  }
}
