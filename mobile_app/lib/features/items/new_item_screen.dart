import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/items/widgets/city_autocomplete_field.dart';
import 'package:uczciwa_cena/features/items/widgets/item_photos_picker.dart';
import 'package:uczciwa_cena/features/items/widgets/pickup_date_field.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _city;
  DateTime? _pickupDate;
  List<XFile> _photos = const [];

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Podaj nazwę przedmiotu';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    // TODO: send the listing to the backend.
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
                const UCPageHeader(title: 'Nowe ogłoszenie'),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nazwa przedmiotu *',
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcjonalnie)',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: null,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                CityAutocompleteField(
                  onChanged: (city) => setState(() => _city = city),
                ),
                if (_city != null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Adres (opcjonalnie)',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PickupDateField(
                  value: _pickupDate,
                  onChanged: (date) => setState(() => _pickupDate = date),
                ),
                const SizedBox(height: 24),
                ItemPhotosPicker(
                  photos: _photos,
                  onChanged: (photos) => setState(() => _photos = photos),
                ),
                const SizedBox(height: 32),
                UCButton(label: 'Wystaw ogłoszenie', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
