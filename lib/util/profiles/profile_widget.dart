import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  final double size;

  const ProfileWidget(
    this.profile, {
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: profile.username,
      excludeSemantics: true,
      button: true,
      tooltip: S.of(context).seeProfile,
      child: Row(
        children: [
          // TODO: Use profile picture
          CircleAvatar(
            minRadius: size,
            child: Text(profile.username[0], style: TextStyle(fontSize: size)),
          ),
          const SizedBox(width: 5),
          Text(profile.username, style: TextStyle(fontSize: size)),
        ],
      ),
    );
  }
}
