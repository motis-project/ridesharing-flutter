import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_birth_date_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_description_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_full_name_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_gender_page.dart';
import 'package:motis_mitfahr_app/account/pages/edit_account/edit_profile_features_page.dart';
import 'package:motis_mitfahr_app/account/pages/write_report_page.dart';
import 'package:motis_mitfahr_app/account/widgets/editable_row.dart';
import 'package:motis_mitfahr_app/account/widgets/features_column.dart';
import 'package:motis_mitfahr_app/account/widgets/reviews_preview.dart';
import 'package:motis_mitfahr_app/util/buttons/button.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../util/supabase.dart';
import '../models/profile.dart';
import '../widgets/avatar.dart';
import 'edit_account/edit_username_page.dart';

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
    if (widget.profile != null) _profile = widget.profile!;
    loadProfile();
  }

  Future<void> loadProfile() async {
    Map<String, dynamic> data = await SupabaseManager.supabaseClient.from('profiles').select('''
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
      onAction: _isLoadingProfilePicture ? null : _updateProfilePictureDialog,
      isTappable: true,
    );
  }

  Widget buildUsername() {
    Widget username = Text(
      _profile!.username,
      style: Theme.of(context).textTheme.headline5,
    );
    if (_profile!.isCurrentUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Container()),
          username,
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: S.of(context).edit,
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => EditUsernamePage(_profile!)))
                      .then((value) => loadProfile());
                },
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
    Widget description = _profile!.description?.isNotEmpty ?? false
        ? Text(
            _profile!.description!,
            style: Theme.of(context).textTheme.bodyText1,
          )
        : buildNoInfoText(S.of(context).pageProfileDescriptionEmpty);
    return EditableRow(
      title: S.of(context).pageProfileDescriptionTitle,
      innerWidget: description,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EditDescriptionPage(_profile!)))
            .then((value) => loadProfile());
      },
    );
  }

  Widget buildFullName() {
    Widget fullName = _profile!.fullName.isNotEmpty
        ? Text(
            _profile!.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileFullNameEmpty);
    return EditableRow(
      title: S.of(context).pageProfileFullNameTitle,
      innerWidget: fullName,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EditFullNamePage(_profile!)))
            .then((value) => loadProfile());
      },
    );
  }

  Widget buildBirthDate() {
    Widget birthDate = _profile!.birthDate != null
        ? Text(
            localeManager.formatDate(_profile!.birthDate!),
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileBirthDateEmpty);
    return EditableRow(
      title: S.of(context).pageProfileBirthDateTitle,
      innerWidget: birthDate,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EditBirthDatePage(_profile!)))
            .then((value) => loadProfile());
      },
    );
  }

  Widget buildGender() {
    Widget gender = _profile!.gender != null
        ? Text(
            _profile!.gender!.getName(context),
            style: Theme.of(context).textTheme.titleMedium,
          )
        : buildNoInfoText(S.of(context).pageProfileGenderEmpty);

    return EditableRow(
      title: S.of(context).pageProfileGenderTitle,
      innerWidget: gender,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EditGenderPage(_profile!)))
            .then((value) => loadProfile());
      },
    );
  }

  Widget buildFeatures() {
    Widget features = _profile!.profileFeatures!.isNotEmpty
        ? FeaturesColumn(_profile!.profileFeatures!)
        : buildNoInfoText(S.of(context).pageProfileFeaturesEmpty);
    return EditableRow(
      title: S.of(context).pageProfileFeaturesTitle,
      innerWidget: features,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EditProfileFeaturesPage(_profile!)))
            .then((value) => loadProfile());
      },
    );
  }

  Widget buildReviews() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        S.of(context).pageProfileReviewsTitle,
        style: Theme.of(context).textTheme.headline6,
      ),
      const SizedBox(height: 8),
      ReviewsPreview(_profile!)
    ]);
  }

  Widget buildNoInfoText(String noInfoText) {
    return Text(
      "<$noInfoText>",
      style: Theme.of(context).textTheme.bodyText1?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      buildAvatar(),
      const SizedBox(height: 8),
      buildUsername(),
      if (_profile!.isCurrentUser) ...[
        buildEmail(),
      ],
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
    ];
    if (_profile!.isCurrentUser || _profile!.fullName.isNotEmpty) {
      widgets.addAll([
        buildFullName(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || (_profile!.description?.isNotEmpty ?? false)) {
      widgets.addAll([
        buildDescription(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || _profile!.birthDate != null) {
      widgets.addAll([
        buildBirthDate(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || _profile!.gender != null) {
      widgets.addAll([
        buildGender(),
        const SizedBox(height: 16),
      ]);
    }
    if (_fullyLoaded) {
      if (_profile!.isCurrentUser || _profile!.profileFeatures!.isNotEmpty) {
        widgets.addAll([buildFeatures(), const SizedBox(height: 16)]);
      }
      widgets.add(buildReviews());
      if (!_profile!.isCurrentUser) {
        bool hasRecentReport = _profile!.reportsReceived!
            .any((report) => report.isRecent && report.reporterId == SupabaseManager.getCurrentProfile()!.id);

        widgets.addAll([
          const SizedBox(height: 32),
          hasRecentReport
              ? Button.disabled(
                  S.of(context).pageProfileButtonReported,
                )
              : Button.error(
                  S.of(context).pageProfileButtonReport,
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) => WriteReportPage(_profile!)))
                        .then((reportSent) {
                      if (reportSent) {
                        loadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(S.of(context).pageProfileButtonMessage)),
                        );
                      }
                    });
                  },
                ),
        ]);
      }
    } else {
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    final content = Column(
      children: widgets,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? ''),
        actions: _profile != null && _profile!.isCurrentUser
            ? [
                TextButton.icon(
                  onPressed: signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(S.of(context).pageAccountSignOut),
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
                child: Padding(padding: const EdgeInsets.all(12), child: content),
              ),
            ),
    );
  }

  Future<void> _updateProfilePictureDialog() async {
    setState(() => _isLoadingProfilePicture = true);
    if (_profile!.avatarUrl == null) {
      _uploadProfilePicture();
      setState(() => _isLoadingProfilePicture = false);
      return;
    }
    switch (await showDialog<ProfilePictureUpdateMethod>(
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
        })) {
      case ProfilePictureUpdateMethod.fromGallery:
        _uploadProfilePicture();
        break;
      case ProfilePictureUpdateMethod.delete:
        _deleteProfilePicture();
        break;
      case null:
        break;
    }
    setState(() => _isLoadingProfilePicture = false);
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (imageFile == null) {
      return;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';

      await SupabaseManager.supabaseClient.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );

      final imageUrlResponse = await SupabaseManager.supabaseClient.storage
          .from('avatars')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365 * 10);

      await SupabaseManager.supabaseClient
          .from('profiles')
          .update({"avatar_url": imageUrlResponse}).eq('id', _profile!.id);

      SupabaseManager.reloadCurrentProfile();
      loadProfile();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).widgetAvatarImageCouldNotBeStored)),
        );
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    await SupabaseManager.supabaseClient.from('profiles').update({"avatar_url": null}).eq('id', _profile!.id);

    SupabaseManager.reloadCurrentProfile();
    loadProfile();
  }

  void signOut() {
    SupabaseManager.supabaseClient.auth.signOut();
  }
}

enum ProfilePictureUpdateMethod { delete, fromGallery }
