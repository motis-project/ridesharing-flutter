import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../util/buttons/button.dart';
import '../../../util/supabase.dart';
import '../../models/profile.dart';

class EditGenderPage extends StatefulWidget {
  final Profile profile;

  const EditGenderPage(this.profile, {super.key});

  @override
  State<EditGenderPage> createState() => _EditGenderPageState();
}

class _EditGenderPageState extends State<EditGenderPage> {
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    _gender = widget.profile.gender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageProfileEditGenderTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: <Widget>[
              ...List<RadioListTile<Gender?>>.generate(
                Gender.values.length + 1,
                (int index) {
                  if (index < Gender.values.length) {
                    final Gender gender = Gender.values[index];
                    return RadioListTile<Gender>(
                      title: Text(gender.getName(context)),
                      value: gender,
                      groupValue: _gender,
                      onChanged: (Gender? value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    );
                  }
                  return RadioListTile<Gender?>(
                    title: Text(S.of(context).pageProfileEditGenderPreferNotToSay),
                    value: null,
                    groupValue: _gender,
                    onChanged: (Gender? value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  );
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
    );
  }

  Future<void> onPressed() async {
    await SupabaseManager.supabaseClient.from('profiles').update(<String, dynamic>{
      'gender': _gender?.index,
    }).eq('id', widget.profile.id);
    await SupabaseManager.reloadCurrentProfile();

    if (mounted) Navigator.of(context).pop();
  }
}
