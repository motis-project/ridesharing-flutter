import 'package:flutter/material.dart';

class SearchCard extends StatelessWidget {
  const SearchCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 150.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
      ),
    );
  }
}
