import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/chat/models/chat.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

import '../util/factories/chat_factory.dart';
import '../util/factories/message_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/mock_server.dart';

void main() {
  final UrlProcessor messageProcessor = UrlProcessor();

  //setup muss in jeder Testklasse einmal aufgerufen werden
  setUp(() async {
    MockServer.setProcessor(messageProcessor);
  });
  group('markAsRead', () {
    test('marks message as read', () async {
      final message = MessageFactory().generateFake(
        read: false,
      );
      await message.markAsRead();
      SupabaseManager.supabaseClient.from('messages').update({
        'read': true,
      }).eq('id', message.id);
      expect(message.read, true);
    });
  });

  group('Message.isFromCurrentUser', () {
    setUp(() {
      final profile = ProfileFactory().generateFake();
      SupabaseManager.setCurrentProfile(profile);
    });
    test('returns true if message is from current user', () async {
      final message = MessageFactory().generateFake(
        senderId: SupabaseManager.getCurrentProfile()?.id,
      );
      expect(message.isFromCurrentUser, true);
    });
    test('returns false if message is not from current user', () async {
      final message = MessageFactory().generateFake(
        senderId: SupabaseManager.getCurrentProfile()!.id! + 1,
      );
      expect(message.isFromCurrentUser, false);
    });

    test('returns false if current user is null', () async {
      SupabaseManager.setCurrentProfile(null);
      final message = MessageFactory().generateFake();
      expect(message.isFromCurrentUser, false);
    });
  });

  group('Message.fromJson', () {
    test('parses a message from json', () async {
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'chat_id': 1,
        'content': 'content',
        'sender_id': 1,
        'read': true,
      };
      final message = Message.fromJson(json);
      expect(message.id, 1);
      expect(message.createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(message.chatId, 1);
      expect(message.content, 'content');
      expect(message.senderId, 1);
      expect(message.read, true);
    });

    test('can handel associated models', () {
      final Chat chat = ChatFactory().generateFake();
      final Profile profile = ProfileFactory().generateFake();
      final Map<String, dynamic> json = {
        'id': 1,
        'created_at': '2021-01-01T00:00:00.000Z',
        'chat_id': 1,
        'chat': chat.toJsonForApi(),
        'content': 'content',
        'sender_id': 1,
        'sender': profile.toJsonForApi(),
        'read': true,
      };
      final message = Message.fromJson(json);
      expect(message.chat.toString(), chat.toString());
      expect(message.sender.toString(), profile.toString());
    });
  });

  group('Message.fromJsonList', () {
    test('parses a list of messages from json', () async {
      final List<Map<String, dynamic>> json = [
        {
          'id': 1,
          'created_at': '2021-01-01T00:00:00.000Z',
          'chat_id': 1,
          'content': 'content',
          'sender_id': 1,
          'read': true,
        },
        {
          'id': 2,
          'created_at': '2021-01-01T00:00:00.000Z',
          'chat_id': 1,
          'content': 'content',
          'sender_id': 1,
          'read': true,
        },
      ];
      final messages = Message.fromJsonList(json);
      expect(messages.length, 2);
      expect(messages[0].id, 1);
      expect(messages[0].createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(messages[0].chatId, 1);
      expect(messages[0].content, 'content');
      expect(messages[0].senderId, 1);
      expect(messages[0].read, true);
      expect(messages[1].id, 2);
      expect(messages[1].createdAt, DateTime.parse('2021-01-01T00:00:00.000Z'));
      expect(messages[1].chatId, 1);
      expect(messages[1].content, 'content');
      expect(messages[1].senderId, 1);
      expect(messages[1].read, true);
    });

    test('parses an empty list of messages from json', () async {
      final List<Map<String, dynamic>> json = [];
      final messages = Message.fromJsonList(json);
      expect(messages.length, 0);
    });
  });

  group('Message.toJson', () {
    test('converts a message to json', () async {
      final message = MessageFactory().generateFake();
      final json = message.toJson();
      expect(json['chat_id'], message.chatId);
      expect(json['content'], message.content);
      expect(json['sender_id'], message.senderId);
      expect(json['read'], message.read);
      expect(json.keys.length, 4);
    });
  });

  group('Message.toString', () {
    test('converts a message to string', () async {
      final message = MessageFactory().generateFake();
      final string = message.toString();
      expect(string,
          'Message{id: ${message.id}, createdAt: ${message.createdAt}, chatId: ${message.chatId}, senderId: ${message.senderId}, content: ${message.content}, read: ${message.read}}');
    });
  });
}
