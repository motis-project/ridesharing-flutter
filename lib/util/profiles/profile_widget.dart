import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';

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
    return Row(
      children: [
        // TODO: Use profile picture
        CircleAvatar(
          minRadius: size,
          child: Text(profile.username[0], style: TextStyle(fontSize: size)),
        ),
        const SizedBox(width: 5),
        Text(profile.username, style: TextStyle(fontSize: size)),
      ],
    );
  }
}
