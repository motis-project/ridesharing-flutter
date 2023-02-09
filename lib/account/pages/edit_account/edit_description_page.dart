import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/buttons/button.dart';
import '../../../util/supabase_manager.dart';
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
            children: <Widget>[
              TextField(
                maxLines: 10,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditDescriptionHint,
                  suffixIcon: _getClearButton(context),
                ),
                controller: _controller,
                key: const Key('description'),
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
    final String? text = _controller.text == '' ? null : _controller.text;
    await supabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'description': text,
    }).eq('id', profile.id);
    await supabaseManager.reloadCurrentProfile();

    if (context.mounted) Navigator.of(context).pop();
  }
}
