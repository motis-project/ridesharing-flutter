import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/models/profile.dart';
import '../../account/pages/profile_page.dart';
import '../../account/widgets/avatar.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  final double size;
  final bool showDescription;
  final Widget? actionWidget;
  final bool isTappable;
  final void Function(dynamic)? onPop;
  final bool withHero;

  const ProfileWidget(
    this.profile, {
    super.key,
    this.size = 20,
    this.showDescription = false,
    this.actionWidget,
    this.isTappable = true,
    this.onPop,
    this.withHero = false,
  }) : assert(onPop == null || isTappable, 'isTappable has to be true if onPop is set');

  @override
  Widget build(BuildContext context) {
    Widget usernameText = Text(profile.username, style: TextStyle(fontSize: size), overflow: TextOverflow.ellipsis);
    if (withHero) usernameText = Hero(tag: 'Username-${profile.id}', child: usernameText);
    Widget profileRow = Semantics(
      label: profile.username,
      excludeSemantics: true,
      button: isTappable,
      tooltip: S.of(context).seeProfile,
      child: Row(
        children: <Widget>[
          Avatar(profile, size: size, withHero: withHero),
          SizedBox(width: size / 2),
          Flexible(child: usernameText),
          if (actionWidget != null) const SizedBox(width: 40),
        ],
      ),
    );
    if (actionWidget != null) {
      profileRow = Stack(
        children: <Widget>[
          profileRow,
          Positioned.fill(right: 5, child: Align(alignment: Alignment.centerRight, child: actionWidget))
        ],
      );
    }
    if (showDescription && (profile.description?.isNotEmpty ?? false)) {
      profileRow = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          profileRow,
          const SizedBox(height: 10),
          Text(profile.description!),
        ],
      );
    }
    return isTappable
        ? InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<dynamic>(builder: (_) => ProfilePage.fromProfile(profile)))
                .then((dynamic value) => onPop?.call(value)),
            child: profileRow,
          )
        : profileRow;
  }
}
