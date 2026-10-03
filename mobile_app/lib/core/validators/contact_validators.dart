abstract final class ContactValidators {
  static const phoneLength = 9;

  static final _digitsOnly = RegExp(r'^\d+$');
  static final _facebookHost = RegExp(r'^(www\.|m\.|web\.)?facebook\.com$');
  static final _facebookUsername = RegExp(r'^[A-Za-z0-9.]{5,}$');

  /// First path segments on facebook.com that are not user profiles.
  static const _nonProfilePaths = {
    'ads',
    'business',
    'events',
    'friends',
    'gaming',
    'groups',
    'help',
    'hashtag',
    'login',
    'marketplace',
    'messages',
    'notifications',
    'pages',
    'photo',
    'photos',
    'policies',
    'reel',
    'reels',
    'search',
    'settings',
    'share',
    'sharer',
    'stories',
    'watch',
  };

  static const _notAProfile = 'Link nie prowadzi do profilu użytkownika';

  static String? phone(String? value) {
    final number = value ?? '';

    if (number.isEmpty) {
      return 'Podaj numer telefonu';
    }
    if (!_digitsOnly.hasMatch(number)) {
      return 'Numer może zawierać tylko cyfry';
    }
    if (number.length != phoneLength) {
      return 'Numer musi mieć $phoneLength cyfr';
    }
    return null;
  }

  static String? facebookProfileUrl(String? value) {
    final url = value?.trim() ?? '';

    if (url.isEmpty) {
      return 'Podaj link do profilu Facebook';
    }

    final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
    if (uri == null || !_facebookHost.hasMatch(uri.host.toLowerCase())) {
      return 'Link musi prowadzić do facebook.com';
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return _notAProfile;
    }

    // Legacy profile links look like facebook.com/profile.php?id=<digits>.
    if (segments.first == 'profile.php') {
      final id = uri.queryParameters['id'];
      final hasNumericId = id != null && _digitsOnly.hasMatch(id);
      return hasNumericId ? null : _notAProfile;
    }

    final username = segments.first;
    final isNonProfile = _nonProfilePaths.contains(username.toLowerCase());
    if (isNonProfile || !_facebookUsername.hasMatch(username)) {
      return _notAProfile;
    }
    return null;
  }
}
