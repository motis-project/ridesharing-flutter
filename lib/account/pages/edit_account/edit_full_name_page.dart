import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/big_button.dart';
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: S.of(context).pageProfileEditSurnameHint,
                suffixIcon: _getClearButton(_surnameController),
              ),
              controller: _surnameController,
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: S.of(context).pageProfileEditNameHint,
                suffixIcon: _getClearButton(_nameController),
              ),
              controller: _nameController,
            ),
            const SizedBox(
              height: 10,
            ),
            BigButton(
              onPressed: () => onPressed(context),
              text: S.of(context).save,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _getClearButton(TextEditingController controller) {
    if (controller.text == '') {
      return null;
    }
    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => controller.clear(),
    );
  }

  void onPressed(context) async {
    String? surname = _surnameController.text == '' ? null : _surnameController.text;
    String? name = _nameController.text == '' ? null : _nameController.text;
    await supabaseClient.from('profiles').update({
      'surname': surname,
      'name': name,
    }).eq('id', profile.id);
    Navigator.of(context).pop();
  }
}
