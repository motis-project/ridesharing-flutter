import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../managers/supabase_manager.dart';
import '../../../util/buttons/button.dart';
import '../../models/profile.dart';

class EditFullNamePage extends StatelessWidget {
  final Profile profile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  EditFullNamePage(this.profile, {super.key}) {
    _nameController.text = profile.name ?? '';
    _surnameController.text = profile.surname ?? '';
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
                  suffixIcon: _getClearButton(_surnameController, context),
                ),
                controller: _surnameController,
                key: const Key('surname'),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditNameHint,
                  suffixIcon: _getClearButton(_nameController, context),
                ),
                controller: _nameController,
                key: const Key('name'),
              ),
              const SizedBox(height: 10),
              Button(
                S.of(context).save,
                onPressed: () => onPressed(context),
                key: const Key('saveButton'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _getClearButton(TextEditingController controller, BuildContext context) {
    if (controller.text == '') {
      return null;
    }
    return IconButton(
      tooltip: S.of(context).formClearInput,
      icon: const Icon(Icons.clear),
      onPressed: () => controller.clear(),
      key: const Key('clearButton'),
    );
  }

  Future<void> onPressed(BuildContext context) async {
    final String? surname = _surnameController.text == '' ? null : _surnameController.text;
    final String? name = _nameController.text == '' ? null : _nameController.text;
    await supabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'surname': surname,
      'name': name,
    }).eq('id', profile.id);
    await supabaseManager.reloadCurrentProfile();

    if (context.mounted) Navigator.of(context).pop();
  }
}
