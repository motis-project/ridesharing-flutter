import 'package:flutter/material.dart';
import 'package:flutter_app/util/big_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: BigButton(
        text: "Yeah",
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomePage())),
      ),
    );
  }
}
