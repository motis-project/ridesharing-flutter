import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';

import '../../account/pages/profile_page.dart';
import '../../account/widgets/avatar.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  final double size;
  final bool showDescription;
  final Widget? actionWidget;
  final bool isTappable;
  final Function(dynamic)? onPop;

  const ProfileWidget(
    this.profile, {
    super.key,
    this.size = 20,
    this.showDescription = false,
    this.actionWidget,
    this.isTappable = true,
    this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    Widget profileRow = Row(
      children: [
        Avatar(profile, size: size),
        const SizedBox(width: 5),
        Text(profile.username, style: TextStyle(fontSize: size)),
      ],
    );
    if (actionWidget != null) {
      profileRow = Stack(
        children: [profileRow, Positioned(right: 0, child: actionWidget!)],
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
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ProfilePage.fromProfile(profile)))
                  .then((value) => onPop?.call(value));
            },
            child: profileRow,
          )
        : profileRow;
  }
}
