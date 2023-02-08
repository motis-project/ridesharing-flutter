import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';

import 'chat_factory.dart';
import 'model_factory.dart';
import 'profile_factory.dart';

class MessageFactory extends ModelFactory<Message> {
  @override
  Message generateFake({
    int? id,
    DateTime? createdAt,
    int? chatId,
    NullableParameter<Chat>? chat,
    String? content,
    int? senderId,
    NullableParameter<Profile>? sender,
    bool? read,
    bool createDependencies = true,
  }) {
    assert(chatId == null || chat?.value == null || chat!.value?.id == chatId, 'chatId and chat.id must be equal');
    assert(senderId == null || sender?.value == null || sender!.value?.id == senderId,
        'senderId and sender.id must be equal');

    final Profile? generatedSender =
        getNullableParameterOr(sender, ProfileFactory().generateFake(id: senderId, createDependencies: false));
    final Chat? generatedChat = createDependencies
        ? getNullableParameterOr(chat, ChatFactory().generateFake(id: chatId, createDependencies: false))
        : null;

    return Message(
      id: id ?? randomId,
      createdAt: createdAt ?? DateTime.now(),
      chatId: generatedChat?.id ?? randomId,
      chat: generatedChat,
      content: content ?? faker.lorem.sentences(random.nextInt(2) + 1).join(' '),
      senderId: generatedSender?.id ?? senderId ?? randomId,
      sender: generatedSender,
      read: read ?? false,
    );
  }
}
