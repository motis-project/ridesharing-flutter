import 'package:flutter_test/flutter_test.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';
import 'package:motis_mitfahr_app/account/widgets/avatar.dart';
import 'package:motis_mitfahr_app/account/widgets/profile_chip.dart';

import '../../test_util/factories/profile_factory.dart';
import '../../test_util/mocks/mock_server.dart';
import '../../test_util/mocks/request_processor.dart';
import '../../test_util/mocks/request_processor.mocks.dart';
import '../../test_util/pump_material.dart';

void main() {
  final Profile profile = ProfileFactory().generateFake();
  final MockRequestProcessor processor = MockRequestProcessor();

  testWidgets('shows right information', (WidgetTester tester) async {
    await pumpScaffold(tester, ProfileChip(profile));

    expect(find.text(profile.username), findsOneWidget);
    final Finder avatar = find.byType(Avatar);
    expect(avatar, findsOneWidget);
    expect(tester.widget<Avatar>(avatar).profile, profile);
  });

  testWidgets('can navigate to ProfilePage', (WidgetTester tester) async {
    MockServer.setProcessor(processor);
    whenRequest(processor).thenReturnJson(profile.toJsonForApi());

    await pumpScaffold(tester, ProfileChip(profile));
    await tester.tap(find.byType(ProfileChip));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
  });
}
