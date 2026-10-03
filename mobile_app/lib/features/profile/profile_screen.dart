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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć konto?'),
        content: const Text('Tej operacji nie da się cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // TODO: delete the account on the backend.
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.welcome);
    }
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
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Link do profilu Facebook *',
                    hintText: 'https://www.facebook.com/twoj.profil',
                  ),
                  keyboardType: TextInputType.url,
                  validator: ContactValidators.facebookProfileUrl,
                ),
                const SizedBox(height: 32),
                UCButton(label: 'Zapisz zmiany', onPressed: _save),
                const SizedBox(height: 48),
                UCButton(
                  label: 'Kup subskrypcję',
                  onPressed: () => context.push(AppRoutes.subscription),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _confirmDeleteAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Usuń konto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
