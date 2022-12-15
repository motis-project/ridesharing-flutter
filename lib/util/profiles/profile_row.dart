import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';

class ProfileRow extends StatelessWidget {
  final Profile profile;
  final bool showChatButton;
  final double size;

  const ProfileRow(
    this.profile, {
    super.key,
    this.showChatButton = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO: Use profile picture
        CircleAvatar(
          child: Text(profile.username[0], style: TextStyle(fontSize: size)),
          minRadius: size,
        ),
        const SizedBox(width: 5),
        Text(profile.username, style: TextStyle(fontSize: size)),
      ],
    );
  }
}
