import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/buttons/button.dart';
import '../../../util/supabase_manager.dart';
import '../../models/profile.dart';

class EditUsernamePage extends StatelessWidget {
  final Profile profile;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  EditUsernamePage(this.profile, {super.key}) {
    _controller.text = profile.username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageProfileEditUsernameTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  maxLength: Profile.maxUsernameLength,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: S.of(context).pageProfileEditUsernameHint,
                    suffixIcon: _getClearButton(context),
                  ),
                  controller: _controller,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).pageProfileEditUsernameValidateEmpty;
                    }
                    return null;
                  },
                  key: const Key('usernameTextField'),
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
      ),
    );
  }

  Widget? _getClearButton(BuildContext context) {
    if (_controller.text == '') {
      return null;
    }
    return IconButton(
      tooltip: S.of(context).formClearInput,
      icon: const Icon(Icons.clear),
      onPressed: () => _controller.clear(),
      key: const Key('clearButton'),
    );
  }

  Future<void> onPressed(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await supabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'username': _controller.text,
    }).eq('id', profile.id);
    await supabaseManager.reloadCurrentProfile();
    if (context.mounted) Navigator.of(context).pop();
  }
}
