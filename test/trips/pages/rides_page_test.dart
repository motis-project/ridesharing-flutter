import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/managers/supabase_manager.dart';
import 'package:motis_mitfahr_app/trips/pages/rides_page.dart';
import 'package:motis_mitfahr_app/trips/pages/search_ride_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_util/factories/profile_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });
  setUp(() async {
    profile = ProfileFactory().generateFake(id: 1);
    supabaseManager.currentProfile = profile;
    whenRequest(processor).thenReturnJson([]);
  });
  testWidgets('has stream subscription', (WidgetTester tester) async {
    await pumpMaterial(tester, const RidesPage());
    final List<RealtimeChannel> subscription = supabaseManager.supabaseClient.getChannels();
    expect(subscription.length, 1);
    expect(subscription[0].topic, 'realtime:public:rides:1');
    verifyRequest(
      processor,
      urlMatcher: equals('/rest/v1/rides?select=%2A&rider_id=eq.${profile.id}&order=start_time.asc.nullslast'),
    );
  });

  testWidgets('FAB works', (WidgetTester tester) async {
    await pumpMaterial(tester, const RidesPage());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final Finder fab = find.byKey(const Key('ridesFAB'));
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.byType(SearchRidePage), findsOneWidget);
  });

  testWidgets('Accessibility', (WidgetTester tester) async {
    await expectMeetsAccessibilityGuidelines(tester, const RidesPage());
  });
}
