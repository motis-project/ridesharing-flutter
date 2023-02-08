import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';

import '../../../util/factories/profile_factory.dart';
import '../../../util/mocks/mock_server.dart';
import '../../../util/mocks/request_processor.dart';
import '../../../util/mocks/request_processor.mocks.dart';
import '../../../util/pump_material.dart';

void main() {
  final Profile profile = ProfileFactory().generateFake();
  final MockRequestProcessor processor = MockRequestProcessor();

  testWidgets('shows right information', (WidgetTester tester) async {
    await pumpScaffold(tester, ProfileWidget(profile));

    expect(find.text(profile.username), findsOneWidget);
    final Finder avatar = find.byType(Avatar);
    expect(avatar, findsOneWidget);
    expect(tester.widget<Avatar>(avatar).profile, profile);

    expect(find.text(profile.description!), findsNothing);

    await pumpScaffold(tester, ProfileWidget(profile, showDescription: true));
    expect(find.text(profile.description!), findsOneWidget);

    await pumpScaffold(tester, ProfileWidget(profile, actionWidget: const Text('Action')));
    expect(find.text('Action'), findsOneWidget);
  });

  testWidgets('navigates to ProfilePage', (WidgetTester tester) async {
    MockServer.setProcessor(processor);
    whenRequest(processor).thenReturnJson(profile.toJsonForApi());

    await pumpScaffold(tester, ProfileWidget(profile));
    await tester.tap(find.byType(ProfileWidget));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('does not navigate to ProfilePage when not tappable', (WidgetTester tester) async {
    await pumpScaffold(tester, ProfileWidget(profile, isTappable: false));
    await tester.tap(find.byType(ProfileWidget), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsNothing);
  });

  testWidgets('uses onPop if given', (WidgetTester tester) async {
    MockServer.setProcessor(processor);
    whenRequest(processor).thenReturnJson(profile.toJsonForApi());
    bool wasCalled = false;

    await pumpScaffold(tester, ProfileWidget(profile, onPop: (_) => wasCalled = true));

    await tester.tap(find.byType(ProfileWidget));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(wasCalled, isTrue);
  });
}
