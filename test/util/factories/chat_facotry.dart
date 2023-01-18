import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';

import 'drive_factory.dart';
import 'message_factory.dart';
import 'model_factory.dart';
import 'profile_factory.dart';

class ChatFactory extends ModelFactory<Chat> {
  @override
  Chat generateFake({
    int? id,
    DateTime? createdAt,
    int? riderId,
    NullableParameter<Profile>? rider,
    int? driveId,
    NullableParameter<Drive>? drive,
    List<Message>? messages,
    bool createDependencies = true,
  }) {
    assert(
        riderId == null || rider?.value == null || rider!.value?.id == riderId, "riderId and rider.id must be equal");
    assert(
        driveId == null || drive?.value == null || drive!.value?.id == driveId, "driveId and drive.id must be equal");

    Profile? generatedRider =
        getNullableParameterOr(rider, ProfileFactory().generateFake(id: riderId, createDependencies: false));
    Drive? generatedDrive =
        getNullableParameterOr(drive, DriveFactory().generateFake(id: driveId, createDependencies: false));

    return Chat(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      riderId: generatedRider?.id ?? randomId,
      rider: generatedRider,
      driveId: generatedDrive?.id ?? randomId,
      drive: generatedDrive,
      messages: messages ?? MessageFactory().generateFakeList(createDependencies: false),
    );
  }
}
