import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/drives/pages/drive_chat_page.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/chat/models/message.dart';
import 'package:motis_mitfahr_app/util/chat/pages/chat_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/factories/chat_factory.dart';
import '../../util/factories/drive_factory.dart';
import '../../util/factories/message_factory.dart';
import '../../util/factories/model_factory.dart';
import '../../util/factories/profile_factory.dart';
import '../../util/factories/ride_factory.dart';
import '../../util/mock_server.dart';
import '../../util/pump_material.dart';
import '../../util/request_processor.dart';
import '../../util/request_processor.mocks.dart';

void main() {
  late Drive drive;
  final MockRequestProcessor processor = MockRequestProcessor();
  final Profile profile = ProfileFactory().generateFake(id: 1);

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  group('Has Stream Subscription', () {
    setUp(() async {
      whenRequest(processor).thenReturnJson([]);
    });

    testWidgets('when Drive has rides with active chat', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [
          RideFactory().generateFake(status: RideStatus.approved),
          RideFactory().generateFake(status: RideStatus.pending),
        ],
      );
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/messages?select=%2A&order=created_at.desc.nullslast'),
      ).called(1);
      final List<RealtimeChannel> subscription = SupabaseManager.supabaseClient.getChannels();
      expect(subscription.length, 1);
      expect(subscription[0].topic, 'realtime:public:messages:1');
    });

    testWidgets('not when Drive has no rides', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [],
      );
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      verifyRequestNever(
        processor,
        urlMatcher: equals('/rest/v1/messages?select=%2A&order=created_at.desc.nullslast'),
      );
      final List<RealtimeChannel> subscription = SupabaseManager.supabaseClient.getChannels();
      expect(subscription.length, 0);
    });

    testWidgets('not when Drive has rides without active chat', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [
          RideFactory().generateFake(status: RideStatus.pending),
          RideFactory().generateFake(status: RideStatus.rejected),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
        ],
      );
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      verifyRequestNever(
        processor,
        urlMatcher: equals('/rest/v1/messages?select=%2A&order=created_at.desc.nullslast'),
      );
      final List<RealtimeChannel> subscription = SupabaseManager.supabaseClient.getChannels();
      expect(subscription.length, 0);
    });
  });

  testWidgets('Shows chats from Rides that have a active Chat', (WidgetTester tester) async {
    drive = DriveFactory().generateFake(
      driverId: profile.id,
      rides: [
        RideFactory().generateFake(status: RideStatus.approved),
        RideFactory().generateFake(status: RideStatus.cancelledByDriver),
        RideFactory().generateFake(status: RideStatus.cancelledByRider),
      ],
    );
    whenRequest(processor).thenReturnJson([]);
    await pumpMaterial(tester, DriveChatPage(drive: drive));
    await tester.pump();

    expect(find.byKey(Key('chatWidget${drive.rides![0].chatId}')), findsOneWidget);
    expect(find.byKey(Key('chatWidget${drive.rides![1].chatId}')), findsOneWidget);
    expect(find.byKey(Key('chatWidget${drive.rides![2].chatId}')), findsOneWidget);
  });

  group('Shows Chats image when', () {
    testWidgets('there are no rides with an active chat', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [
          RideFactory().generateFake(status: RideStatus.pending),
          RideFactory().generateFake(status: RideStatus.rejected),
          RideFactory().generateFake(status: RideStatus.withdrawnByRider),
        ],
      );
      whenRequest(processor).thenReturnJson([]);
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      expect(find.byKey(Key('chatWidget${drive.rides![0].chatId}')), findsNothing);
      expect(find.byKey(Key('chatWidget${drive.rides![1].chatId}')), findsNothing);
      expect(find.byKey(Key('chatWidget${drive.rides![2].chatId}')), findsNothing);
      expect(find.byKey(const Key('noChatsImage')), findsOneWidget);
    });

    testWidgets('there are no rides', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [],
      );
      whenRequest(processor).thenReturnJson([]);
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      expect(find.byKey(const Key('noChatsImage')), findsOneWidget);
    });
  });

  group('ChatWidget', () {
    testWidgets('shows Avatar of Rider', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [RideFactory().generateFake(status: RideStatus.approved)],
      );
      whenRequest(processor).thenReturnJson([]);
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      final Finder chatWidget = find.byKey(Key('chatWidget${drive.rides![0].chatId}'));
      expect(chatWidget, findsOneWidget);
      final Finder avatar = find.descendant(of: chatWidget, matching: find.byType(Avatar));
      expect(avatar, findsOneWidget);
      final Avatar avatarWidget = tester.widget(avatar);
      expect(avatarWidget.profile.id, drive.rides![0].rider!.id);
    });

    group('last Message', () {
      testWidgets('is shown when chat has Messages', (WidgetTester tester) async {
        final Message message = MessageFactory().generateFake();
        drive = DriveFactory().generateFake(
          driverId: profile.id,
          rides: [
            RideFactory().generateFake(
              chat: NullableParameter(
                ChatFactory().generateFake(
                  messages: NullableParameter([message]),
                ),
              ),
              status: RideStatus.approved,
            ),
          ],
        );
        whenRequest(processor).thenReturnJson([MessageFactory().generateFake().toJsonForApi()]);
        await pumpMaterial(tester, DriveChatPage(drive: drive));
        await tester.pump();

        final Finder subtitle = find.byKey(Key('chatWidget${drive.rides![0].chatId}Subtitle'));
        expect(subtitle, findsOneWidget);
        expect(find.descendant(of: subtitle, matching: find.text(message.content)), findsOneWidget);
      });
      testWidgets('is not shown when Chat has no messages', (WidgetTester tester) async {
        drive = DriveFactory().generateFake(
          driverId: profile.id,
          rides: [
            RideFactory().generateFake(
              chat: NullableParameter(
                ChatFactory().generateFake(
                  messages: NullableParameter([]),
                ),
              ),
              status: RideStatus.approved,
            ),
          ],
        );
        whenRequest(processor).thenReturnJson([]);
        await pumpMaterial(tester, DriveChatPage(drive: drive));
        await tester.pump();

        expect(find.byKey(Key('chatWidget${drive.rides![0].chatId}Subtitle')), findsNothing);
      });
    });
    group('Icon.done_all', () {
      setUp(() {
        SupabaseManager.setCurrentProfile(profile);
      });
      testWidgets('is shown when last Message is from current user', (WidgetTester tester) async {
        final Message message = MessageFactory().generateFake(
          senderId: profile.id,
        );
        drive = DriveFactory().generateFake(
          driverId: profile.id,
          rides: [
            RideFactory().generateFake(
              chat: NullableParameter(
                ChatFactory().generateFake(
                  messages: NullableParameter([message]),
                ),
              ),
              status: RideStatus.approved,
            ),
          ],
        );
        whenRequest(processor).thenReturnJson([message.toJsonForApi()]);
        await pumpMaterial(tester, DriveChatPage(drive: drive));
        await tester.pump();

        final Finder subtitle = find.byKey(Key('chatWidget${drive.rides![0].chatId}Subtitle'));
        expect(subtitle, findsOneWidget);
        expect(find.descendant(of: subtitle, matching: find.byIcon(Icons.done_all)), findsOneWidget);
      });
      testWidgets('is not shown when last Message is not from current User', (WidgetTester tester) async {
        final Message message = MessageFactory().generateFake(
          senderId: profile.id! + 1,
        );
        drive = DriveFactory().generateFake(
          driverId: profile.id,
          rides: [
            RideFactory().generateFake(
              chat: NullableParameter(
                ChatFactory().generateFake(
                  messages: NullableParameter([message]),
                ),
              ),
              status: RideStatus.approved,
            ),
          ],
        );
        whenRequest(processor).thenReturnJson([message.toJsonForApi()]);
        await pumpMaterial(tester, DriveChatPage(drive: drive));
        await tester.pump();

        final Finder subtitle = find.byKey(Key('chatWidget${drive.rides![0].chatId}Subtitle'));
        expect(subtitle, findsOneWidget);
        expect(find.descendant(of: subtitle, matching: find.byIcon(Icons.done_all)), findsNothing);
      });
    });
    group('shows unreadMessage count', () {
      setUp(() {
        SupabaseManager.setCurrentProfile(profile);
      });

      testWidgets('when there are unread Messages', (WidgetTester tester) async {
        final Message message = MessageFactory().generateFake(
          senderId: profile.id! + 1,
          read: false,
        );
        drive = DriveFactory().generateFake(
          driverId: profile.id,
          rides: [
            RideFactory().generateFake(
              chat: NullableParameter(
                ChatFactory().generateFake(
                  messages: NullableParameter([message]),
                ),
              ),
              status: RideStatus.approved,
            ),
          ],
        );
        whenRequest(processor).thenReturnJson([message.toJsonForApi()]);
        await pumpMaterial(tester, DriveChatPage(drive: drive));
        await tester.pump();
        final Finder unreadMessageWidget = find.byKey(Key('chatWidget${drive.rides![0].chatId}UnreadMessageCount'));
        expect(unreadMessageWidget, findsOneWidget);
        expect(
            find.descendant(
                of: unreadMessageWidget,
                matching: find.text(drive.rides![0].chat!.getUnreadMessagesCount().toString())),
            findsOneWidget);
      });

      testWidgets('not when there are no unread Messages', (WidgetTester tester) async {
        final Message message = MessageFactory().generateFake(
          senderId: profile.id! + 1,
          read: true,
        );
        drive = DriveFactory().generateFake(
          driverId: profile.id,
          rides: [
            RideFactory().generateFake(
              chat: NullableParameter(
                ChatFactory().generateFake(
                  messages: NullableParameter([message]),
                ),
              ),
              status: RideStatus.approved,
            ),
          ],
        );
        whenRequest(processor).thenReturnJson([message.toJsonForApi()]);
        await pumpMaterial(tester, DriveChatPage(drive: drive));
        await tester.pump();

        final Finder unreadMessageWidget = find.byKey(Key('chatWidget${drive.rides![0].chatId}UnreadMessageCount'));
        expect(unreadMessageWidget, findsNothing);
      });
    });

    testWidgets('can Navigate to ChatPage with Rider', (WidgetTester tester) async {
      drive = DriveFactory().generateFake(
        driverId: profile.id,
        rides: [
          RideFactory().generateFake(
            chatId: 1,
            status: RideStatus.approved,
            rider: NullableParameter(profile),
          ),
        ],
      );
      whenRequest(processor).thenReturnJson([]);
      await pumpMaterial(tester, DriveChatPage(drive: drive));
      await tester.pump();

      final Finder chatWidget = find.byKey(Key('chatWidget${drive.rides![0].chatId}'));
      expect(chatWidget, findsOneWidget);
      await tester.tap(chatWidget);
      await tester.pumpAndSettle();

      final Finder chatPageFinder = find.byType(ChatPage);
      expect(chatPageFinder, findsOneWidget);
      final ChatPage chatPage = tester.widget(chatPageFinder);
      expect(chatPage.chatId, drive.rides![0].chatId);
      expect(chatPage.profile.id, drive.rides![0].rider!.id);
    });
  });
}
