import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';

class AvatarPicturePage extends StatelessWidget {
  final Profile profile;
  const AvatarPicturePage(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.username),
      ),
      body: Center(
        child: Hero(
          tag: "Avatar-${profile.id}",
          child: SizedBox(
            height: width,
            width: width,
            child: profile.avatarUrl?.isEmpty ?? true
                ? Container(
                    color: getBackgroundColor(context),
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Text(
                        profile.username[0].toUpperCase(),
                        style: Theme.of(context).primaryTextTheme.subtitle1!.copyWith(fontSize: width / 2),
                      ),
                    ),
                  )
                : Image(fit: BoxFit.cover, image: NetworkImage(profile.avatarUrl!)),
          ),
        ),
      ),
    );
  }

  Color getBackgroundColor(BuildContext context) {
    ThemeData theme = Theme.of(context);
    switch (ThemeData.estimateBrightnessForColor(theme.primaryTextTheme.subtitle1!.color!)) {
      case Brightness.dark:
        return theme.primaryColorLight;
      case Brightness.light:
        return theme.primaryColorDark;
    }
  }
}
