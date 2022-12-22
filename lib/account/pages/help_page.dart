import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/submit_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<Widget> getFaqCards() => [
        FAQCard(
          question: S.of(context).pageHelpWhatIsMotisQuestion,
          answer: S.of(context).pageHelpWhatIsMotisAnswer,
        ),
        FAQCard(
          question: S.of(context).pageHelpWhereIsAccessibilityQuestion,
          answer: S.of(context).pageHelpWhereIsAccessibilityAnswer,
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
              [
                const Divider(
                  thickness: 1,
                ),
                SubmitButton(
                  text: S.of(context).pageHelpContactUs,
                  onPressed: () => print("Contact TODO"),
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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    Widget question = Text(
      widget.question,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    return Hero(
      tag: question.hashCode,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _expanded
                  ? Column(
                      children: [
                        question,
                        const Divider(
                          thickness: 1,
                        ),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            widget.answer,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    )
                  : question,
            ),
          ),
        ),
      ),
    );
  }
}
