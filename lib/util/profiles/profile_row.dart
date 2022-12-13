import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';

class ProfileRow extends StatelessWidget {
  final Profile profile;
  final bool showChatButton;

  const ProfileRow(this.profile, {super.key, this.showChatButton = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO: Use profile picture
        CircleAvatar(
          child: Text(profile.username[0]),
        ),
        const SizedBox(width: 5),
        Text(profile.username),
      ],
    );
  }
}
