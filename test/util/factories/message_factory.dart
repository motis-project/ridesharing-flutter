import 'package:motis_mitfahr_app/util/chat/models/message.dart';

import 'model_factory.dart';

class MessageFactory extends ModelFactory<Message> {
  @override
  Message generateFake({
    int? id,
    DateTime? createdAt,
    int? rideId,
    String? content,
    int? senderId,
    bool? read,
    bool createDependencies = true,
  }) {
    return Message(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      rideId: rideId ?? randomId,
      content: content ?? faker.lorem.sentences(random.nextInt(2) + 1).join(" "),
      senderId: senderId ?? randomId,
      read: read ?? false,
    );
  }
}
