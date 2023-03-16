import 'package:motis_mitfahr_app/chat/models/chat.dart';
import 'package:motis_mitfahr_app/chat/models/message.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';

import 'message_factory.dart';
import 'model_factory.dart';

class ChatFactory extends ModelFactory<Chat> {
  @override
  Chat generateFake({
    int? id,
    DateTime? createdAt,
    Ride? ride,
    NullableParameter<List<Message>>? messages,
    bool createDependencies = true,
  }) {
    final List<Message>? generatedMessages =
        getNullableParameterOr(messages, MessageFactory().generateFakeList(length: 20, createDependencies: false));

    return Chat(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      ride: ride,
      messages: generatedMessages,
    );
  }
}
