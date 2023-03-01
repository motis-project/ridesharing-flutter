import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/buttons/button.dart';
import '../../util/snackbar.dart';
import '../../util/supabase_manager.dart';
import '../models/profile.dart';
import '../models/report.dart';
import '../widgets/avatar.dart';
import '../widgets/editable_row.dart';
import '../widgets/features_column.dart';
import '../widgets/reviews_preview.dart';
import 'edit_account/edit_birth_date_page.dart';
import 'edit_account/edit_description_page.dart';
import 'edit_account/edit_full_name_page.dart';
import 'edit_account/edit_gender_page.dart';
import 'edit_account/edit_profile_features_page.dart';
import 'edit_account/edit_username_page.dart';
import 'write_report_page.dart';

class ProfilePage extends StatefulWidget {
  final int profileId;
  final Profile? profile;

  const ProfilePage(this.profileId, {super.key}) : profile = null;
  ProfilePage.fromProfile(this.profile, {super.key}) : profileId = profile!.id!;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _fullyLoaded = false;
  bool _isLoadingProfilePicture = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) _profile = widget.profile;
    loadProfile();
  }

  Future<void> loadProfile() async {
    final Map<String, dynamic> data =
        await supabaseManager.supabaseClient.from('profiles').select<Map<String, dynamic>>('''
      *,
      profile_features (*),
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      ),
      reports_received: reports!reports_offender_id_fkey(*)
    ''').eq('id', widget.profileId).single();
    setState(() {
      _profile = Profile.fromJson(data);
      _fullyLoaded = true;
    });
  }

  Widget buildAvatar() {
    return Avatar(
      _profile!,
      size: 64,
      onAction: _updateProfilePictureDialog,
      isTappable: true,
      withHero: true,
    );
  }

  Widget buildUsername() {
    final Widget username = Hero(
      tag: 'Username-${_profile!.id}',
      child: Text(
        _profile!.username,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    if (_profile!.isCurrentUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(child: Container()),
          InkWell(
            onTap: () => _pushEditPage(EditUsernamePage(_profile!)),
            key: const Key('editUsernameText'),
            child: username,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: S.of(context).edit,
                icon: const Icon(Icons.edit),
                onPressed: () => _pushEditPage(EditUsernamePage(_profile!)),
                key: const Key('editUsernameIcon'),
              ),
            ),
          ),
        ],
      );
    } else {
      return username;
    }
  }

  Widget buildEmail() {
    return Text(
      _profile!.email,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
    );
  }

  Widget buildDescription() {
    final Widget description = _profile!.description?.isNotEmpty ?? false
        ? Text(
            _profile!.description!,
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileDescriptionEmpty);
    return EditableRow(
      title: S.of(context).pageProfileDescriptionTitle,
      innerWidget: description,
      isEditable: _profile!.isCurrentUser,
      onPressed: () => _pushEditPage(EditDescriptionPage(_profile!)),
      key: const Key('description'),
    );
  }

  Widget buildFullName() {
    final Widget fullName = _profile!.fullName.isNotEmpty
        ? Text(
            _profile!.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileFullNameEmpty);
    return EditableRow(
      title: S.of(context).pageProfileFullNameTitle,
      innerWidget: fullName,
      isEditable: _profile!.isCurrentUser,
      onPressed: () => _pushEditPage(EditFullNamePage(_profile!)),
      key: const Key('fullName'),
    );
  }

  Widget buildAge() {
    final Widget age = _profile!.age != null
        ? Text(
            _profile!.age!.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileAgeEmpty);
    return EditableRow(
      title: S.of(context).pageProfileAgeTitle,
      innerWidget: age,
      isEditable: _profile!.isCurrentUser,
      onPressed: () => _pushEditPage(EditBirthDatePage(_profile!)),
      key: const Key('age'),
    );
  }

  Widget buildGender() {
    final Widget gender = _profile!.gender != null
        ? Text(
            _profile!.gender!.getName(context),
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileGenderEmpty);

    return EditableRow(
      title: S.of(context).pageProfileGenderTitle,
      innerWidget: gender,
      isEditable: _profile!.isCurrentUser,
      onPressed: () => _pushEditPage(EditGenderPage(_profile!)),
      key: const Key('gender'),
    );
  }

  Widget buildFeatures() {
    final Widget features = _profile!.profileFeatures!.isNotEmpty
        ? FeaturesColumn(_profile!.profileFeatures!)
        : buildNoInfoText(S.of(context).pageProfileFeaturesEmpty);
    return EditableRow(
      title: S.of(context).pageProfileFeaturesTitle,
      innerWidget: features,
      isEditable: _profile!.isCurrentUser,
      onPressed: () => _pushEditPage(EditProfileFeaturesPage(_profile!)),
      key: const Key('features'),
    );
  }

  Widget buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          S.of(context).pageProfileReviewsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ReviewsPreview(_profile!)
      ],
    );
  }

  Widget buildNoInfoText(String noInfoText) {
    return Text(
      '<$noInfoText>',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
      key: const Key('noInfoText'),
    );
  }

  Column buildWidgetColumn() {
    final List<Widget> widgets = <Widget>[
      buildAvatar(),
      const SizedBox(height: 8),
      buildUsername(),
      if (_profile!.isCurrentUser) ...<Widget>[
        buildEmail(),
      ],
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
    ];
    if (_profile!.isCurrentUser || _profile!.fullName.isNotEmpty) {
      widgets.addAll(<Widget>[
        buildFullName(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || (_profile!.description?.isNotEmpty ?? false)) {
      widgets.addAll(<Widget>[
        buildDescription(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || _profile!.birthDate != null) {
      widgets.addAll(<Widget>[
        buildAge(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || _profile!.gender != null) {
      widgets.addAll(<Widget>[
        buildGender(),
        const SizedBox(height: 16),
      ]);
    }
    if (_fullyLoaded) {
      if (_profile!.isCurrentUser || _profile!.profileFeatures!.isNotEmpty) {
        widgets.addAll(<Widget>[buildFeatures(), const SizedBox(height: 16)]);
      }
      widgets.add(buildReviews());
      if (!_profile!.isCurrentUser) {
        final bool hasRecentReport = _profile!.reportsReceived!
            .any((Report report) => report.isRecent && report.reporterId == supabaseManager.currentProfile!.id);

        widgets.addAll(<Widget>[
          const SizedBox(height: 32),
          if (hasRecentReport)
            Button.disabled(
              S.of(context).pageProfileButtonReported,
              key: const Key('disabledReportButton'),
            )
          else
            Button.error(
              S.of(context).pageProfileButtonReport,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute<bool?>(builder: (BuildContext context) => WriteReportPage(_profile!)))
                    .then((bool? reportSent) {
                  if (reportSent ?? false) {
                    loadProfile();
                    showSnackBar(context, S.of(context).pageProfileButtonMessage);
                  }
                });
              },
              key: const Key('reportButton'),
            ),
        ]);
      }
    } else {
      widgets.add(const Center(child: CircularProgressIndicator()));
    }
    return Column(
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? ''),
        actions: _profile != null && _profile!.isCurrentUser
            ? <Widget>[
                TextButton.icon(
                  onPressed: signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(S.of(context).pageAccountSignOut),
                  key: const Key('signOutButton'),
                ),
              ]
            : null,
      ),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(padding: const EdgeInsets.all(12), child: buildWidgetColumn()),
              ),
            ),
    );
  }

  Future<void> _pushEditPage(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) => page))
        .then((_) => loadProfile());
  }

  Future<void> _updateProfilePictureDialog() async {
    if (_isLoadingProfilePicture) return;

    setState(() => _isLoadingProfilePicture = true);

    if (_profile!.avatarUrl == null) {
      await _uploadProfilePicture();
    } else {
      await _chooseProfilePictureUpdateMethodDialog();
    }

    setState(() => _isLoadingProfilePicture = false);
  }

  Future<void> _chooseProfilePictureUpdateMethodDialog() async {
    final ProfilePictureUpdateMethod? method = await showDialog<ProfilePictureUpdateMethod>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.of(context).pageProfileUpdateProfilePictureTitle),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ProfilePictureUpdateMethod.fromGallery);
              },
              child: Text(S.of(context).pageProfileUpdateProfilePictureFromGallery),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ProfilePictureUpdateMethod.delete);
              },
              child: Text(S.of(context).pageProfileUpdateProfilePictureDelete),
            ),
          ],
        );
      },
    );

    switch (method) {
      case ProfilePictureUpdateMethod.fromGallery:
        await _uploadProfilePicture();
        break;
      case ProfilePictureUpdateMethod.delete:
        await _deleteProfilePicture();
        break;
      default:
        break;
    }
  }

  Future<void> _uploadProfilePicture() async {
    final PermissionStatus photosPermissionStatus = await Permission.photos.request();
    if (photosPermissionStatus.isPermanentlyDenied) {
      // wait a half second to let the request dialog close
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return _requestPhotosPermissionDialog();
    }

    final ImagePicker picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile == null) return;

    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final String fileExt = imageFile.path.split('.').last;
      final String fileName = '${DateTime.now().toIso8601String()}.$fileExt';

      await supabaseManager.supabaseClient.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );

      final String imageUrlResponse = await supabaseManager.supabaseClient.storage
          .from('avatars')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365 * 10);

      await supabaseManager.supabaseClient
          .from('profiles')
          .update(<String, dynamic>{'avatar_url': imageUrlResponse}).eq('id', _profile!.id);

      await supabaseManager.reloadCurrentProfile();
      await loadProfile();
    } catch (error) {
      if (mounted) {
        showSnackBar(
          context,
          S.of(context).widgetAvatarImageCouldNotBeStored,
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    await supabaseManager.supabaseClient
        .from('profiles')
        .update(<String, dynamic>{'avatar_url': null}).eq('id', _profile!.id);

    await supabaseManager.reloadCurrentProfile();
    await loadProfile();
  }

  Future<void> _requestPhotosPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).pageProfileUpdateProfilePicturePermissionTitle),
          content: Text(S.of(context).pageProfileUpdateProfilePicturePermissionMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: Text(S.of(context).pageProfileUpdateProfilePicturePermissionToSettings),
            ),
          ],
        );
      },
    );
  }

  void signOut() {
    supabaseManager.supabaseClient.auth.signOut();
  }
}

enum ProfilePictureUpdateMethod { delete, fromGallery }
