import 'package:flutter/material.dart';

class NewItemScreen extends StatelessWidget {
  const NewItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowe ogłoszenie')),
      body: const SizedBox.shrink(),
    );
  }
}
