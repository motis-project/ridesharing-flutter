import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/buttons/button.dart';
import '../../../util/supabase_manager.dart';
import '../../models/profile.dart';

class EditDescriptionPage extends StatefulWidget {
  final Profile profile;

  const EditDescriptionPage(this.profile, {super.key});

  @override
  State<EditDescriptionPage> createState() => _EditDescriptionPageState();
}

class _EditDescriptionPageState extends State<EditDescriptionPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.profile.description ?? '';
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
                  suffixIcon: _getClearButton(),
                ),
                controller: _controller,
                key: const Key('description'),
              ),
              const SizedBox(height: 10),
              Button(
                S.of(context).save,
                onPressed: onPressed,
                key: const Key('saveButton'),
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
      tooltip: S.of(context).formClearInput,
      icon: const Icon(Icons.clear),
      onPressed: () => _controller.clear(),
      key: const Key('clearButton'),
    );
  }

  Future<void> onPressed() async {
    final String? text = _controller.text == '' ? null : _controller.text;
    await supabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'description': text,
    }).eq('id', widget.profile.id);
    await supabaseManager.reloadCurrentProfile();

    if (mounted) Navigator.of(context).pop();
  }
}
