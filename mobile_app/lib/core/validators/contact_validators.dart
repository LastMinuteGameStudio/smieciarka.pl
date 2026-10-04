abstract final class ContactValidators {
  static const phoneLength = 9;
  static const otpLength = 6;

  static final _digitsOnly = RegExp(r'^\d+$');

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

  static String? otpCode(String? value) {
    final code = value ?? '';

    if (code.isEmpty) {
      return 'Podaj kod z SMS';
    }
    if (!_digitsOnly.hasMatch(code) || code.length != otpLength) {
      return 'Kod musi mieć $otpLength cyfr';
    }
    return null;
  }
}
