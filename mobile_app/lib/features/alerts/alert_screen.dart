import 'package:flutter/material.dart';
import 'package:uczciwa_cena/models/alert.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alert')),
      body: Center(child: Text('ID: ${alert.id}')),
    );
  }
}
