class Item {
  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.phoneNumber,
    this.pickupLocation,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String description;
  final String phoneNumber;

  /// `null` when the owner hasn't provided a pickup location.
  final String? pickupLocation;
  final List<String> imageUrls;
}
