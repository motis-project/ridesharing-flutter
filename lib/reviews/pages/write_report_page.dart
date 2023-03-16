import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../account/models/profile.dart';
import '../../account/widgets/profile_widget.dart';
import '../../managers/supabase_manager.dart';
import '../../util/buttons/loading_button.dart';
import '../models/report.dart';

class WriteReportPage extends StatefulWidget {
  final Profile profile;

  const WriteReportPage(this.profile, {super.key});

  @override
  State<WriteReportPage> createState() => _WriteReportPageState();
}

class _WriteReportPageState extends State<WriteReportPage> {
  ReportReason? _reason = ReportReason.other;
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
                    children: List<RadioListTile<ReportReason>>.generate(
                      ReportReason.values.length,
                      (int index) {
                        final ReportReason reason = ReportReason.values[index];
                        return RadioListTile<ReportReason>(
                          key: Key('writeReportReason${reason.name}'),
                          visualDensity: VisualDensity.compact,
                          title: Row(
                            children: <Widget>[
                              reason.getIcon(context),
                              const SizedBox(width: 15),
                              Expanded(child: Text(reason.getDescription(context))),
                            ],
                          ),
                          value: reason,
                          groupValue: _reason,
                          onChanged: (ReportReason? value) {
                            setState(() {
                              _reason = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('writeReportField'),
                    controller: _textController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: S.of(context).pageWriteReportField,
                      hintText: S.of(context).pageWriteReportFieldHint,
                      alignLabelWithHint: true,
                    ),
                    textAlignVertical: TextAlignVertical.top,
                    maxLines: 6,
                    validator: (String? value) {
                      if ((value == null || value.isEmpty) && _reason == ReportReason.other) {
                        return S.of(context).pageWriteReportFieldValidateEmpty;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  LoadingButton(
                    key: const Key('writeReportButton'),
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
      reporterId: supabaseManager.currentProfile!.id!,
      reason: _reason!,
      text: _textController.text,
    );

    await supabaseManager.supabaseClient.from('reports').insert(report.toJson());

    setState(() {
      _state = ButtonState.success;
    });

    if (mounted) await Navigator.of(context).maybePop(true);
  }
}
