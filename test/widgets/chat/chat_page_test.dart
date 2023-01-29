import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/util/chat/chat_bubble.dart';
import 'package:motis_mitfahr_app/util/chat/message_bar.dart';
import 'package:motis_mitfahr_app/util/chat/pages/chat_page.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/factories/message_factory.dart';
import '../../util/factories/profile_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  final MockRequestProcessor processor = MockRequestProcessor();
  final Profile profile = ProfileFactory().generateFake(id: 1);
  const int chatId = 1;

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  testWidgets('Page has stream subscription', (WidgetTester tester) async {
    whenRequest(processor).thenReturnJson([]);
    await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));

    verifyRequest(
      processor,
      urlMatcher: equals('/rest/v1/messages?select=%2A&chat_id=eq.$chatId&order=created_at.desc.nullslast'),
    ).called(1);
    final List<RealtimeChannel> subscription = SupabaseManager.supabaseClient.getChannels();
    expect(subscription.length, 1);
    expect(subscription[0].topic, 'realtime:public:messages:1');
  });

  testWidgets('shows ProfileWidget of given Profile', (WidgetTester tester) async {
    await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));

    final Finder profileWidgetFinder = find.byType(ProfileWidget);
    expect(profileWidgetFinder, findsOneWidget);
    final ProfileWidget profileWidget = tester.widget(profileWidgetFinder);
    expect(profileWidget.profile, profile);
  });

  group('MessageBar', () {
    setUp(() => whenRequest(processor).thenReturnJson([]));

    testWidgets('is shown when Active', (WidgetTester tester) async {
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      expect(find.byType(MessageBar), findsOneWidget);
    });

    testWidgets('is not shown when not Active', (WidgetTester tester) async {
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId, active: false));
      await tester.pump();

      expect(find.byType(MessageBar), findsNothing);
    });

    testWidgets('can send Message', (WidgetTester tester) async {
      final Profile profile = ProfileFactory().generateFake();
      SupabaseManager.setCurrentProfile(profile);
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      final Finder messageBar = find.byType(MessageBar);
      expect(messageBar, findsOneWidget);
      final textField = find.descendant(of: messageBar, matching: find.byType(TextFormField));
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Hello World');
      await tester.tap(find.byType(IconButton));
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/messages'),
        methodMatcher: equals('POST'),
        bodyMatcher: equals({
          'chat_id': chatId,
          'content': 'Hello World',
          'sender_id': profile.id,
        }),
      ).called(1);
    });
  });

  group('ChatBubbles', () {
    testWidgets('are shown', (WidgetTester tester) async {
      whenRequest(processor).thenReturnJson([
        MessageFactory().generateFake().toJsonForApi(),
        MessageFactory().generateFake().toJsonForApi(),
        MessageFactory().generateFake().toJsonForApi(),
        MessageFactory().generateFake().toJsonForApi(),
        MessageFactory().generateFake().toJsonForApi(),
        MessageFactory().generateFake().toJsonForApi(),
      ]);
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      expect(find.byType(ChatBubble), findsNWidgets(6));
    });

    testWidgets('are not when there are no messages', (WidgetTester tester) async {
      whenRequest(processor).thenReturnJson([]);
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      expect(find.byType(ChatBubble), findsNothing);
    });

    testWidgets('shows Icon.done_all when message is from current user', (WidgetTester tester) async {
      whenRequest(processor).thenReturnJson([
        MessageFactory().generateFake(senderId: profile.id).toJsonForApi(),
      ]);
      SupabaseManager.setCurrentProfile(profile);
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      final Finder chatBubble = find.byType(ChatBubble);
      expect(chatBubble, findsOneWidget);
      expect(find.descendant(of: chatBubble, matching: find.byIcon(Icons.done_all)), findsOneWidget);
    });

    testWidgets('shows Icon.done_all not when message is from other user', (WidgetTester tester) async {
      whenRequest(processor).thenReturnJson([
        MessageFactory().generateFake(senderId: profile.id! + 1).toJsonForApi(),
      ]);
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      final Finder chatBubble = find.byType(ChatBubble);
      expect(chatBubble, findsOneWidget);
      expect(find.descendant(of: chatBubble, matching: find.byIcon(Icons.done_all)), findsNothing);
    });

    testWidgets('shows tail exactly when it should be shown', (WidgetTester tester) async {
      final Profile currentProfile = ProfileFactory().generateFake();
      SupabaseManager.setCurrentProfile(currentProfile);
      final List<Map<String, dynamic>> messages = [
        MessageFactory()
            .generateFake(
              senderId: profile.id,
              createdAt: DateTime.now(),
              content: 'newest Message from other user',
            ) // has Tail
            .toJsonForApi(),
        MessageFactory()
            .generateFake(
              senderId: currentProfile.id,
              createdAt: DateTime.now().subtract(const Duration(seconds: 1)),
              content: 'Message from current user',
            ) // has Tail
            .toJsonForApi(),
        MessageFactory()
            .generateFake(
              senderId: profile.id,
              createdAt: DateTime.now().subtract(const Duration(seconds: 2)),
              content: 'Message from other User',
            ) // has Tail
            .toJsonForApi(),
        MessageFactory()
            .generateFake(
              senderId: profile.id,
              createdAt: DateTime.now().subtract(const Duration(seconds: 3)),
              content: 'another Message from other User',
            ) // does not have Tail
            .toJsonForApi(),
        MessageFactory()
            .generateFake(
              senderId: currentProfile.id,
              createdAt: DateTime.now().subtract(const Duration(seconds: 4)),
              content: 'Message from current User',
            ) // has Tail
            .toJsonForApi(),
        MessageFactory()
            .generateFake(
              senderId: currentProfile.id,
              createdAt: DateTime.now().subtract(const Duration(seconds: 5)),
              content: 'another Message from current User',
            ) // does not have Tail
            .toJsonForApi(),
        MessageFactory()
            .generateFake(
              senderId: currentProfile.id,
              createdAt: DateTime.now().subtract(const Duration(seconds: 6)),
              content: 'a third Message from current User',
            ) // does not have Tail
            .toJsonForApi(),
      ];
      whenRequest(processor).thenReturnJson(messages);
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      final Finder chatBubbles = find.byType(ChatBubble);
      expect(chatBubbles, findsNWidgets(7));
      expect(chatBubbles.evaluate().map((e) => e.widget as ChatBubble).map((e) => e.tail).toList(),
          [true, true, true, false, true, false, false]);
    });
  });
}
