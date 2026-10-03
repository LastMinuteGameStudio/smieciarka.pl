import 'package:flutter_test/flutter_test.dart';
import 'package:uczciwa_cena/core/validators/contact_validators.dart';

void main() {
  group('facebookProfileUrl', () {
    test('accepts links to user profiles', () {
      const validUrls = [
        'https://www.facebook.com/jan.kowalski',
        'facebook.com/jan.kowalski',
        'https://m.facebook.com/jan.kowalski',
        'https://www.facebook.com/profile.php?id=100012345678901',
        'https://www.facebook.com/people/Jan-Kowalski/100012345678901',
      ];

      for (final url in validUrls) {
        expect(ContactValidators.facebookProfileUrl(url), isNull, reason: url);
      }
    });

    test('rejects links that are not user profiles', () {
      const invalidUrls = [
        '',
        'https://example.com/jan.kowalski',
        'https://facebook.com.evil.com/jan.kowalski',
        'https://www.facebook.com/',
        'https://www.facebook.com/groups/12345',
        'https://www.facebook.com/pages/Sklep/123',
        'https://www.facebook.com/profile.php',
        'https://www.facebook.com/abc',
        'https://www.facebook.com/jan kowalski',
      ];

      for (final url in invalidUrls) {
        expect(
          ContactValidators.facebookProfileUrl(url),
          isNotNull,
          reason: url,
        );
      }
    });
  });

  group('phone', () {
    test('requires exactly 9 digits', () {
      expect(ContactValidators.phone('123456789'), isNull);
      expect(ContactValidators.phone('12345678'), isNotNull);
      expect(ContactValidators.phone('1234567890'), isNotNull);
      expect(ContactValidators.phone('12345678a'), isNotNull);
      expect(ContactValidators.phone(''), isNotNull);
    });
  });
}
