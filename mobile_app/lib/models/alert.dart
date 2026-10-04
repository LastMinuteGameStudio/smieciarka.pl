import 'package:uczciwa_cena/models/search_area.dart';

class Alert {
  const Alert({
    required this.id,
    required this.name,
    required this.description,
    this.area,
  });

  final String id;
  final String name;

  /// What the user is looking for. Capped at 200 characters.
  final String description;

  /// Only listings inside this area match the alert. `null` for nationwide.
  final SearchArea? area;
}
