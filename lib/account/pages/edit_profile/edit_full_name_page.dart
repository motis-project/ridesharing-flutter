import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../managers/supabase_manager.dart';
import '../../../util/buttons/button.dart';
import '../../models/profile.dart';

class EditFullNamePage extends StatelessWidget {
  final Profile profile;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  EditFullNamePage(this.profile, {super.key}) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
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
                  hintText: S.of(context).pageProfileEditFirstNameHint,
                  suffixIcon: _getClearButton(_firstNameController, context),
                ),
                controller: _firstNameController,
                key: const Key('firstName'),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditLastNameHint,
                  suffixIcon: _getClearButton(_lastNameController, context),
                ),
                controller: _lastNameController,
                key: const Key('lastName'),
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
    final String? firstName = _firstNameController.text == '' ? null : _firstNameController.text;
    final String? lastName = _lastNameController.text == '' ? null : _lastNameController.text;
    await supabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
    }).eq('id', profile.id);
    await supabaseManager.reloadCurrentProfile();

    if (context.mounted) Navigator.of(context).pop();
  }
}
