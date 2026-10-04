class Item {
  const Item({
    required this.id,
    required this.name,
    required this.description,
    this.phoneNumber,
    this.pickupLocation,
    this.imageUrls = const [],
    this.isMine = false,
  });

  final String id;
  final String name;
  final String description;

  /// The author's phone, shared on the listing. `null` when not provided.
  final String? phoneNumber;

  /// `null` when the owner hasn't provided a pickup location.
  final String? pickupLocation;
  final List<String> imageUrls;

  /// True for the signed-in user's own listings; only those can be deleted.
  final bool isMine;
}
