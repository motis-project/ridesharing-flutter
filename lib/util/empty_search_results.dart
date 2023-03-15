import 'package:flutter/material.dart';

class EmptySearchResults extends StatelessWidget {
  final String asset;
  final double? scale;
  final String title;
  final Widget? subtitle;
  const EmptySearchResults({super.key, required this.asset, this.scale, required this.title, this.subtitle});

  factory EmptySearchResults.shrug({Key? key, double? scale, required String title, Widget? subtitle}) =>
      EmptySearchResults(
        key: key,
        asset: 'assets/shrug.png',
        scale: scale,
        title: title,
        subtitle: subtitle,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 10),
        Image.asset(asset, scale: scale),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) subtitle!,
      ],
    );
  }
}
