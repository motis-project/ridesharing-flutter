import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/report.dart';
import 'package:motis_mitfahr_app/account/pages/write_report_page.dart';
import 'package:motis_mitfahr_app/util/supabase_manager.dart';

import '../../util/factories/profile_factory.dart';
import '../../util/mocks/mock_server.dart';
import '../../util/mocks/request_processor.dart';
import '../../util/mocks/request_processor.mocks.dart';
import '../../util/pump_material.dart';

void main() {
  late Profile profile;
  final MockRequestProcessor processor = MockRequestProcessor();

  setUpAll(() async {
    MockServer.setProcessor(processor);
  });

  setUp(() async {
    profile = ProfileFactory().generateFake();
    supabaseManager.currentProfile = ProfileFactory().generateFake(id: profile.id! + 1);
  });

  group('WriteReportPage', () {
    testWidgets('constructor', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReportPage(profile));
      await tester.pump();

      expect(find.text(profile.username), findsOneWidget);
    });

    testWidgets('Validator', (WidgetTester tester) async {
      await pumpMaterial(tester, WriteReportPage(profile));
      await tester.pump();

      await tester.tap(find.byKey(const Key('writeReportButton')));
      await tester.pump();

      final FormFieldState formFieldState = tester.state(find.byKey(const Key('writeReportField')));
      expect(formFieldState.hasError, isTrue);
    });

    testWidgets('Write Report', (WidgetTester tester) async {
      whenRequest(processor).thenReturnJson(null);

      await pumpMaterial(tester, WriteReportPage(profile));
      await tester.pump();

      final ReportCategory category = ReportCategory.values[Random().nextInt(ReportCategory.values.length)];
      await tester.tap(find.byKey(Key('writeReportCategory${category.name}')));

      final String reportText = faker.lorem.sentence();
      await tester.enterText(find.byKey(const Key('writeReportField')), reportText);

      await tester.tap(find.byKey(const Key('writeReportButton')));
      await tester.pump();

      verifyRequest(
        processor,
        urlMatcher: equals('/rest/v1/reports'),
        methodMatcher: equals('POST'),
        bodyMatcher: equals({
          'offender_id': profile.id,
          'reporter_id': supabaseManager.currentProfile!.id,
          'category': category.index,
          'text': reportText,
        }),
      );
    });
  });
}
