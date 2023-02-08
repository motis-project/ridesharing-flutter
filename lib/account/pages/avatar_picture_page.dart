import 'package:flutter/material.dart';

import '../models/profile.dart';

class AvatarPicturePage extends StatelessWidget {
  final Profile profile;
  const AvatarPicturePage(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.username),
      ),
      body: Center(
        child: Hero(
          tag: 'Avatar-${profile.id}',
          child: SizedBox(
            height: width,
            width: width,
            child: profile.avatarUrl?.isEmpty ?? true
                ? Container(
                    color: Theme.of(context).colorScheme.primary,
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Text(
                        profile.username[0].toUpperCase(),
                        style: Theme.of(context)
                            .primaryTextTheme
                            .titleMedium!
                            .copyWith(fontSize: width / 2, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  )
                : Image(fit: BoxFit.cover, image: NetworkImage(profile.avatarUrl!)),
          ),
        ),
      ),
    );
  }
}
