import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../account/pages/profile_page.dart';
import '../../account/widgets/avatar.dart';

class ProfileChip extends StatelessWidget {
  final Profile profile;
  final bool showChatButton;
  final bool withHero;

  const ProfileChip(this.profile, {super.key, this.showChatButton = false, this.withHero = false});

  @override
  Widget build(BuildContext context) {
    Widget usernameText = Text(profile.username);
    if (withHero) usernameText = Hero(tag: 'Username-${profile.id}', child: usernameText);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Semantics(
        label: profile.username,
        excludeSemantics: true,
        button: true,
        tooltip: S.of(context).seeProfile,
        key: Key('profile-${profile.id}'),
        child: ActionChip(
          avatar: Avatar(profile, withHero: withHero),
          label: usernameText,
          labelPadding: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(5),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfilePage.fromProfile(profile)));
          },
        ),
      ),
    );
  }
}
