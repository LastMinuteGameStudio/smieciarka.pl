import 'package:flutter_test/flutter_test.dart';
import 'package:uczciwa_cena/core/validators/contact_validators.dart';

void main() {
  group('phone', () {
    test('requires exactly 9 digits', () {
      expect(ContactValidators.phone('123456789'), isNull);
      expect(ContactValidators.phone('12345678'), isNotNull);
      expect(ContactValidators.phone('1234567890'), isNotNull);
      expect(ContactValidators.phone('12345678a'), isNotNull);
      expect(ContactValidators.phone(''), isNotNull);
    });
  });

  group('otpCode', () {
    test('requires exactly 6 digits', () {
      expect(ContactValidators.otpCode('123456'), isNull);
      expect(ContactValidators.otpCode('12345'), isNotNull);
      expect(ContactValidators.otpCode('1234567'), isNotNull);
      expect(ContactValidators.otpCode('12a456'), isNotNull);
      expect(ContactValidators.otpCode(''), isNotNull);
    });
  });
}
