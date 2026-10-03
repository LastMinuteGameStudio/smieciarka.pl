import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/alerts/widgets/search_area_picker.dart';
import 'package:uczciwa_cena/models/search_area.dart';

class NewAlertScreen extends StatefulWidget {
  const NewAlertScreen({super.key});

  @override
  State<NewAlertScreen> createState() => _NewAlertScreenState();
}

class _NewAlertScreenState extends State<NewAlertScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    // TODO: send the alert and its search area to the backend.
    context.pop();
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
                const UCPageHeader(title: 'Nowy alert'),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nazwa alertu *',
                  ),
                  validator: (value) =>
                      _validateRequired(value, 'Podaj nazwę alertu'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Opis poszukiwanego przedmiotu *',
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: (value) =>
                      _validateRequired(value, 'Opisz poszukiwany przedmiot'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Obszar poszukiwań *',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                FormField<SearchArea>(
                  validator: (area) => area == null
                      ? 'Zaznacz obszar poszukiwań na mapie'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SearchAreaPicker(onChanged: field.didChange),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                UCButton(label: 'Utwórz alert', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
