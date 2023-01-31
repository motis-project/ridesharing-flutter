import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';

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

  setUp(() {
    profile = ProfileFactory().generateFake(id: 1);
    SupabaseManager.setCurrentProfile(profile);
    whenRequest(processor, urlMatcher: equals('/rest/v1/profiles?id=eq.1')).thenReturnJson('');
  });
  group('edit_gender_page', () {
    testWidgets('display genderRadioListTile', (WidgetTester tester) async {
      await pumpMaterial(tester, EditGenderPage(profile));
      await tester.pump();
      final maleGenderFinder = find.byKey(const Key('0genderRadioListTile'));
      expect(maleGenderFinder, findsOneWidget);
      final femaleGenderFinder = find.byKey(const Key('1genderRadioListTile'));
      expect(femaleGenderFinder, findsOneWidget);
      final diverseGenderFinder = find.byKey(const Key('2genderRadioListTile'));
      expect(diverseGenderFinder, findsOneWidget);
      final preferNotToSayGenderFinder = find.byKey(const Key('preferNotToSayGenderRadioListTile'));
      expect(preferNotToSayGenderFinder, findsOneWidget);
    });
    // don't know to test what I have selected
    testWidgets('change gender', (WidgetTester tester) async {
      await pumpMaterial(tester, EditGenderPage(profile));
      await tester.pump();
      final maleGenderFinder = find.byKey(const Key('0genderRadioListTile'));
      await tester.tap(maleGenderFinder);
      await tester.pump();
      final femaleGenderFinder = find.byKey(const Key('1genderRadioListTile'));
      await tester.tap(femaleGenderFinder);
      await tester.pump();
      //expect(selected, Gender.female)
    });
    // same problem as in edit_username_page_test.dart
    testWidgets('save Button', (WidgetTester tester) async {});
  });
}
