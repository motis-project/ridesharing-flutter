import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/rides/pages/rides_page.dart';
import 'package:motis_mitfahr_app/rides/pages/search_ride_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/factories/profile_factory.dart';
import '../util/mock_server.dart';
import '../util/pump_material.dart';
import '../util/request_processor.dart';
import '../util/request_processor.mocks.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });
  setUp(() async {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
    whenRequest(processor).thenReturnJson([]);
  });
  testWidgets('has stream subscription', (WidgetTester tester) async {
    await pumpMaterial(tester, const RidesPage());
    final List<RealtimeChannel> subscription = SupabaseManager.supabaseClient.getChannels();
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
}
