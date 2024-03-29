import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/chat/models/message.dart';
import 'package:motis_mitfahr_app/chat/pages/chat_page.dart';
import 'package:motis_mitfahr_app/home/models/ride_event.dart';
import 'package:motis_mitfahr_app/home/pages/home_page.dart';
import 'package:motis_mitfahr_app/main_app.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';
import 'package:motis_mitfahr_app/trips/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/trips/pages/drive_detail_page.dart';
import 'package:motis_mitfahr_app/trips/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/trips/pages/search_ride_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test_util/factories/drive_factory.dart';
import '../test_util/factories/message_factory.dart';
import '../test_util/factories/model_factory.dart';
import '../test_util/factories/profile_factory.dart';
import '../test_util/factories/ride_event_factory.dart';
import '../test_util/factories/ride_factory.dart';
import '../test_util/mocks/mock_server.dart';
import '../test_util/mocks/request_processor.dart';
import '../test_util/mocks/request_processor.mocks.dart';
import '../test_util/pump_material.dart';

void main() {
  final Profile profile = ProfileFactory().generateFake(id: 1);
  final MockRequestProcessor processor = MockRequestProcessor();
  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    reset(processor);
    supabaseManager.currentProfile = profile;
  });

  testWidgets('Page has stream subscriptions', (WidgetTester tester) async {
    whenRequest(processor).thenReturnJson([]);
    await pumpMaterial(tester, const HomePage());
    verifyRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).called(1);
    verifyRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).called(1);
    verifyRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).called(1);
    verifyRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).called(1);

    final List<RealtimeChannel> subscriptions = supabaseManager.supabaseClient.getChannels();
    expect(subscriptions.length, 4);
    expect(subscriptions[0].topic, 'realtime:public:rides');
    expect(subscriptions[1].topic, 'realtime:public:drives');
    expect(subscriptions[2].topic, 'realtime:public:ride_events');
    expect(subscriptions[3].topic, 'realtime:public:messages');
  });

  testWidgets('Empty page', (WidgetTester tester) async {
    whenRequest(processor).thenReturnJson([]);
    await pumpMaterial(tester, const HomePage());
    await tester.pump();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(const Key('messagesColumn')), findsNothing);
    expect(find.byKey(const Key('rideEventsColumn')), findsNothing);
    expect(find.byKey(const Key('tripsColumn')), findsNothing);
    expect(find.byKey(const Key('emptyColumn')), findsOneWidget);
    expect(find.byKey(const Key('completeProfileColumn')), findsNothing);
  });

  testWidgets('Empty page with incomplete profile', (WidgetTester tester) async {
    supabaseManager.currentProfile = ProfileFactory().generateFake(
      id: 1,
      description: NullableParameter(null),
      birthDate: NullableParameter(null),
      firstName: NullableParameter(null),
      lastName: NullableParameter(null),
      gender: NullableParameter(null),
      avatarUrl: NullableParameter(null),
    );
    whenRequest(processor).thenReturnJson([]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/profiles'), methodMatcher: equals('GET'))
        .thenReturnJson(supabaseManager.currentProfile!.toJsonForApi());
    //We need a MainApp because we need to navigate to another tab
    await pumpMaterial(tester, MainApp());
    await tester.pump();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(const Key('messagesColumn')), findsNothing);
    expect(find.byKey(const Key('rideEventsColumn')), findsNothing);
    expect(find.byKey(const Key('tripsColumn')), findsNothing);
    expect(find.byKey(const Key('emptyColumn')), findsNothing);
    expect(find.byKey(const Key('completeProfileColumn')), findsOneWidget);

    final Finder completeProfileButton = find.byKey(const Key('completeProfileButton'));
    expect(completeProfileButton, findsOneWidget);

    await tester.tap(completeProfileButton);
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProfilePage), findsOneWidget);
  });

  group('RideEvent', () {
    testWidgets('Shows the right RideEvents (driver)', (WidgetTester tester) async {
      final Drive drive = DriveFactory().generateFake(driver: NullableParameter(profile));
      final Ride ride = RideFactory().generateFake(drive: NullableParameter(drive));

      final List<RideEvent> rideEvents = [
        for (RideEventCategory category in RideEventCategory.values)
          RideEventFactory().generateFake(
            read: false,
            ride: NullableParameter(ride),
            reason: category,
          )
      ];

      final List<RideEvent> relevantRideEvents = [
        for (RideEvent rideEvent in rideEvents)
          if (rideEvent.category == RideEventCategory.cancelledByRider ||
              rideEvent.category == RideEventCategory.pending ||
              rideEvent.category == RideEventCategory.withdrawn)
            rideEvent
      ];

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events'))
          .thenReturnJson(rideEvents.map((RideEvent rideEvent) => rideEvent.toJsonForApi()).toList());
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read')).thenReturnJson('');

      for (final RideEvent rideEvent in rideEvents) {
        whenRequest(
          processor,
          urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + rideEvent.rideId.toString())),
        ).thenReturnJson(ride.toJsonForApi());
      }
      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder finder = find.byType(Dismissible, skipOffstage: false);
      expect(finder, findsNWidgets(relevantRideEvents.length));

      for (final RideEvent rideEvent in relevantRideEvents) {
        expect(tester.widget(finder.at(relevantRideEvents.indexOf(rideEvent))).key, Key('rideEvent${rideEvent.id}'));
      }
    });

    testWidgets('Shows the right RideEvents (rider)', (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(rider: NullableParameter(profile));

      final List<RideEvent> rideEvents = [
        for (RideEventCategory category in RideEventCategory.values)
          RideEventFactory().generateFake(
            read: false,
            ride: NullableParameter(ride),
            reason: category,
          )
      ];

      final List<RideEvent> relevantRideEvents = [
        for (RideEvent rideEvent in rideEvents)
          if (rideEvent.category == RideEventCategory.approved ||
              rideEvent.category == RideEventCategory.cancelledByDriver ||
              rideEvent.category == RideEventCategory.rejected)
            rideEvent
      ];

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events'))
          .thenReturnJson(rideEvents.map((RideEvent rideEvent) => rideEvent.toJsonForApi()).toList());
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read')).thenReturnJson('');

      for (final RideEvent rideEvent in rideEvents) {
        whenRequest(
          processor,
          urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + rideEvent.rideId.toString())),
        ).thenReturnJson(ride.toJsonForApi());
      }
      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder finder = find.byType(Dismissible, skipOffstage: false);
      expect(finder, findsNWidgets(relevantRideEvents.length));

      for (final RideEvent rideEvent in relevantRideEvents) {
        expect(tester.widget(finder.at(relevantRideEvents.indexOf(rideEvent))).key, Key('rideEvent${rideEvent.id}'));
      }
    });

    testWidgets('can navigate to rideDetail if rideEvent is for ride', (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(rider: NullableParameter(profile));
      final RideEvent rideEvent = RideEventFactory().generateFake(
        read: false,
        ride: NullableParameter(ride),
        reason: RideEventCategory.approved,
      );

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([rideEvent.toJsonForApi()]);
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read')).thenReturnJson('');

      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + rideEvent.rideId.toString())),
      ).thenReturnJson(ride.toJsonForApi());
      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder rideEventFinder = find.byKey(Key('rideEvent${rideEvent.id}'));
      expect(rideEventFinder, findsOneWidget);

      await tester.tap(rideEventFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RideDetailPage), findsOneWidget);
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read'),
        bodyMatcher: equals({'ride_event_id': rideEvent.id}),
      ).called(1);
    });

    testWidgets('can navigate to driveDetail if rideEvent is for drive', (WidgetTester tester) async {
      final Drive drive = DriveFactory().generateFake(driver: NullableParameter(profile));
      final Ride ride = RideFactory().generateFake(drive: NullableParameter(drive));
      final RideEvent rideEvent = RideEventFactory().generateFake(
        read: false,
        ride: NullableParameter(ride),
        reason: RideEventCategory.pending,
      );

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([rideEvent.toJsonForApi()]);
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read')).thenReturnJson('');

      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.' + rideEvent.ride!.driveId.toString())),
      ).thenReturnJson(drive.toJsonForApi());
      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder rideEventFinder = find.byKey(Key('rideEvent${rideEvent.id}'));
      expect(rideEventFinder, findsOneWidget);

      await tester.tap(rideEventFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DriveDetailPage), findsOneWidget);
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read'),
        bodyMatcher: equals({'ride_event_id': rideEvent.id}),
      ).called(1);
    });
    testWidgets('can dismiss', (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(rider: NullableParameter(profile));
      final RideEvent rideEvent = RideEventFactory().generateFake(
        read: false,
        ride: NullableParameter(ride),
        reason: RideEventCategory.approved,
      );
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([rideEvent.toJsonForApi()]);
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read')).thenReturnJson('');

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder rideEventFinder = find.byKey(Key('rideEvent${rideEvent.id}'));
      expect(rideEventFinder, findsOneWidget);

      await tester.drag(rideEventFinder, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('rideEvent${rideEvent.id}')), findsNothing);
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/rpc/mark_ride_event_as_read'),
        bodyMatcher: equals({'ride_event_id': rideEvent.id}),
      ).called(1);
    });
    testWidgets('insertRideEvent', (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(rider: NullableParameter(profile));
      final RideEvent rideEvent =
          RideEventFactory().generateFake(ride: NullableParameter(ride), reason: RideEventCategory.approved);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);
      //the following request is for the rideEvent in the loadInsertRideEvent function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/ride_events.*&id=eq\.' + rideEvent.id.toString())),
      ).thenReturnJson(rideEvent.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.insertRideEvent(rideEvent.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('rideEvent${rideEvent.id}')), findsOneWidget);
    });

    testWidgets('updateRideEvent', (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(rider: NullableParameter(profile));
      final RideEvent rideEvent = RideEventFactory().generateFake(
        ride: NullableParameter(ride),
        read: false,
        reason: RideEventCategory.approved,
      );

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([rideEvent.toJsonForApi()]);

      rideEvent.read = true;
      //the following request is for the rideEvent in the updateRideEvent function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/ride_events.*&id=eq\.' + rideEvent.id.toString())),
      ).thenReturnJson(rideEvent.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);
      expect(find.byKey(Key('rideEvent${rideEvent.id}')), findsOneWidget);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.updateRideEvent(rideEvent.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('rideEvent${rideEvent.id}')), findsNothing);
    });
  });

  group('Messages', () {
    testWidgets('can navigate to chat', (WidgetTester tester) async {
      final Message message = MessageFactory().generateFake(read: false);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([message.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_message_as_read')).thenReturnJson('');

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder messageFinder = find.byKey(Key('message${message.id}'));
      expect(messageFinder, findsOneWidget);

      await tester.tap(messageFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
    });
    testWidgets('can dismiss', (WidgetTester tester) async {
      final Message message = MessageFactory().generateFake(read: false);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([message.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: equals('/rest/v1/rpc/mark_message_as_read')).thenReturnJson('');

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder messageFinder = find.byKey(Key('message${message.id}'));
      expect(messageFinder, findsOneWidget);

      await tester.drag(messageFinder, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('message${message.id}')), findsNothing);
      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/rpc/mark_message_as_read'),
        bodyMatcher: equals({'message_id': message.id}),
      ).called(1);
    });

    testWidgets('insertMessage', (WidgetTester tester) async {
      final Profile sender = ProfileFactory().generateFake(id: 2);
      final Message message = MessageFactory().generateFake(sender: NullableParameter(sender));

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      //the following request is for the message in the insertMessage function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/messages.*&id=eq\.' + message.id.toString())),
      ).thenReturnJson(message.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.insertMessage(message.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('message${message.id}')), findsOneWidget);
    });

    testWidgets('updateMessage', (WidgetTester tester) async {
      final Message message = MessageFactory().generateFake(read: false);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([message.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      message.read = true;
      //the following request is for the message in the updateMessage function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/messages.*&id=eq\.' + message.id.toString())),
      ).thenReturnJson(message.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);
      expect(find.byKey(Key('message${message.id}')), findsOneWidget);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.updateMessage(message.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('message${message.id}')), findsNothing);
    });
  });

  group('Ride', () {
    testWidgets('can navigate to driveDetail', (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(rider: NullableParameter(profile));

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([ride.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + ride.id.toString())),
      ).thenReturnJson(ride.toJsonForApi());
      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder rideFinder = find.byKey(Key('ride${ride.id}'));
      expect(rideFinder, findsOneWidget);

      await tester.tap(rideFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RideDetailPage), findsOneWidget);
    });

    testWidgets('updateRide inserts ride if status is approved and it starts today or tomorrow',
        (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(
        status: RideStatus.approved,
        rider: NullableParameter(profile),
        startDateTime: DateTime.now().add(const Duration(hours: 1)),
      );
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      //the following request is for the rides in the updateRide function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + ride.id.toString())),
      ).thenReturnJson(ride.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.updateRide(ride.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('ride${ride.id}')), findsOneWidget);
    });

    testWidgets('updateRide sorts correctly', (WidgetTester tester) async {
      final Ride ride1 = RideFactory().generateFake(
        status: RideStatus.approved,
        rider: NullableParameter(profile),
        startDateTime: DateTime.now(),
      );
      final Ride ride2 = RideFactory().generateFake(
        status: RideStatus.approved,
        rider: NullableParameter(profile),
        startDateTime: DateTime.now().add(const Duration(hours: 2)),
      );
      final Ride ride = RideFactory().generateFake(
        status: RideStatus.approved,
        rider: NullableParameter(profile),
        startDateTime: DateTime.now().add(const Duration(hours: 1)),
      );
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'))
          .thenReturnJson([ride1.toJsonForApi(), ride2.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      //the following request is for the rides in the updateRide function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + ride.id.toString())),
      ).thenReturnJson(ride.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.updateRide(ride.toJsonForApi());
      await tester.pumpAndSettle();

      final Finder finder = find.byType(Dismissible, skipOffstage: false);
      expect(finder, findsNWidgets(3));

      expect(tester.widget(finder.at(0)).key, Key('ride${ride1.id}'));
      expect(tester.widget(finder.at(1)).key, Key('ride${ride.id}'));
      expect(tester.widget(finder.at(2)).key, Key('ride${ride2.id}'));
    });

    testWidgets('updateRide removes ride if the status changes from approved to cancelled',
        (WidgetTester tester) async {
      final Ride ride = RideFactory().generateFake(
        status: RideStatus.approved,
        rider: NullableParameter(profile),
        startDateTime: DateTime.now().add(const Duration(hours: 1)),
      );
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([ride.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      ride.status = RideStatus.cancelledByDriver;
      //the following request is for the ride in the updateRide function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + ride.id.toString())),
      ).thenReturnJson(ride.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);
      expect(find.byKey(Key('ride${ride.id}')), findsOneWidget);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.updateRide(ride.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('ride${ride.id}')), findsNothing);
    });
  });

  group('Drives', () {
    testWidgets('can navigate to driveDetail', (WidgetTester tester) async {
      final Drive drive = DriveFactory().generateFake(driver: NullableParameter(profile));

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([drive.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.' + drive.id.toString())),
      ).thenReturnJson(drive.toJsonForApi());
      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder driveFinder = find.byKey(Key('drive${drive.id}'));
      expect(driveFinder, findsOneWidget);

      await tester.tap(driveFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DriveDetailPage), findsOneWidget);
    });
    testWidgets('insertDrive', (WidgetTester tester) async {
      final Drive drive = DriveFactory().generateFake(
        driver: NullableParameter(profile),
        startDateTime: DateTime.now().add(const Duration(hours: 1)),
      );

      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      //the following request is for the drive in the insertDrive function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.' + drive.id.toString())),
      ).thenReturnJson(drive.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.insertDrive(drive.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('drive${drive.id}')), findsOneWidget);
    });

    testWidgets('updateDrive', (WidgetTester tester) async {
      final Drive drive = DriveFactory().generateFake(
        driver: NullableParameter(profile),
        startDateTime: DateTime.now().add(const Duration(hours: 1)),
        status: DriveStatus.plannedOrFinished,
      );
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([drive.toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

      drive.status = DriveStatus.cancelledByDriver;
      //the following request is for the drive in the updateDrive function
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.' + drive.id.toString())),
      ).thenReturnJson(drive.toJsonForApi());

      await pumpMaterial(tester, const HomePage());
      await tester.pump();

      final Finder homepage = find.byType(HomePage);
      expect(find.byKey(Key('drive${drive.id}')), findsOneWidget);

      final HomePageState homepageState = tester.state(homepage);
      homepageState.updateDrive(drive.toJsonForApi());
      await tester.pumpAndSettle();

      expect(find.byKey(Key('drive${drive.id}')), findsNothing);
    });
  });

  testWidgets('can dismiss trip ', (WidgetTester tester) async {
    // testing the dismiss for a drive is enough since it is the same for a ride
    final Drive drive = DriveFactory().generateFake(
      driver: NullableParameter(profile),
      startDateTime: DateTime.now().add(const Duration(hours: 1)),
    );
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([drive.toJsonForApi()]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides')).thenReturnJson([]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([]);

    await pumpMaterial(tester, const HomePage());
    await tester.pump();

    final Finder driveFinder = find.byKey(Key('drive${drive.id}'));
    expect(driveFinder, findsOneWidget);

    await tester.drag(driveFinder, const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('drive${drive.id}')), findsNothing);
  });

  testWidgets('works with multiple events', (WidgetTester tester) async {
    final Drive driveToday = DriveFactory().generateFake(
      driver: NullableParameter(profile),
      startDateTime: DateTime.now(),
    );
    final Drive driveTomorrow = DriveFactory().generateFake(
      driver: NullableParameter(profile),
      startDateTime: DateTime.now().add(const Duration(days: 1)),
    );
    final Ride rideToday = RideFactory().generateFake(
      rider: NullableParameter(profile),
      startDateTime: DateTime.now(),
    );
    final Ride rideTomorrow = RideFactory().generateFake(
      rider: NullableParameter(profile),
      startDateTime: DateTime.now().add(const Duration(days: 1)),
    );
    final Message message = MessageFactory().generateFake(createdAt: DateTime.now().subtract(const Duration(hours: 2)));
    final Message message2 = MessageFactory().generateFake(createdAt: DateTime.now());
    final RideEvent rideEvent = RideEventFactory().generateFake(
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ride: NullableParameter(rideToday),
      reason: RideEventCategory.approved,
    );

    whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives')).thenReturnJson([driveToday.toJsonForApi()]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages')).thenReturnJson([message.toJsonForApi()]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'))
        .thenReturnJson([rideToday.toJsonForApi(), rideTomorrow.toJsonForApi()]);
    whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events')).thenReturnJson([rideEvent.toJsonForApi()]);

    whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/messages.*&id=eq\.' + message2.id.toString())))
        .thenReturnJson(message2.toJsonForApi());
    whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.' + driveTomorrow.id.toString())))
        .thenReturnJson(driveTomorrow.toJsonForApi());
    whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/rides.*&id=eq\.' + rideTomorrow.id.toString())))
        .thenReturnJson(rideTomorrow.toJsonForApi());

    await pumpMaterial(tester, const HomePage());
    await tester.pump();

    final HomePageState homepageState = tester.state(find.byType(HomePage));

    expect(find.byKey(const Key('messagesColumn')), findsOneWidget);
    expect(find.byKey(const Key('rideEventsColumn')), findsOneWidget);
    expect(find.byKey(const Key('tripsColumn')), findsOneWidget);
    expect(find.byKey(const Key('emptyColumn')), findsNothing);
    expect(find.byKey(const Key('completeProfileColumn')), findsNothing);

    final Finder finder = find.byType(Dismissible, skipOffstage: false);
    expect(finder, findsNWidgets(5));

    expect(tester.widget(finder.at(0)).key, Key('drive${driveToday.id}'));
    expect(tester.widget(finder.at(1)).key, Key('ride${rideToday.id}'));
    expect(tester.widget(finder.at(2)).key, Key('ride${rideTomorrow.id}'));
    expect(tester.widget(finder.at(3)).key, Key('rideEvent${rideEvent.id}'));
    expect(tester.widget(finder.at(4)).key, Key('message${message.id}'));

    homepageState.insertMessage(message2.toJsonForApi());
    homepageState.insertDrive(driveTomorrow.toJsonForApi());
    await tester.pumpAndSettle();

    expect(finder, findsNWidgets(7));

    expect(tester.widget(finder.at(5)).key, Key('message${message2.id}'));
    expect(tester.widget(finder.at(2)).key, Key('drive${driveTomorrow.id}'));
  });

  group('Buttons', () {
    setUp(() => whenRequest(processor).thenReturnJson([]));
    testWidgets('checks SearchRideButton Button', (WidgetTester tester) async {
      //We need a MainApp because we need to navigate to another tab
      await pumpMaterial(tester, MainApp());
      await tester.pump();

      await tester.tap(find.byKey(const Key('SearchButton')));
      await tester.pumpAndSettle();
      expect(find.byType(SearchRidePage), findsOneWidget);
    });

    testWidgets('checks CreateDrive Button', (WidgetTester tester) async {
      //We need a MainApp because we need to navigate to another tab
      await pumpMaterial(tester, MainApp());

      await tester.tap(find.byKey(const Key('CreateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateDrivePage), findsOneWidget);
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/drives'))
          .thenReturnJson([DriveFactory().generateFake().toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/messages'))
          .thenReturnJson([MessageFactory().generateFake().toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/rides'))
          .thenReturnJson([RideFactory().generateFake().toJsonForApi()]);
      whenRequest(processor, urlMatcher: startsWith('/rest/v1/ride_events'))
          .thenReturnJson([RideEventFactory().generateFake().toJsonForApi()]);
      await expectMeetsAccessibilityGuidelines(tester, const HomePage());
    });
  });
}
