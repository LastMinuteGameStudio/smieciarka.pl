import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/alerts/data/alerts_repository.dart';
import 'package:uczciwa_cena/features/alerts/widgets/search_area_picker.dart';
import 'package:uczciwa_cena/models/search_area.dart';

class NewAlertScreen extends StatefulWidget {
  const NewAlertScreen({super.key});

  @override
  State<NewAlertScreen> createState() => _NewAlertScreenState();
}

class _NewAlertScreenState extends State<NewAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repository = GetIt.instance<AlertsRepository>();

  SearchArea? _area;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  Future<void> _submit() async {
    final area = _area;
    if (!(_formKey.currentState?.validate() ?? false) || area == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repository.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        area: area,
      );
      if (mounted) {
        context.pop();
      }
    } on DioException {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się utworzyć alertu')),
        );
      }
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
                const UCPageHeader(title: 'Nowy alert'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa alertu *',
                  ),
                  maxLength: 60,
                  validator: (value) =>
                      _validateRequired(value, 'Podaj nazwę alertu'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis poszukiwanego przedmiotu *',
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  maxLength: 200,
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
                  validator: (_) => _area == null
                      ? 'Zaznacz obszar poszukiwań na mapie'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SearchAreaPicker(
                        onChanged: (area) {
                          _area = area;
                          field.didChange(area);
                        },
                      ),
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
                UCButton(
                  label: _submitting ? 'Zapisywanie…' : 'Utwórz alert',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
