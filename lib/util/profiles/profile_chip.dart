import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:motis_mitfahr_app/account/pages/profile_page.dart';

import '../../account/widgets/avatar.dart';

class ProfileChip extends StatelessWidget {
  final Profile profile;
  final bool showChatButton;

  const ProfileChip(this.profile, {super.key, this.showChatButton = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Semantics(
        label: profile.username,
        excludeSemantics: true,
        button: true,
        tooltip: S.of(context).seeProfile,
        child: ActionChip(
          avatar: Avatar(profile),
          label: Text(profile.username),
          labelPadding: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(5),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage.fromProfile(profile)));
          },
        ),
      ),
    );
  }
}
