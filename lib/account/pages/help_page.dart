import 'package:flutter/material.dart';
import 'package:flutter_app/util/big_button.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<FAQ> faqs = [
    FAQ(question: "What can this app do?", answer: "With the MOTIS Ride App, you can do a lot of useful stuff!"),
    FAQ(
        question: "Where are the accessibility settings?",
        answer:
            "This app supports a multitude of accessibility settings offered by the OS. Go to your OS's settings to enable Screen Reader or large fonts!"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Help'),
        ),
        body: ListView(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(faqs.length, (index) => faqs[index].card),
            ),
            const BigButton(
              text: "Contact us",
            ),
          ],
        ));
  }
}

class FAQ {
  final String question;
  final String answer;
  final FAQCard card;

  FAQ({required this.question, required this.answer}) : card = FAQCard(question: question, answer: answer);
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
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    return Card(
      child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
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
              : question),
    );
  }
}
