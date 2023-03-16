import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/trips/cards/drive_card.dart';
import 'package:motis_mitfahr_app/trips/cards/recurring_drive_card.dart';
import 'package:motis_mitfahr_app/trips/cards/ride_card.dart';
import 'package:motis_mitfahr_app/trips/models/drive.dart';
import 'package:motis_mitfahr_app/trips/models/recurring_drive.dart';
import 'package:motis_mitfahr_app/trips/models/ride.dart';
import 'package:motis_mitfahr_app/trips/pages/drives_page.dart';
import 'package:motis_mitfahr_app/trips/pages/rides_page.dart';

import '../../test_util/factories/drive_factory.dart';
import '../../test_util/factories/model_factory.dart';
import '../../test_util/factories/profile_factory.dart';
import '../../test_util/factories/recurring_drive_factory.dart';
import '../../test_util/factories/ride_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  late List<Map<String, dynamic>> drives;
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    reset(processor);
    profile = ProfileFactory().generateFake(id: 1);
    supabaseManager.currentProfile = profile;
  });

  // since the code for the TripPageBuilder is the same for both pages,
  // we only test the DrivesPage and assume that the RidesPage works the same.
  // This test is to show that if the ridesPage is called there are rideCards shown.
  testWidgets('shows Ride card for RidesPage', (WidgetTester tester) async {
    final Ride ride1 = RideFactory().generateFake(
      destinationDateTime: DateTime.now().add(const Duration(days: 1)),
    );
    final Ride ride2 = RideFactory().generateFake(
      destinationDateTime: DateTime.now().add(const Duration(days: 1)),
    );
    final List<Map<String, dynamic>> rides = [ride1.toJsonForApi(), ride2.toJsonForApi()];
    whenRequest(
      processor,
      urlMatcher: equals('/rest/v1/rides?select=%2A&rider_id=eq.${profile.id}&order=start_time.asc.nullslast'),
    ).thenReturnJson(rides);
    whenRequest(
      processor,
      urlMatcher: matches(RegExp(r'/rest/v1/drives.*id=eq\.' + ride1.drive!.id.toString())),
      methodMatcher: equals('GET'),
    ).thenReturnJson(ride1.drive!.toJsonForApi());
    whenRequest(
      processor,
      urlMatcher: matches(RegExp(r'/rest/v1/drives.*id=eq\.' + ride2.drive!.id.toString())),
      methodMatcher: equals('GET'),
    ).thenReturnJson(ride2.drive!.toJsonForApi());

    await pumpMaterial(tester, const RidesPage());
    await tester.pump();

    final Finder rideCard = find.byType(RideCard);
    expect(rideCard, findsNWidgets(2));
  });

  group('tabs', () {
    testWidgets('Drives finds all Tabs(before and after Drives are loaded)', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);

      await pumpMaterial(tester, const DrivesPage());
      final Finder tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);
      expect(find.descendant(of: tabBar, matching: find.byType(Tab)), findsNWidgets(3));

      await tester.pump();

      expect(tabBar, findsOneWidget);
      expect(find.descendant(of: tabBar, matching: find.byType(Tab)), findsNWidgets(3));
    });

    testWidgets('Rides finds all Tabs(before and after Rides are loaded)', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/rides?select=%2A&rider_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);

      await pumpMaterial(tester, const RidesPage());
      final Finder tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);
      expect(find.descendant(of: tabBar, matching: find.byType(Tab)), findsNWidgets(2));

      await tester.pump();

      expect(tabBar, findsOneWidget);
      expect(find.descendant(of: tabBar, matching: find.byType(Tab)), findsNWidgets(2));
    });

    testWidgets('shows upcoming Trips at beginning', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());

      expect(find.byKey(const Key('upcomingTrips')), findsOneWidget);
    });

    testWidgets('can navigate between Tabs', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();

      final Finder upcomingTab = find.byType(Tab).at(0);
      final Finder pastTab = find.byType(Tab).at(1);
      final Finder recurringTab = find.byType(Tab).at(2);

      expect(find.byKey(const Key('upcomingTrips')), findsOneWidget);
      expect(find.byKey(const Key('pastTrips')), findsNothing);
      expect(find.byKey(const Key('recurringDrives')), findsNothing);

      await tester.tap(pastTab);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pastTrips')), findsOneWidget);
      expect(find.byKey(const Key('upcomingTrips')), findsNothing);
      expect(find.byKey(const Key('recurringDrives')), findsNothing);

      await tester.tap(recurringTab);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pastTrips')), findsNothing);
      expect(find.byKey(const Key('upcomingTrips')), findsNothing);
      expect(find.byKey(const Key('recurringDrives')), findsOneWidget);

      await tester.tap(upcomingTab);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('upcomingTrips')), findsOneWidget);
      expect(find.byKey(const Key('pastTrips')), findsNothing);
      expect(find.byKey(const Key('recurringDrives')), findsNothing);
    });
  });

  group('shows Cards upcoming', () {
    testWidgets('shows Cards that should be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
          id: 1,
          destinationDateTime: DateTime.now().add(const Duration(days: 1)),
          hideInListView: false,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
        DriveFactory().generateFake(
          id: 2,
          destinationDateTime: DateTime.now().add(const Duration(days: 1)),
          hideInListView: false,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
      ];
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson(drives);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[0]);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[1]);
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      expect(find.byType(DriveCard), findsNWidgets(2));
    });

    testWidgets('does not show Cards that should not be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
          id: 1,
          destinationDateTime: DateTime.now().subtract(const Duration(days: 1)),
          hideInListView: false,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
        DriveFactory().generateFake(
          id: 2,
          destinationDateTime: DateTime.now().add(const Duration(days: 1)),
          hideInListView: true,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
      ];
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson(drives);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      expect(find.byType(DriveCard), findsNothing);
      verifyRequestNever(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')),
        methodMatcher: equals('GET'),
      );
      verifyRequestNever(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')),
        methodMatcher: equals('GET'),
      );
    });

    testWidgets('shows Nothing if no Drives are there', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      expect(find.byType(DriveCard), findsNothing);
      expect(find.byKey(const Key('emptyMessage')), findsOneWidget);
    });
  });

  group('Past Cards', () {
    testWidgets('shows Cards that should be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
          id: 1,
          destinationDateTime: DateTime.now().subtract(const Duration(days: 1)),
          hideInListView: false,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
        DriveFactory().generateFake(
          id: 2,
          destinationDateTime: DateTime.now().subtract(const Duration(days: 1)),
          hideInListView: false,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
      ];
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson(drives);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[0]);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[1]);
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      final Finder pastTab = find.byType(Tab).at(1);

      await tester.tap(pastTab);
      await tester.pumpAndSettle();

      expect(find.byType(DriveCard), findsNWidgets(2));
    });

    testWidgets('does not show Cards that should not be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
          id: 1,
          destinationDateTime: DateTime.now().add(const Duration(days: 1)),
          hideInListView: false,
          rides: [
            RideFactory().generateFake(
              id: 1,
              rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
            )
          ],
        ).toJsonForApi(),
        DriveFactory().generateFake(
            id: 2,
            destinationDateTime: DateTime.now().subtract(const Duration(days: 1)),
            hideInListView: true,
            rides: [
              RideFactory().generateFake(
                id: 1,
                rider: NullableParameter(ProfileFactory().generateFake(id: 1)),
              )
            ]).toJsonForApi(),
      ];
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson(drives);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[0]);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[1]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();

      final Finder pastTab = find.byType(Tab).at(1);
      await tester.tap(pastTab);
      await tester.pumpAndSettle();

      expect(find.byType(DriveCard), findsNothing);
    });

    testWidgets('shows Nothing if no Drives are there', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      final Finder pastTab = find.byType(Tab).at(1);
      expect(pastTab, findsOneWidget);
      await tester.tap(pastTab);
      await tester.pumpAndSettle();

      expect(find.byType(DriveCard), findsNothing);
      expect(find.byKey(const Key('emptyMessage')), findsOneWidget);
    });
  });

  group('Recurring Cards', () {
    testWidgets('shows Cards that should be shown', (WidgetTester tester) async {
      final List<RecurringDrive> recurringDrives = [
        RecurringDriveFactory().generateFake(
          id: 1,
        ),
        RecurringDriveFactory().generateFake(
          id: 2,
        ),
      ];
      drives = recurringDrives
          .map((RecurringDrive recurringDrive) =>
              recurringDrive.drives!.map((Drive drive) => drive.toJsonForApi()).toList())
          .expand((x) => x)
          .toList();
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson(drives);
      for (final RecurringDrive recurringDrive in recurringDrives) {
        whenRequest(
          processor,
          urlMatcher: matches(RegExp('/rest/v1/recurring_drives.*&id=eq\\.${recurringDrive.id}')),
          methodMatcher: equals('GET'),
        ).thenReturnJson(recurringDrive.toJsonForApi());
        for (final Drive drive in recurringDrive.drives!) {
          whenRequest(
            processor,
            urlMatcher: matches(RegExp('/rest/v1/drives.*&id=eq\\.${drive.id}')),
            methodMatcher: equals('GET'),
          ).thenReturnJson(drive.toJsonForApi());
        }
      }
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      final Finder recurrenceTab = find.byType(Tab).at(2);

      await tester.tap(recurrenceTab);
      await tester.pumpAndSettle();

      expect(find.byType(RecurringDriveCard), findsNWidgets(2));
    });

    testWidgets('does not show Cards that should not be shown', (WidgetTester tester) async {
      final List<RecurringDrive> recurringDrives = [
        RecurringDriveFactory().generateFake(
          id: 1,
          drives: [
            DriveFactory().generateFake(
              recurringDriveId: NullableParameter(1),
              startDateTime: DateTime.now().subtract(const Duration(days: 1)),
            )
          ],
        ),
        RecurringDriveFactory().generateFake(
          id: 2,
          drives: [
            DriveFactory().generateFake(
              recurringDriveId: NullableParameter(2),
              hideInListView: true,
              startDateTime: DateTime.now().add(const Duration(days: 1)),
            )
          ],
        ),
        RecurringDriveFactory().generateFake(
          id: 3,
          drives: [
            DriveFactory().generateFake(
              recurringDriveId: NullableParameter(3),
              status: DriveStatus.cancelledByRecurrenceRule,
              rides: [],
              startDateTime: DateTime.now().add(const Duration(days: 1)),
            )
          ],
        ),
        // This Recurring Drive WILL be shown, because it has Drives with rides
        RecurringDriveFactory().generateFake(
          id: 4,
          drives: [
            DriveFactory().generateFake(
              recurringDriveId: NullableParameter(4),
              status: DriveStatus.cancelledByRecurrenceRule,
              startDateTime: DateTime.now().add(const Duration(days: 1)),
            )
          ],
        ),
      ];
      drives = [
        DriveFactory().generateFake(id: 1, recurringDriveId: NullableParameter(null)).toJsonForApi(),
        ...recurringDrives
            .map((RecurringDrive recurringDrive) =>
                recurringDrive.drives!.map((Drive drive) => drive.toJsonForApi()).toList())
            .expand((x) => x)
      ];
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson(drives);
      whenRequest(
        processor,
        urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')),
        methodMatcher: equals('GET'),
      ).thenReturnJson(drives[0]);
      for (final RecurringDrive recurringDrive in recurringDrives) {
        whenRequest(
          processor,
          urlMatcher: matches(RegExp('/rest/v1/recurring_drives.*&id=eq\\.${recurringDrive.id}')),
          methodMatcher: equals('GET'),
        ).thenReturnJson(recurringDrive.toJsonForApi());
        for (final Drive drive in recurringDrive.drives!) {
          whenRequest(
            processor,
            urlMatcher: matches(RegExp('/rest/v1/drives.*&id=eq\\.${drive.id}')),
            methodMatcher: equals('GET'),
          ).thenReturnJson(drive.toJsonForApi());
        }
      }
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      final Finder recurrenceTab = find.byType(Tab).at(2);

      await tester.tap(recurrenceTab);
      await tester.pumpAndSettle();

      expect(find.byType(RecurringDriveCard), findsNWidgets(1));

      final RecurringDriveCardState state = tester.state(find.byType(RecurringDriveCard).first);
      expect(state.id, 4);
    });

    testWidgets('shows Nothing if no RecurringDrives are there', (WidgetTester tester) async {
      whenRequest(
        processor,
        urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
      ).thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());

      await tester.pump();

      final Finder recurringTab = find.byType(Tab).at(2);
      await tester.tap(recurringTab);
      await tester.pumpAndSettle();

      expect(find.byType(RecurringDriveCard), findsNothing);
      expect(find.byKey(const Key('emptyMessage')), findsOneWidget);
    });
  });
}
