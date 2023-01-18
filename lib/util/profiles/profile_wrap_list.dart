import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import 'profile_chip.dart';

class ProfileWrapList extends StatelessWidget {
  final Set<Profile> profiles;
  final String title;

  const ProfileWrapList(this.profiles, {super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 5),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: -5,
          runSpacing: -5,
          children: List.generate(
            profiles.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: ProfileChip(
                profiles.elementAt(index),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
