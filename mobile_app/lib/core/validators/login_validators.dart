abstract final class LoginValidators {
  static final _uppercase = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');

  static String? password(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Podaj hasło';
    }
    if (!_uppercase.hasMatch(password)) {
      return 'Hasło musi zawierać wielką literę';
    }
    if (!_digit.hasMatch(password)) {
      return 'Hasło musi zawierać cyfrę';
    }
    return null;
  }
}
