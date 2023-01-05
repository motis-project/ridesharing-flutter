import 'package:flutter/material.dart';
import 'package:flutter_app/util/supabase.dart';

import '../../../util/big_button.dart';
import '../../models/profile.dart';

class EditUsernamePage extends StatelessWidget {
  final Profile profile;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  EditUsernamePage(this.profile, {super.key}) {
    _controller.text = profile.username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit username'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 15,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter a username',
                  suffixIcon: _getClearButton(),
                ),
                controller: _controller,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username cannot be empty';
                  }
                  return null;
                },
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await supabaseClient.from('profiles').update({
      'username': _controller.text,
    }).eq('id', profile.id);
    Navigator.of(context).pop();
  }
}
