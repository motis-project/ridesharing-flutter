import 'package:flutter/material.dart';
import 'package:flutter_app/util/submit_button.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<Widget> faqCards = const [
    FAQCard(
      question: "What can this app do?",
      answer: "With the MOTIS Ride App, you can do a lot of useful stuff!",
    ),
    FAQCard(
      question: "Where are the accessibility settings?",
      answer:
          "This app supports a multitude of accessibility settings offered by the OS. Go to your OS's settings to enable Screen Reader or large fonts!",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          children: faqCards +
              [
                const Divider(
                  thickness: 1,
                ),
                SubmitButton(
                  text: "Contact us",
                  onPressed: () => print("Contact"),
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
                        Text(
                          widget.answer,
                          textAlign: TextAlign.start,
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
