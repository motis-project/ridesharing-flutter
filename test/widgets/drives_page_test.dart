import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/drives/pages/create_drive_page.dart';
import 'package:motis_mitfahr_app/drives/pages/drives_page.dart';
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
    whenRequest(processor).thenReturn(jsonEncode([]));
  });
  testWidgets('has stream subscription', (WidgetTester tester) async {
    await pumpMaterial(tester, const DrivesPage());
    final List<RealtimeChannel> subscription = SupabaseManager.supabaseClient.getChannels();
    expect(subscription.length, 1);
    expect(subscription[0].topic, 'realtime:public:drives:1');
    verifyRequest(
      processor,
      urlMatcher: equals('/rest/v1/drives?select=%2A&driver_id=eq.1&order=start_time.asc.nullslast'),
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
}
