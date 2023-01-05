import 'package:flutter/material.dart';
import 'package:flutter_app/util/supabase.dart';

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
        title: const Text('Edit full name'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter a first name',
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
                hintText: 'Enter a last name',
                suffixIcon: _getClearButton(_nameController),
              ),
              controller: _nameController,
            ),
            const SizedBox(
              height: 10,
            ),
            BigButton(
              onPressed: () => onPressed(context),
              text: 'Save',
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
