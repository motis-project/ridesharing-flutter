import 'package:flutter/material.dart';

class SearchDetailPage extends StatefulWidget {
  const SearchDetailPage({super.key});

  @override
  State<SearchDetailPage> createState() => _SearchDetailPage();
}

class _SearchDetailPage extends State<SearchDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Detail'),
      ),
      body: const Center(
        child: Text('Search Detail'),
      ),
    );
  }
}