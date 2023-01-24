import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/pages/drives_page.dart';
import 'package:motis_mitfahr_app/rides/pages/rides_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/trip/drive_card.dart';
import 'package:motis_mitfahr_app/util/trip/ride_card.dart';

import '../util/factories/drive_factory.dart';
import '../util/factories/model_factory.dart';
import '../util/factories/profile_factory.dart';
import '../util/factories/ride_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

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
    SupabaseManager.setCurrentProfile(profile);
  });

  // since the code for the TripPageBuilder is the same for both pages,
  // we only test the DrivesPage and assume that the RidesPage works the same.
  // This test is to show that if the ridesPage is called there are rideCards shown.
  testWidgets('shows Ride card for RidesPage', (WidgetTester tester) async {
    final List<Map<String, dynamic>> rides = [
      RideFactory()
          .generateFake(
            id: 1,
            endTime: DateTime.now().add(const Duration(days: 1)),
            hideInListView: false,
            rider: NullableParameter(null),
            drive: NullableParameter(null),
            driveId: 6,
            createDependencies: false,
          )
          .toJsonForApi(),
      RideFactory()
          .generateFake(
            id: 2,
            endTime: DateTime.now().add(const Duration(days: 1)),
            hideInListView: false,
            rider: NullableParameter(null),
            drive: NullableParameter(null),
            driveId: 7,
            createDependencies: false,
          )
          .toJsonForApi(),
    ];
    whenRequest(processor,
            urlMatcher: equals('/rest/v1/rides?select=%2A&rider_id=eq.${profile.id}&order=start_time.asc.nullslast'))
        .thenReturnJson(rides);
    whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*id=eq\.6')), methodMatcher: equals('GET'))
        .thenReturnJson(DriveFactory().generateFake(id: 6).toJsonForApi());
    whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*id=eq\.7')), methodMatcher: equals('GET'))
        .thenReturnJson(DriveFactory().generateFake(id: 7).toJsonForApi());

    await pumpMaterial(tester, const RidesPage());
    await tester.pump();
    final Finder rideCard = find.byType(RideCard);
    expect(rideCard, findsNWidgets(2));
  });

  group('tabs', () {
    setUp(() async {});
    testWidgets('finds both Tabs(before and after Drives are loaded)', (WidgetTester tester) async {
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());
      final Finder tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);
      expect(find.descendant(of: tabBar, matching: find.byType(Tab)), findsNWidgets(2));
      await tester.pump();
      expect(tabBar, findsOneWidget);
      expect(find.descendant(of: tabBar, matching: find.byType(Tab)), findsNWidgets(2));
    });
    testWidgets('shows upcoming Trips at beginning', (WidgetTester tester) async {
      whenRequest(processor,
              urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.1&order=start_time.asc.nullslast'))
          .thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());
      expect(find.byKey(const Key('upcomingTrips')), findsOneWidget);
    });

    testWidgets('can navigate between Tabs', (WidgetTester tester) async {
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      expect(find.byKey(const Key('upcomingTrips')), findsOneWidget);
      expect(find.byKey(const Key('pastTrips')), findsNothing);
      final Finder pastTab = find.byType(Tab).at(1);
      expect(pastTab, findsOneWidget);
      await tester.tap(pastTab);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pastTrips')), findsOneWidget);
      expect(find.byKey(const Key('upcomingTrips')), findsNothing);
      final Finder upcomingTab = find.byType(Tab).at(0);
      expect(upcomingTab, findsOneWidget);
      await tester.tap(upcomingTab);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('upcomingTrips')), findsOneWidget);
      expect(find.byKey(const Key('pastTrips')), findsNothing);
    });
  });
  group('shows Cards upcoming', () {
    testWidgets('shows Cards that should be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
            id: 1,
            endTime: DateTime.now().add(const Duration(days: 1)),
            hideInListView: false,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
        DriveFactory().generateFake(
            id: 2,
            endTime: DateTime.now().add(const Duration(days: 1)),
            hideInListView: false,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
      ];
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson(drives);
      whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')), methodMatcher: equals('GET'))
          .thenReturnJson(drives[0]);
      whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')), methodMatcher: equals('GET'))
          .thenReturnJson(drives[1]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      expect(find.byType(DriveCard), findsNWidgets(2));
    });

    testWidgets('does not show Cards that should not be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
            id: 1,
            endTime: DateTime.now().subtract(const Duration(days: 1)),
            hideInListView: false,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
        DriveFactory().generateFake(
            id: 2,
            endTime: DateTime.now().add(const Duration(days: 1)),
            hideInListView: true,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
      ];
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson(drives);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      expect(find.byType(DriveCard), findsNothing);
      verifyRequestNever(processor,
          urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')), methodMatcher: equals('GET'));
      verifyRequestNever(processor,
          urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')), methodMatcher: equals('GET'));
    });
    testWidgets('shows Nothing if no Drives are there', (WidgetTester tester) async {
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson([]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      expect(find.byType(DriveCard), findsNothing);
      expect(find.byKey(const Key('emptyMessage')), findsOneWidget);
    });
  });

  group('shows Cards past', () {
    testWidgets('shows Cards that should be shown', (WidgetTester tester) async {
      drives = [
        DriveFactory().generateFake(
            id: 1,
            endTime: DateTime.now().subtract(const Duration(days: 1)),
            hideInListView: false,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
        DriveFactory().generateFake(
            id: 2,
            endTime: DateTime.now().subtract(const Duration(days: 1)),
            hideInListView: false,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
      ];
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson(drives);
      whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')), methodMatcher: equals('GET'))
          .thenReturnJson(drives[0]);
      whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')), methodMatcher: equals('GET'))
          .thenReturnJson(drives[1]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      final Finder pastTab = find.byType(Tab).at(1);
      expect(pastTab, findsOneWidget);
      await tester.tap(pastTab);
      await tester.pumpAndSettle();
      expect(find.byType(DriveCard), findsNWidgets(2));
    });

    testWidgets('does not show Cards that should not be shown', (WidgetTester tester) async {
      reset(processor);
      drives = [
        DriveFactory().generateFake(
            id: 1,
            endTime: DateTime.now().add(const Duration(days: 1)),
            hideInListView: false,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
        DriveFactory().generateFake(
            id: 2,
            endTime: DateTime.now().subtract(const Duration(days: 1)),
            hideInListView: true,
            rides: [
              RideFactory().generateFake(id: 1, rider: NullableParameter(ProfileFactory().generateFake(id: 1)))
            ]).toJsonForApi(),
      ];
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson(drives);
      whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.1')), methodMatcher: equals('GET'))
          .thenReturnJson(drives[0]);
      whenRequest(processor, urlMatcher: matches(RegExp(r'/rest/v1/drives.*&id=eq\.2')), methodMatcher: equals('GET'))
          .thenReturnJson(drives[1]);
      await pumpMaterial(tester, const DrivesPage());
      await tester.pump();
      final Finder pastTab = find.byType(Tab).at(1);
      expect(pastTab, findsOneWidget);
      await tester.tap(pastTab);
      await tester.pumpAndSettle();
      expect(find.byType(DriveCard), findsNothing);
    });
    testWidgets('shows Nothing if no Drives are there', (WidgetTester tester) async {
      whenRequest(processor,
              urlMatcher:
                  equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'))
          .thenReturnJson([]);
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
}
