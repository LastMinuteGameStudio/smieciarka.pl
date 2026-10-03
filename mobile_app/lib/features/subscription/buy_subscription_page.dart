import 'package:flutter/material.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';

class BuySubscriptionPage extends StatelessWidget {
  const BuySubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [const UCPageHeader(title: 'Subskrypcja')],
          ),
        ),
      ),
    );
  }
}
