import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_widget.dart';
import 'package:motis_mitfahr_app/chat/pages/chat_page.dart';
import 'package:motis_mitfahr_app/chat/util/chat_bubble.dart';
import 'package:motis_mitfahr_app/chat/util/message_bar.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_util/factories/message_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

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
    final List<RealtimeChannel> subscription = supabaseManager.supabaseClient.getChannels();
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
    final Finder messageBarFinder = find.byType(MessageBar);

    setUp(() => whenRequest(processor).thenReturnJson([]));

    testWidgets('is shown when Active', (WidgetTester tester) async {
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
      await tester.pump();

      expect(messageBarFinder, findsOneWidget);
    });

    testWidgets('is not shown when not Active', (WidgetTester tester) async {
      await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId, active: false));
      await tester.pump();

      expect(messageBarFinder, findsNothing);
    });

    group('sending messages', () {
      final Profile profile = ProfileFactory().generateFake(id: 1);
      const String message = 'Hello World';

      Future<void> setUpMessageBar(WidgetTester tester) async {
        supabaseManager.currentProfile = profile;
        await pumpMaterial(tester, ChatPage(profile: profile, chatId: chatId));
        await tester.pump();

        final textField = find.descendant(of: messageBarFinder, matching: find.byType(TextFormField));
        await tester.enterText(textField, message);
      }

      void verifyRequestSent() {
        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/messages'),
          methodMatcher: equals('POST'),
          bodyMatcher: equals({
            'chat_id': chatId,
            'content': message,
            'sender_id': profile.id,
          }),
        ).called(1);
      }

      testWidgets('can send message by clicking the Send Icon', (WidgetTester tester) async {
        await setUpMessageBar(tester);

        await tester.tap(find.byType(IconButton));

        verifyRequestSent();
      });

      testWidgets('can send message by closing the keyboard', (WidgetTester tester) async {
        await setUpMessageBar(tester);

        await tester.testTextInput.receiveAction(TextInputAction.done);

        verifyRequestSent();
      });
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
      supabaseManager.currentProfile = profile;
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
      supabaseManager.currentProfile = currentProfile;
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

  testWidgets('Accessibility', (WidgetTester tester) async {
    await expectMeetsAccessibilityGuidelines(tester, ChatPage(profile: profile, chatId: chatId));
  });
}
