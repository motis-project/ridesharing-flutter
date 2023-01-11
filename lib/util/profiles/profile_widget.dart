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
  final VoidCallback? customAction;
  final Function(dynamic)? onPop;

  const ProfileWidget(
    this.profile, {
    super.key,
    this.size = 20,
    this.showDescription = false,
    this.actionWidget,
    this.isTappable = true,
    this.customAction,
    this.onPop,
  });

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
              customAction ??
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ProfilePage.fromProfile(profile)))
                      .then((value) => onPop?.call(value));
            },
            child: profileRow,
          )
        : profileRow;
  }
}
