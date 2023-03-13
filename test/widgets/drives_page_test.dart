import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/drives/pages/drives_page.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/factories/profile_factory.dart';
import '../util/mocks/mock_server.dart';
import '../util/mocks/request_processor.dart';
import '../util/mocks/request_processor.mocks.dart';
import '../util/pump_material.dart';

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
    await pumpMaterial(tester, const DrivesPage());
    final List<RealtimeChannel> subscription = supabaseManager.supabaseClient.getChannels();
    expect(subscription.length, 1);
    expect(subscription[0].topic, 'realtime:public:drives:1');
    verifyRequest(
      processor,
      urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.${profile.id}&order=start_time.asc.nullslast'),
    ).called(1);
  });

  testWidgets('FAB works', (WidgetTester tester) async {
    await pumpMaterial(tester, const DrivesPage());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final Finder fab = find.byKey(const Key('drivesFAB'));
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(find.byType(CreateDrivePage), findsOneWidget);
  });

  testWidgets('Accessibility', (WidgetTester tester) async {
    await expectMeetsAccessibilityGuidelines(tester, const DrivesPage());
  });
}
