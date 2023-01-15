import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/report.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WriteReportPage extends StatefulWidget {
  final Profile profile;

  const WriteReportPage(this.profile, {super.key});

  @override
  State<WriteReportPage> createState() => _WriteReportPageState();
}

class _WriteReportPageState extends State<WriteReportPage> {
  ReportCategory? _category = ReportCategory.other;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  ButtonState _state = ButtonState.idle;

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ProfileWidget(widget.profile),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Column(
                    children: List.generate(
                      ReportCategory.values.length,
                      (index) {
                        final category = ReportCategory.values[index];
                        return RadioListTile(
                          visualDensity: VisualDensity.compact,
                          title: Row(children: [
                            category.getIcon(context),
                            const SizedBox(width: 15),
                            Text(category.getDescription(context)),
                          ]),
                          value: category,
                          groupValue: _category,
                          onChanged: (ReportCategory? value) {
                            setState(() {
                              _category = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: S.of(context).pageWriteReportField,
                      hintText: S.of(context).pageWriteReportFieldHint,
                      alignLabelWithHint: true,
                    ),
                    textAlignVertical: TextAlignVertical.top,
                    maxLines: 5,
                    validator: (value) {
                      if ((value == null || value.isEmpty) && _category == ReportCategory.other) {
                        return S.of(context).pageWriteReportFieldValidateEmpty;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  LoadingButton(
                    onPressed: _onSubmit,
                    state: _state,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _state = ButtonState.loading;
    });

    final report = Report(
      offenderId: widget.profile.id!,
      reporterId: SupabaseManager.getCurrentProfile()!.id!,
      category: _category!,
      text: _textController.text,
    );

    await SupabaseManager.supabaseClient.from('reports').insert(report.toJson());

    setState(() {
      _state = ButtonState.success;
    });

    if (mounted) Navigator.of(context).maybePop(true);
  }
}
