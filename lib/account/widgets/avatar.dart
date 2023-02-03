import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/profile.dart';
import '../pages/avatar_picture_page.dart';

class Avatar extends StatefulWidget {
  const Avatar(
    this.profile, {
    super.key,
    this.isTappable = false,
    this.actionIcon = const Icon(Icons.photo_library),
    this.onAction,
    this.size,
    this.withHero = false,
  });

  final bool isTappable;
  final Profile profile;
  final Icon? actionIcon;
  final VoidCallback? onAction;
  final double? size;
  final bool withHero;

  @override
  AvatarState createState() => AvatarState();
}

class AvatarState extends State<Avatar> {
  Widget buildAvatar() {
    final Widget avatar = CircleAvatar(
      radius: widget.size,
      backgroundImage: widget.profile.avatarUrl?.isEmpty ?? true ? null : NetworkImage(widget.profile.avatarUrl!),
      child: widget.profile.avatarUrl?.isEmpty ?? true
          ? Text(
              widget.profile.username[0].toUpperCase(),
              style: TextStyle(fontSize: widget.size),
            )
          : null,
    );
    return widget.withHero ? Hero(tag: 'Avatar-${widget.profile.id}', child: avatar) : avatar;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        buildAvatar(),
        if (widget.isTappable)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                label: S.of(context).widgetAvatarDetailsLabel,
                button: true,
                tooltip: S.of(context).widgetAvatarDetailsTooltip,
                child: InkWell(
                  borderRadius: BorderRadius.circular(widget.size ?? 20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (BuildContext context) => AvatarPicturePage(widget.profile)),
                  ),
                ),
              ),
            ),
          ),
        if (widget.onAction != null && widget.profile.isCurrentUser)
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                tooltip: S.of(context).widgetAvatarUploadTooltip,
                iconSize: 20,
                onPressed: widget.onAction,
                icon: const Icon(Icons.photo_library),
              ),
            ),
          ),
      ],
    );
  }
}
