import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/buttons/button.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        title: Text(S.of(context).pageProfileEditDescriptionTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              TextField(
                maxLines: 10,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditDescriptionHint,
                  suffixIcon: _getClearButton(context),
                ),
                controller: _controller,
              ),
              const SizedBox(
                height: 10,
              ),
              Button(
                S.of(context).save,
                onPressed: () => onPressed(context),
              ),
            ],
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
    );
  }

  void onPressed(context) async {
    String? text = _controller.text == '' ? null : _controller.text;
    await SupabaseManager.supabaseClient.from('profiles').update({
      'description': text,
    }).eq('id', profile.id);
    SupabaseManager.reloadCurrentProfile();

    Navigator.of(context).pop();
  }
}
