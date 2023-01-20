import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/chat_factory.dart';
import '../util/factories/message_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/ride_factory.dart';

void main() {
  group('getUnreadMessagesCount', (() {
    Profile? profile = ProfileFactory().generateFake();
    int profileId = profile.id!;
    Message readTrueFromUser = MessageFactory().generateFake(
      read: true,
      senderId: profileId,
      createDependencies: false,
    );
    Message readTrueFromOther = MessageFactory().generateFake(
      read: true,
      senderId: profileId + 1,
      createDependencies: false,
    );
    Message readFalseFromUser = MessageFactory().generateFake(
      read: false,
      senderId: profileId,
      createDependencies: false,
    );
    Message readFalseFromOther = MessageFactory().generateFake(
      read: false,
      senderId: profileId + 1,
      createDependencies: false,
    );
    SupabaseManager.setCurrentProfile(profile);
    test('zero when Messages are null', () async {
      final chat = ChatFactory().generateFake(
        messages: NullableParameter(null),
      );
      expect(chat.getUnreadMessagesCount(), 0);
    });
    test('zero when Messages are empty', () async {
      final chat = ChatFactory().generateFake(
        messages: NullableParameter([]),
      );
      expect(chat.getUnreadMessagesCount(), 0);
    });
    test('zero when Messages are read', () async {
      final chat = ChatFactory().generateFake(
        messages: NullableParameter(
          [
            readTrueFromUser,
            readTrueFromOther,
          ],
        ),
      );
      expect(chat.getUnreadMessagesCount(), 0);
    });
    test('zero when Message is unread but from user', () async {
      final chat = ChatFactory().generateFake(
        messages: NullableParameter(
          [
            readFalseFromUser,
          ],
        ),
      );
      expect(chat.getUnreadMessagesCount(), 0);
    });

    test('one when Message is unread and not from user', () async {
      final chat = ChatFactory().generateFake(
        messages: NullableParameter(
          [
            readFalseFromOther,
          ],
        ),
      );
      expect(chat.getUnreadMessagesCount(), 1);
    });

    test('two when two Messages are unread and not from user', () async {
      final chat = ChatFactory().generateFake(
        messages: NullableParameter([
          readFalseFromOther,
          readFalseFromOther,
        ]),
      );
      expect(chat.getUnreadMessagesCount(), 2);
    });
  }));

  group('Chat.fromJson', () {
    test('parses a Chat from json', () {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-01-01T00:00:00.000Z",
        "ride_id": 2,
        "drive_id": 3,
      };
      Chat chat = Chat.fromJson(json);
      expect(chat.id, json["id"]);
      expect(chat.createdAt, DateTime.parse(json["created_at"]));
      expect(chat.rideId, json["ride_id"]);
      expect(chat.driveId, json["drive_id"]);
    });

    test('can handle associated Modles', (() {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-01-01T00:00:00.000Z",
        "ride_id": 2,
        "drive_id": 3,
        "ride": RideFactory().generateFake().toJsonForApi(),
        "messages": [
          MessageFactory().generateFake().toJsonForApi(),
          MessageFactory().generateFake().toJsonForApi(),
        ],
      };
      Chat chat = Chat.fromJson(json);
      expect(chat.ride, isNotNull);
      expect(chat.messages, isNotNull);
      expect(chat.messages!.length, 2);
    }));
  });

  group('Chat.fromJsonList', (() {
    test('parses a List of Chats from json', () {
      Map<String, dynamic> json = {
        "id": 1,
        "created_at": "2021-01-01T00:00:00.000Z",
        "ride_id": 2,
        "drive_id": 3,
      };
      List<Chat> chats = Chat.fromJsonList([json, json, json]);
      expect(chats.length, 3);
      expect(chats[0].id, json["id"]);
      expect(chats[2].createdAt, DateTime.parse(json["created_at"]));
      expect(chats[1].rideId, json["ride_id"]);
      expect(chats[0].driveId, json["drive_id"]);
    });

    test('can handle empty List', (() {
      List<Chat> chats = Chat.fromJsonList([]);
      expect(chats.length, 0);
    }));
  }));

  group('Chat.toJson', () {
    test('parses a Chat to json', () {
      Chat chat = ChatFactory().generateFake();
      Map<String, dynamic> json = chat.toJson();
      expect(json["ride_id"], chat.rideId);
      expect(json["drive_id"], chat.driveId);
      expect(json.keys.length, 2);
    });
  });

  group('Chat.toString', () {
    test('parses a Chat to String', () {
      Chat chat = ChatFactory().generateFake();
      String string = chat.toString();
      expect(string,
          "Chat{id: ${chat.id}, createdAt: ${chat.createdAt}, rideId: ${chat.rideId}, driveId: ${chat.driveId}}");
    });
  });
}
