import 'package:flutter/material.dart';
import 'package:uczciwa_cena/models/item.dart';

class ItemScreen extends StatelessWidget {
  const ItemScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ogłoszenie')),
      body: Center(child: Text('ID: ${item.id}')),
    );
  }
}
