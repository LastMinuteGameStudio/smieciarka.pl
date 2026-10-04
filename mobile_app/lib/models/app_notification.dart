/// A match the backend found: a new listing that fits one of the user's alerts.
class AppNotification {
  const AppNotification({required this.id, required this.listingId});

  final String id;
  final String listingId;
}
