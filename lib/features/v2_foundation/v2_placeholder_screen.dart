import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class V2PlaceholderScreen extends StatelessWidget {
  const V2PlaceholderScreen(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    assert(
        !kReleaseMode, 'V2 placeholder routes must not be shown in release.');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('V2 development placeholder')),
    );
  }
}
