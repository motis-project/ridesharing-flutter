import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/pages/avatar_picture_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase.dart';
import '../models/profile.dart';

class Avatar extends StatefulWidget {
  const Avatar(
    this.profile, {
    super.key,
    this.isTappable = false,
    this.onUpload,
    this.size,
  });

  final bool isTappable;
  final Profile profile;
  final Function? onUpload;
  final double? size;

  @override
  AvatarState createState() => AvatarState();
}

class AvatarState extends State<Avatar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Hero(
          tag: "Avatar-${widget.profile.id}",
          child: CircleAvatar(
            radius: widget.size,
            backgroundImage: widget.profile.avatarUrl?.isEmpty ?? true ? null : NetworkImage(widget.profile.avatarUrl!),
            child: widget.profile.avatarUrl?.isEmpty ?? true
                ? Text(
                    widget.profile.username[0].toUpperCase(),
                    style: TextStyle(fontSize: widget.size),
                  )
                : null,
          ),
        ),
        if (widget.isTappable)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.size ?? 20),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AvatarPicturePage(widget.profile),
                  ),
                ),
              ),
            ),
          ),
        if (widget.onUpload != null && widget.profile.isCurrentUser)
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                iconSize: 20,
                onPressed: _isLoading ? null : _upload,
                icon: const Icon(Icons.camera_alt),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (imageFile == null) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';

      await supabaseClient.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );

      final imageUrlResponse =
          await supabaseClient.storage.from('avatars').createSignedUrl(fileName, 60 * 60 * 24 * 365 * 10);

      await supabaseClient.from('profiles').update({"avatar_url": imageUrlResponse}).eq('id', widget.profile.id);

      widget.onUpload!();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).widgetAvatarImageCouldNotBeStored)),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}
