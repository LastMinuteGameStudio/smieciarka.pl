import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/models/alert.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UCPageHeader(title: 'Opis alertu'),
              const SizedBox(height: 24),
              Center(child: Text('ID: ${alert.id}')),
            ],
          ),
        ),
      ),
    );
  }
}
