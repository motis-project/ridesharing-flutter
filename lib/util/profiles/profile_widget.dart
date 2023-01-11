import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../account/pages/profile_page.dart';
import '../../account/widgets/avatar.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  final double size;
  final bool showDescription;
  final Widget? actionWidget;
  final bool isTappable;
  final Function()? onTap;
  final Function(dynamic)? onPop;

  const ProfileWidget(
    this.profile, {
    super.key,
    this.size = 20,
    this.showDescription = false,
    this.actionWidget,
    this.isTappable = true,
    this.onTap,
    this.onPop,
  })  : assert(onTap == null || onPop == null, "onTap and onPop cannot be set at the same time."),
        assert((onTap == null && onPop == null) || isTappable, "isTappable has to be true if onTap or onPop are set");

  @override
  Widget build(BuildContext context) {
    Widget profileRow = Semantics(
      label: profile.username,
      excludeSemantics: true,
      button: isTappable,
      tooltip: S.of(context).seeProfile,
      child: Row(
        children: [
          Avatar(profile, size: size),
          const SizedBox(width: 5),
          Text(profile.username, style: TextStyle(fontSize: size)),
        ],
      ),
    );
    if (actionWidget != null) {
      profileRow = Stack(
        children: [profileRow, Positioned.fill(child: Align(alignment: Alignment.centerRight, child: actionWidget!))],
      );
    }
    if (showDescription && (profile.description?.isNotEmpty ?? false)) {
      profileRow = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileRow,
          const SizedBox(height: 10),
          Text(profile.description!),
        ],
      );
    }
    return isTappable
        ? InkWell(
            onTap: () {
              onTap ??
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ProfilePage.fromProfile(profile)))
                      .then((value) => onPop?.call(value));
            },
            child: profileRow,
          )
        : profileRow;
  }
}
