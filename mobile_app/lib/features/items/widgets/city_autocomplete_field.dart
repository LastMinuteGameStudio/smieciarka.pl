import 'package:flutter/material.dart';
import 'package:uczciwa_cena/features/items/data/cities.dart';

/// Free-text city input that only accepts a city picked from the dropdown.
class CityAutocompleteField extends StatelessWidget {
  const CityAutocompleteField({super.key, required this.onChanged});

  /// Called with the picked city, or `null` when the picked city is edited.
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (value) => value == null ? 'Wybierz miasto z listy' : null,
      builder: (field) {
        return Autocomplete<String>(
          optionsBuilder: (textValue) {
            final query = textValue.text.toLowerCase();
            if (query.isEmpty) {
              return const Iterable<String>.empty();
            }
            return polishCities.where(
              (city) => city.toLowerCase().contains(query),
            );
          },
          onSelected: (city) {
            field.didChange(city);
            onChanged(city);
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (text) {
                if (field.value != null && text != field.value) {
                  field.didChange(null);
                  onChanged(null);
                }
              },
              onSubmitted: (_) => onSubmitted(),
              decoration: InputDecoration(
                labelText: 'Miasto odbioru *',
                errorText: field.errorText,
              ),
            );
          },
        );
      },
    );
  }
}
