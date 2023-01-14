import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/buttons/button.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/profile.dart';

class EditBirthDatePage extends StatefulWidget {
  final Profile profile;
  const EditBirthDatePage(this.profile, {super.key});

  @override
  State<EditBirthDatePage> createState() => _EditBirthDatePageState();
}

class _EditBirthDatePageState extends State<EditBirthDatePage> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _date = widget.profile.birthDate;
    _controller.text = _date == null ? '' : localeManager.formatDate(_date!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageProfileEditBirthDateTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: S.of(context).pageProfileEditBirthDateHint,
                  suffixIcon: _getClearButton(),
                ),
                readOnly: true,
                onTap: _showDatePicker,
                controller: _controller,
              ),
              const SizedBox(
                height: 10,
              ),
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

  Widget? _getClearButton() {
    if (_controller.text == '') {
      return null;
    }
    return IconButton(
      tooltip: S.of(context).formClearInput,
      icon: const Icon(Icons.clear),
      onPressed: () {
        _controller.clear();
        _date = null;
      },
    );
  }

  void _showDatePicker() async {
    final twelveYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 12));
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: twelveYearsAgo,
      firstDate: DateTime(1900),
      lastDate: twelveYearsAgo,
    );
    setState(() {
      _controller.text = date == null ? '' : localeManager.formatDate(date);
      _date = date;
    });
  }

  void onPressed() async {
    final date = _date == null ? null : _date!.toString();
    await SupabaseManager.supabaseClient.from('profiles').update({
      'birth_date': date,
    }).eq('id', widget.profile.id);
    SupabaseManager.reloadCurrentProfile();

    if (mounted) Navigator.of(context).pop();
  }
}
