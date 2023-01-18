import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/supabase.dart';
import '../models/profile.dart';
import '../models/report.dart';

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
                children: <Widget>[
                  Column(
                    children: List<RadioListTile<ReportCategory>>.generate(
                      ReportCategory.values.length,
                      (int index) {
                        final ReportCategory category = ReportCategory.values[index];
                        return RadioListTile<ReportCategory>(
                          visualDensity: VisualDensity.compact,
                          title: Row(children: <Widget>[
                            category.getIcon(context),
                            const SizedBox(width: 15),
                            Expanded(child: Text(category.getDescription(context))),
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
                    validator: (String? value) {
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

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _state = ButtonState.loading;
    });

    final Report report = Report(
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
