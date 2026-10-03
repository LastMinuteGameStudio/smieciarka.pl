import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/app/app_routes.dart';
import 'package:uczciwa_cena/core/auth/auth_repository.dart';
import 'package:uczciwa_cena/core/validators/contact_validators.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final _auth = GetIt.instance<AuthRepository>();

  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await _run(
      errorMessage: 'Nie udało się wysłać kodu. Spróbuj ponownie.',
      action: () async {
        await _auth.requestCode(_phoneController.text);
        if (!mounted) {
          return;
        }
        setState(() => _codeSent = true);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _codeFocus.requestFocus(),
        );
      },
    );
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await _run(
      errorMessage: 'Nieprawidłowy kod. Spróbuj ponownie.',
      action: () async {
        await _auth.verifyCode(_phoneController.text, _codeController.text);
        if (mounted) {
          context.go(AppRoutes.items);
        }
      },
    );
  }

  void _changeNumber() {
    setState(() {
      _codeSent = false;
      _codeController.clear();
    });
  }

  Future<void> _run({
    required Future<void> Function() action,
    required String errorMessage,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UCPageHeader(title: 'Logowanie'),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_codeSent,
                  decoration: const InputDecoration(
                    labelText: 'Nr telefonu',
                    prefixText: '+48 ',
                    hintText: '123 456 789',
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _sendCode(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      ContactValidators.phoneLength,
                    ),
                  ],
                  validator: ContactValidators.phone,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    focusNode: _codeFocus,
                    decoration: const InputDecoration(
                      labelText: 'Kod z SMS',
                      hintText: '123456',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        ContactValidators.otpLength,
                      ),
                    ],
                    validator: ContactValidators.otpCode,
                  ),
                ],
                const SizedBox(height: 24),
                UCButton(
                  label: _codeSent ? 'Zaloguj' : 'Wyślij kod',
                  onPressed: _busy ? null : (_codeSent ? _login : _sendCode),
                ),
                if (_codeSent)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _changeNumber,
                      child: const Text('Zmień numer'),
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.go(AppRoutes.items),
                    child: const Text(
                      'Kontynuuj bez logowania',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
