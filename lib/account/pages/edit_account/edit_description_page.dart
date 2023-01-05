import 'package:flutter/material.dart';
import 'package:flutter_app/util/supabase.dart';

import '../../../util/big_button.dart';
import '../../models/profile.dart';

class EditDescriptionPage extends StatelessWidget {
  final Profile profile;
  final TextEditingController _controller = TextEditingController();

  EditDescriptionPage(this.profile, {super.key}) {
    _controller.text = profile.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit description'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            TextField(
              maxLines: 10,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter a description',
                suffixIcon: _getClearButton(),
              ),
              controller: _controller,
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

  Widget? _getClearButton() {
    if (_controller.text == '') {
      return null;
    }
    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => _controller.clear(),
    );
  }

  void onPressed(context) async {
    String? text = _controller.text == '' ? null : _controller.text;
    await supabaseClient.from('profiles').update({
      'description': text,
    }).eq('id', profile.id);
    Navigator.of(context).pop();
  }
}
