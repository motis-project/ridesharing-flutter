import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/buttons/button.dart';
import '../../../util/supabase.dart';
import '../../models/profile.dart';

class EditFullNamePage extends StatefulWidget {
  final Profile profile;

  const EditFullNamePage(this.profile, {super.key});

  @override
  State<EditFullNamePage> createState() => _EditFullNamePageState();
}

class _EditFullNamePageState extends State<EditFullNamePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name ?? '';
    _surnameController.text = widget.profile.surname ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageProfileEditFullNameTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditSurnameHint,
                  suffixIcon: _getClearButton(_surnameController),
                ),
                controller: _surnameController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditNameHint,
                  suffixIcon: _getClearButton(_nameController),
                ),
                controller: _nameController,
              ),
              const SizedBox(height: 10),
              Button(
                S.of(context).save,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _getClearButton(TextEditingController controller) {
    if (controller.text == '') {
      return null;
    }
    return IconButton(
      tooltip: S.of(context).formClearInput,
      icon: const Icon(Icons.clear),
      onPressed: () => controller.clear(),
    );
  }

  void onPressed() async {
    String? surname = _surnameController.text == '' ? null : _surnameController.text;
    String? name = _nameController.text == '' ? null : _nameController.text;
    await SupabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'surname': surname,
      'name': name,
    }).eq('id', widget.profile.id);
    SupabaseManager.reloadCurrentProfile();

    if (mounted) Navigator.of(context).pop();
  }
}
