import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';

class ProfileChip extends StatelessWidget {
  final Profile profile;
  final bool showChatButton;

  const ProfileChip(this.profile, {super.key, this.showChatButton = false});

  @override
  Widget build(BuildContext context) {
    // TODO: Use profile picture
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Semantics(
        label: profile.username,
        excludeSemantics: true,
        button: true,
        tooltip: "See profile",
        child: ActionChip(
          avatar: CircleAvatar(
            child: Text(profile.username[0]),
          ),
          label: Text(profile.username),
          labelPadding: const EdgeInsets.all(5),
          padding: const EdgeInsets.all(5),
          onPressed: () {
            // TODO: Navigate to profile page
          },
        ),
      ),
    );
  }
}
