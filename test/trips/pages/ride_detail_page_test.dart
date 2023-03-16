import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/widgets/features_column.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_chip.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_widget.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_wrap_list.dart';
import 'package:motis_mitfahr_app/account/widgets/reviews_preview.dart';
import 'package:motis_mitfahr_app/chat/pages/chat_page.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/reviews/pages/write_review_page.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';
import 'package:motis_mitfahr_app/trips/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/trips/util/trip_overview.dart';
import 'package:motis_mitfahr_app/util/buttons/custom_banner.dart';
import 'package:motis_mitfahr_app/welcome/pages/login_page.dart';
import 'package:motis_mitfahr_app/welcome/pages/register_page.dart';

import '../../test_util/factories/chat_factory.dart';
import '../../test_util/factories/drive_factory.dart';
import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/review_factory.dart';
import '../../test_util/factories/ride_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  late Profile driver;
  late Drive drive;
  late Ride ride;

  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() {
    MockServer.setProcessor(processor);
  });

  setUp(() {
    reset(processor);

    driver = ProfileFactory().generateFake(
      reviewsReceived: ReviewFactory().generateFakeList(),
    );

    drive = DriveFactory().generateFake(
      driver: NullableParameter(driver),
    );

    ride = RideFactory().generateFake(
      start: 'Start',
      end: 'End',
      endDateTime: DateTime.now().add(const Duration(hours: 1)),
      status: RideStatus.approved,
      drive: NullableParameter(drive),
    );

    whenRequest(processor).thenReturnJson(ride.toJsonForApi());
  });

  group('RideDetailPage', () {
    group('constructors', () {
      testWidgets('Works with id parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage(id: ride.id));

        expect(find.byType(TripOverview), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the ride to be fully loaded
        await tester.pump();

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.text(driver.username), findsOneWidget);
      });

      testWidgets('Works with object parameter', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));

        expect(find.byType(TripOverview), findsOneWidget);
        expect(find.text(driver.username), findsNothing);

        // Wait for the ride to be fully loaded
        await tester.pump();

        expect(find.text(driver.username), findsOneWidget);
      });
    });

    testWidgets('Shows the driver profile', (WidgetTester tester) async {
      await pumpMaterial(tester, RideDetailPage.fromRide(ride));
      await tester.pump();

      expect(find.byType(ProfileWidget), findsOneWidget);
      expect(find.byType(ReviewsPreview), findsOneWidget);
      expect(find.byType(FeaturesColumn), findsOneWidget);
      expect(find.text(driver.username), findsOneWidget);
    });

    group('when ride is preview', () {
      setUp(() {
        ride = RideFactory().generateFake(
          status: RideStatus.preview,
          drive: NullableParameter(null),
          driveId: drive.id,
        );

        whenRequest(processor).thenReturnJson(drive.toJsonForApi());
      });

      testWidgets('It shows the request button, but no riders', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byType(CustomBanner), findsNothing);
        expect(find.byType(ProfileWrapList), findsNothing);
        expect(find.byKey(const Key('requestRideButton')), findsOneWidget);
      });
    });

    group('when ride is pending', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.pending, drive: NullableParameter(drive));

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      testWidgets('it shows a banner and the withdraw button, but no riders', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('rideRequestedBanner')), findsOneWidget);
        expect(find.byKey(const Key('withdrawRideButton')), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsNothing);
      });
    });

    group('when ride is approved', () {
      testWidgets('it shows the riders', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byType(ProfileWrapList), findsOneWidget);
      });

      testWidgets('it shows the cancel button when ride is ongoing', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('cancelRideButton')), findsOneWidget);
      });

      testWidgets('it shows the rating button when ride is finished', (WidgetTester tester) async {
        ride = RideFactory().generateFake(
          status: RideStatus.approved,
          endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
          drive: NullableParameter(drive),
        );

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());

        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('rateDriverButton')), findsOneWidget);
      });
    });

    group('when ride is rejected', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.rejected, drive: NullableParameter(drive));

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      testWidgets('it shows the hide button and a banner, but no riders', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('rideRejectedBanner')), findsOneWidget);
        expect(find.byKey(const Key('hideRideButton')), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsNothing);
      });
    });

    group('when ride is cancelled by driver', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.cancelledByDriver, drive: NullableParameter(drive));

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      testWidgets('it shows the riders, a hide button and a banner', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('rideCancelledByDriverBanner')), findsOneWidget);
        expect(find.byKey(const Key('hideRideButton')), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsOneWidget);
      });
    });

    group('when ride is cancelled by rider', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.cancelledByRider, drive: NullableParameter(drive));

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      testWidgets('it shows the hide button and a banner, but no riders', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('rideCancelledByYouBanner')), findsOneWidget);
        expect(find.byKey(const Key('hideRideButton')), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsNothing);
      });
    });

    group('when ride is withdrawn by rider', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.withdrawnByRider, drive: NullableParameter(drive));

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      testWidgets('it shows the request button', (WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        expect(find.byKey(const Key('requestRideButton')), findsOneWidget);
        expect(find.byType(ProfileWrapList), findsNothing);
      });
    });

    group('Riders view', () {
      testWidgets('it shows only visible riders that overlap', (WidgetTester tester) async {
        final DateTime now = DateTime.now();

        final List<Ride> rideWithStatuses = RideStatus.values
            .where((status) => !status.isRealRider())
            .map(
              (status) => RideFactory().generateFake(
                status: status,
                endDateTime: now.add(const Duration(hours: 1)),
              ),
            )
            .toList();

        final Ride approvedRide = RideFactory().generateFake(
          status: RideStatus.approved,
          endDateTime: now.add(const Duration(hours: 1)),
        );

        final Ride approvedRideWithoutOverlap = RideFactory().generateFake(
          status: RideStatus.approved,
          startDateTime: now.add(const Duration(hours: 2)),
          endDateTime: now.add(const Duration(hours: 3)),
        );

        final Ride cancelledByDriverRide = RideFactory().generateFake(
          status: RideStatus.cancelledByDriver,
          endDateTime: DateTime.now().add(const Duration(hours: 1)),
        );

        final Ride cancelledByDriverRideWithoutOverlap = RideFactory().generateFake(
          status: RideStatus.cancelledByDriver,
          startDateTime: now.add(const Duration(hours: 2)),
          endDateTime: now.add(const Duration(hours: 3)),
        );

        // The drive has "the" ride, but we redefine that ride later to avoid StackOverflow
        drive = DriveFactory().generateFake(
          driver: NullableParameter(driver),
          rides: [ride] +
              rideWithStatuses +
              [approvedRide] +
              [approvedRideWithoutOverlap] +
              [cancelledByDriverRide] +
              [cancelledByDriverRideWithoutOverlap],
        );

        ride = RideFactory().generateFake(
          rider: NullableParameter(ride.rider),
          status: RideStatus.approved,
          drive: NullableParameter(drive),
          endDateTime: now.add(const Duration(hours: 1)),
        );

        whenRequest(processor).thenReturnJson(ride.toJsonForApi());

        await pumpMaterial(tester, RideDetailPage.fromRide(ride));
        await tester.pump();

        final Finder profileChipFinder =
            find.descendant(of: find.byType(ProfileWrapList), matching: find.byType(ProfileChip));

        final Iterable<ProfileChip> profileChips = tester.widgetList<ProfileChip>(profileChipFinder);
        final Set<int> profileIds = profileChips.map((ProfileChip profileChip) => profileChip.profile.id!).toSet();
        expect(profileIds, {ride.rider!.id, approvedRide.rider!.id, cancelledByDriverRide.rider!.id});
      });
    });

    group('Cancelling ride', () {
      Future<void> openCancelDialog(WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));

        await tester.pump();

        final Finder cancelRideButton = find.byKey(const Key('cancelRideButton'));
        await tester.scrollUntilVisible(cancelRideButton, 500.0, scrollable: find.byType(Scrollable).first);
        await tester.tap(cancelRideButton);
        await tester.pumpAndSettle();
      }

      testWidgets('Can cancel ride', (WidgetTester tester) async {
        await openCancelDialog(tester);

        final Finder cancelRideYesButton = find.byKey(const Key('cancelRideYesButton'));
        expect(cancelRideYesButton, findsOneWidget);
        await tester.tap(cancelRideYesButton);
        await tester.pumpAndSettle();

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/rides?id=eq.${ride.id}'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: equals({'status': RideStatus.cancelledByRider.index}),
        ).called(1);

        expect(find.byKey(const Key('rideCancelledByYouBanner')), findsOneWidget);
      });

      testWidgets('Can abort cancelling ride', (WidgetTester tester) async {
        await openCancelDialog(tester);

        final Finder cancelRideNoButton = find.byKey(const Key('cancelRideNoButton'));
        expect(cancelRideNoButton, findsOneWidget);
        await tester.tap(cancelRideNoButton);
        await tester.pumpAndSettle();

        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/rides?id=eq.${ride.id}'));

        expect(find.byKey(const Key('rideCancelledByYouBanner')), findsNothing);
      });
    });

    group('Requesting ride', () {
      setUp(() {
        ride = RideFactory().generateFake(
          status: RideStatus.preview,
          drive: NullableParameter(null),
          driveId: drive.id,
        );

        // We return the drive when ride is preview
        whenRequest(processor).thenReturnJson(drive.toJsonForApi());
      });

      Future<void> openDialog(WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));

        await tester.pump();

        final Finder requestRideButton = find.byKey(const Key('requestRideButton'));
        await tester.scrollUntilVisible(requestRideButton, 500.0, scrollable: find.byType(Scrollable).first);
        await tester.tap(requestRideButton);
        await tester.pumpAndSettle();
      }

      group('Request dialog', () {
        testWidgets('Can request ride', (WidgetTester tester) async {
          await openDialog(tester);

          // Using ride.id + 1 to simulate the assigned id of the new ride
          final Ride returnedRide = ride.copyWith(id: ride.id! + 1, status: RideStatus.pending);
          whenRequest(processor).thenReturnJson(returnedRide.toJsonForApi());

          final Finder requestRideYesButton = find.byKey(const Key('requestRideYesButton'));
          expect(requestRideYesButton, findsOneWidget);
          await tester.tap(requestRideYesButton);

          await tester.pumpAndSettle();

          // Ride is requested by uploading a new ride
          verifyRequest(
            processor,
            urlMatcher: equals('/rest/v1/rides?select=%2A'),
            methodMatcher: equals('POST'),
            bodyMatcher: containsPair('start', ride.start),
          ).called(1);

          // Ride is reloaded to pick up supabase function changes
          verifyRequest(
            processor,
            urlMatcher: matches(RegExp('/rest/v1/rides.*id=eq.${returnedRide.id}')),
            methodMatcher: equals('GET'),
          ).called(1);

          expect(find.byKey(const Key('rideRequestedBanner')), findsOneWidget);
        });

        testWidgets('Can abort requesting ride', (WidgetTester tester) async {
          await openDialog(tester);

          final Finder requestRideNoButton = find.byKey(const Key('requestRideNoButton'));
          expect(requestRideNoButton, findsOneWidget);
          await tester.tap(requestRideNoButton);
          await tester.pumpAndSettle();

          verifyRequestNever(processor, urlMatcher: startsWith('/rest/v1/rides'));

          expect(find.byKey(const Key('rideRequestedBanner')), findsNothing);
        });
      });

      group('Login Dialog', () {
        setUp(() {
          ride.chat = null;
          supabaseManager.currentProfile = null;
        });

        testWidgets('Can cancel', (WidgetTester tester) async {
          await openDialog(tester);

          final Finder loginRideCancelButton = find.byKey(const Key('loginRideCancelButton'));
          expect(loginRideCancelButton, findsOneWidget);
          await tester.tap(loginRideCancelButton);
          await tester.pumpAndSettle();

          expect(find.byType(RideDetailPage), findsOneWidget);
        });

        testWidgets('Can go to login', (WidgetTester tester) async {
          await openDialog(tester);

          final Finder loginRideLoginButton = find.byKey(const Key('loginRideLoginButton'));
          expect(loginRideLoginButton, findsOneWidget);
          await tester.tap(loginRideLoginButton);
          await tester.pumpAndSettle();

          expect(find.byType(LoginPage), findsOneWidget);
        });

        testWidgets('Can go to register', (WidgetTester tester) async {
          await openDialog(tester);

          final Finder loginRideRegisterButton = find.byKey(const Key('loginRideRegisterButton'));
          expect(loginRideRegisterButton, findsOneWidget);
          await tester.tap(loginRideRegisterButton);
          await tester.pumpAndSettle();

          expect(find.byType(RegisterPage), findsOneWidget);
        });
      });
    });

    group('Withdrawing from ride', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.pending, drive: NullableParameter(drive));
        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      Future<void> openWithdrawDialog(WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));

        await tester.pump();

        final Finder withdrawRideButton = find.byKey(const Key('withdrawRideButton'));
        await tester.scrollUntilVisible(withdrawRideButton, 500.0, scrollable: find.byType(Scrollable).first);
        await tester.tap(withdrawRideButton);
        await tester.pumpAndSettle();
      }

      testWidgets('Can withdraw from ride', (WidgetTester tester) async {
        await openWithdrawDialog(tester);

        final Finder withdrawRideYesButton = find.byKey(const Key('withdrawRideYesButton'));
        expect(withdrawRideYesButton, findsOneWidget);
        await tester.tap(withdrawRideYesButton);
        await tester.pumpAndSettle();

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/rides?id=eq.${ride.id}'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: containsPair('status', RideStatus.withdrawnByRider.index),
        ).called(1);
      });

      testWidgets('Can abort withdrawing from ride', (WidgetTester tester) async {
        await openWithdrawDialog(tester);

        final Finder withdrawRideNoButton = find.byKey(const Key('withdrawRideNoButton'));
        expect(withdrawRideNoButton, findsOneWidget);
        await tester.tap(withdrawRideNoButton);
        await tester.pumpAndSettle();

        verifyRequestNever(processor, urlMatcher: equals('/rest/v1/rides?id=eq.${ride.id}'));
      });
    });

    group('Hiding drive', () {
      setUp(() {
        ride = RideFactory().generateFake(status: RideStatus.cancelledByDriver, drive: NullableParameter(drive));
        whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      });

      Future<void> openHideDialog(WidgetTester tester) async {
        await pumpMaterial(tester, RideDetailPage.fromRide(ride));

        await tester.pump();

        final Finder hideRideButton = find.byKey(const Key('hideRideButton'));
        await tester.scrollUntilVisible(hideRideButton, 500.0, scrollable: find.byType(Scrollable).first);
        await tester.tap(hideRideButton);
        await tester.pumpAndSettle();
      }

      testWidgets('Can hide drive', (WidgetTester tester) async {
        await openHideDialog(tester);

        final Finder hideRideYesButton = find.byKey(const Key('hideRideYesButton'));
        expect(hideRideYesButton, findsOneWidget);
        await tester.tap(hideRideYesButton);
        await tester.pumpAndSettle();

        verifyRequest(
          processor,
          urlMatcher: equals('/rest/v1/rides?id=eq.${ride.id}'),
          methodMatcher: equals('PATCH'),
          bodyMatcher: equals({'hide_in_list_view': true}),
        ).called(1);
      });

      testWidgets('Can abort hiding drive', (WidgetTester tester) async {
        await openHideDialog(tester);

        final Finder hideRideNoButton = find.byKey(const Key('hideRideNoButton'));
        expect(hideRideNoButton, findsOneWidget);
        await tester.tap(hideRideNoButton);
        await tester.pumpAndSettle();

        verifyRequestNever(processor, urlMatcher: startsWith('/rest/v1/rides?id=eq.${ride.id}'));
      });
    });
    testWidgets('Can navigate to rate page', (WidgetTester tester) async {
      ride = RideFactory().generateFake(
        status: RideStatus.approved,
        endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        drive: NullableParameter(drive),
      );

      whenRequest(processor).thenReturnJson(ride.toJsonForApi());

      await pumpMaterial(tester, RideDetailPage.fromRide(ride));

      await tester.pump();

      // Mock review call
      whenRequest(processor).thenReturnJson(null);

      final Finder rateDriverButton = find.byKey(const Key('rateDriverButton'));
      await tester.scrollUntilVisible(rateDriverButton, 500.0, scrollable: find.byType(Scrollable).first);
      await tester.tap(rateDriverButton);
      await tester.pumpAndSettle();

      expect(find.byType(WriteReviewPage), findsOneWidget);
    });

    testWidgets('Accessibility', (WidgetTester tester) async {
      await expectMeetsAccessibilityGuidelines(tester, RideDetailPage.fromRide(ride));
    });
  });

  group('can Navigate to chatPage', () {
    setUp(() {
      ride = RideFactory().generateFake(
        status: RideStatus.approved,
        endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        drive: NullableParameter(drive),
        chat: NullableParameter(ChatFactory().generateFake(id: 1, messages: NullableParameter([]))),
      );
      whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/messages?select=%2A&chat_id=eq.${ride.chatId}&order=created_at.desc.nullslast'),
      ).thenReturnJson([]);
    });
    testWidgets('with the right profile and chatId', (WidgetTester tester) async {
      await pumpMaterial(tester, RideDetailPage.fromRide(ride));
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatButton')));
      await tester.pump();
      await tester.pump();
      final Finder chatPageFinder = find.byType(ChatPage);
      expect(chatPageFinder, findsOneWidget);
      final ChatPage chatPage = tester.widget(chatPageFinder);
      expect(chatPage.profile, ride.drive!.driver);
      expect(chatPage.chatId, ride.chatId);
    });
    testWidgets('active = true when ride has active chat', (WidgetTester tester) async {
      ride = RideFactory().generateFake(
        status: RideStatus.approved,
        endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        drive: NullableParameter(drive),
        chat: NullableParameter(ChatFactory().generateFake(id: 1, messages: NullableParameter([]))),
      );
      await pumpMaterial(tester, RideDetailPage.fromRide(ride));
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatButton')));
      await tester.pump();
      await tester.pump();
      final Finder chatPageFinder = find.byType(ChatPage);
      expect(chatPageFinder, findsOneWidget);
      final ChatPage chatPage = tester.widget(chatPageFinder);
      expect(chatPage.active, true);
    });
    testWidgets('active = false when ride has inactive chat', (WidgetTester tester) async {
      ride = RideFactory().generateFake(
        status: RideStatus.pending,
        endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        drive: NullableParameter(drive),
        chat: NullableParameter(ChatFactory().generateFake(id: 1, messages: NullableParameter([]))),
      );
      whenRequest(processor).thenReturnJson(ride.toJsonForApi());
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/messages?select=%2A&chat_id=eq.${ride.chatId}&order=created_at.desc.nullslast'),
      ).thenReturnJson([]);
      await pumpMaterial(tester, RideDetailPage.fromRide(ride));
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatButton')));
      await tester.pump();
      await tester.pump();
      final Finder chatPageFinder = find.byType(ChatPage);
      expect(chatPageFinder, findsOneWidget);
      final ChatPage chatPage = tester.widget(chatPageFinder);
      expect(chatPage.active, false);
    });
  });
}
