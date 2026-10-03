import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/validators/contact_validators.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    // TODO: send the profile to the backend.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Zapisano zmiany')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UCPageHeader(title: 'Profil'),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nr telefonu *'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      ContactValidators.phoneLength,
                    ),
                  ],
                  validator: ContactValidators.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Adres zamieszkania',
                  ),
                ),
                const SizedBox(height: 32),
                UCButton(label: 'Zapisz zmiany', onPressed: _save),
                const SizedBox(height: 48),
                UCButton(
                  label: 'Kup subskrypcję',
                  onPressed: () => context.push(AppRoutes.subscription),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
