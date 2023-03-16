import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../config.dart';
import '../../managers/supabase_manager.dart';
import '../../util/buttons/button.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<Widget> getFaqCards() => <Widget>[
        FAQCard(
          question: S.of(context).pageHelpQuestion1,
          answer: S.of(context).pageHelpAnswer1,
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion2,
          answer: S.of(context).pageHelpAnswer2,
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion3,
          answer: S
              .of(context)
              .pageHelpAnswer3(S.of(context).pageProfileButtonReport, S.of(context).modelReportReasonDidNotPay),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion4,
          answer: S
              .of(context)
              .pageHelpAnswer4(S.of(context).pageProfileButtonReport, S.of(context).modelReportReasonDidNotShowUp),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion5,
          answer: S
              .of(context)
              .pageHelpAnswer5(S.of(context).pageProfileButtonReport, S.of(context).modelReportReasonOther),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion6,
          answer: S.of(context).pageHelpAnswer6,
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion7,
          answer: S.of(context).pageHelpAnswer7(S.of(context).pageRideDetailButtonWithdraw),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion8,
          answer: S.of(context).pageHelpAnswer8(S.of(context).pageProfileButtonReport),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion9,
          answer: S.of(context).pageHelpAnswer9(S.of(context).pageAccountTitle),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion10,
          answer: S.of(context).pageHelpAnswer10(S.of(context).pageDrivesTitle),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion11,
          answer: S.of(context).pageHelpAnswer11(S.of(context).pageRidesTitle),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion12,
          answer: S.of(context).pageHelpAnswer12(S.of(context).pageRideDetailButtonRate),
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion13,
          answer: S.of(context).pageHelpAnswer13,
        ),
        FAQCard(
          question: S.of(context).pageHelpQuestion14,
          answer: S.of(context).pageHelpAnswer14(S.of(context).pageHelpContactUs),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageHelpTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          children: getFaqCards() +
              <Widget>[
                const Divider(
                  thickness: 1,
                ),
                Button.submit(
                  S.of(context).pageHelpContactUs,
                  onPressed: () => launchUrlString(
                    'mailto:${Config.emailAddress}?'
                    'subject=${S.of(context).pageHelpEmailSubject(supabaseManager.currentProfile!.id!)}',
                  ),
                ),
              ],
        ),
      ),
    );
  }
}

class FAQCard extends StatefulWidget {
  final String question;
  final String answer;

  const FAQCard({super.key, required this.question, required this.answer});

  @override
  State<FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<FAQCard> {
  @override
  Widget build(BuildContext context) {
    final Widget question = Text(
      widget.question,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: question,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.answer,
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
