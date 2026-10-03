import 'package:flutter/material.dart';

class NewAlertScreen extends StatelessWidget {
  const NewAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowy alert')),
      body: const SizedBox.shrink(),
    );
  }
}
