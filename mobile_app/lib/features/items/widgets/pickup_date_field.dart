import 'package:flutter/material.dart';

class PickupDateField extends StatelessWidget {
  const PickupDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final date = value;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _pickDate(context),
      child: InputDecorator(
        isEmpty: date == null,
        decoration: InputDecoration(
          labelText: 'Termin odbioru (opcjonalnie)',
          suffixIcon: date == null
              ? const Icon(Icons.calendar_today_rounded)
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(date == null ? '' : _formatDate(date)),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
