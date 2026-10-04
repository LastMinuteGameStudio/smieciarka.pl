import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_button.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/items/widgets/item_photos_picker.dart';
import 'package:uczciwa_cena/features/items/widgets/pickup_date_field.dart';
import 'package:uczciwa_cena/features/items/widgets/pickup_location_picker.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();

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
    // TODO: send the listing (name, description, pin, date, photos) to the backend.
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
                const SizedBox(height: 24),
                const Text(
                  'Miejsce odbioru *',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                FormField<LatLng>(
                  validator: (point) =>
                      point == null ? 'Zaznacz miejsce odbioru na mapie' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PickupLocationPicker(onChanged: field.didChange),
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
