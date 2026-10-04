class UserProfile {
  const UserProfile({required this.phoneNumber, required this.isSubscribed});

  /// E.164, e.g. `+48600000000`.
  final String phoneNumber;

  /// Demo flag toggled from the profile. No payment is involved yet.
  final bool isSubscribed;
}
