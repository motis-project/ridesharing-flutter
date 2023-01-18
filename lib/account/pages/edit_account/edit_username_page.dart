import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/buttons/button.dart';
import '../../../util/supabase.dart';
import '../../models/profile.dart';

class EditUsernamePage extends StatefulWidget {
  final Profile profile;

  const EditUsernamePage(this.profile, {super.key});

  @override
  State<EditUsernamePage> createState() => _EditUsernamePageState();
}

class _EditUsernamePageState extends State<EditUsernamePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.profile.username;
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
                  maxLength: 15,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: S.of(context).pageProfileEditUsernameHint,
                    suffixIcon: _getClearButton(),
                  ),
                  controller: _controller,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).pageProfileEditUsernameValidateEmpty;
                    }
                    return null;
                  },
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
      ),
    );
  }

  Widget? _getClearButton() {
    if (_controller.text == '') {
      return null;
    }
    return IconButton(
      tooltip: S.of(context).formClearInput,
      icon: const Icon(Icons.clear),
      onPressed: () => _controller.clear(),
    );
  }

  Future<void> onPressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await SupabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'username': _controller.text,
    }).eq('id', widget.profile.id);
    SupabaseManager.reloadCurrentProfile();

    if (mounted) Navigator.of(context).pop();
  }
}
