import 'package:flutter/material.dart';

class EmptySearchResults extends StatelessWidget {
  final String asset;
  final double? scale;
  final String title;
  final Widget? subtitle;
  const EmptySearchResults({super.key, required this.asset, this.scale, required this.title, this.subtitle});

  static const String shrugAsset = 'assets/shrug.png';
  static const String pointingUpAsset = 'assets/pointing_up.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
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
      ),
    );
  }
}
