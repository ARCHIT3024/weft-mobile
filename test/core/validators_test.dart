import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/core/validators.dart';

/// Rules mirror weft-backend/app/schemas/auth.py RegisterRequest/LoginRequest.
void main() {
  group('email (EMAIL_PATTERN ^[^@\\s]+@[^@\\s]+\\.[^@\\s]+\$, max 255)', () {
    test('valid', () {
      for (final v in [
        'citizen@weft.local',
        'A.B+tag@Example.CO.in',
        '  padded@weft.city  ', // backend strips whitespace
      ]) {
        expect(Validators.email(v), isNull, reason: v);
      }
    });

    test('invalid', () {
      for (final v in [
        null,
        '',
        'plain',
        'no-at.example.com',
        'a@b',
        'a b@c.com',
        'a@b c.com',
        'a@@b.com',
      ]) {
        expect(Validators.email(v), isNotNull, reason: '$v');
      }
    });

    test('max length 255', () {
      final ok = '${'a' * 245}@weft.city'; // 255
      expect(ok.length, 255);
      expect(Validators.email(ok), isNull);
      expect(Validators.email('a$ok'), isNotNull);
    });

    test('normalised like the backend (strip + lowercase)', () {
      expect(
        Validators.normaliseEmail('  Citizen@WEFT.Local '),
        'citizen@weft.local',
      );
    });
  });

  group('passwords', () {
    test('registration: min 8, no complexity rule, no max', () {
      expect(Validators.newPassword(null), isNotNull);
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('1234567'), isNotNull);
      expect(Validators.newPassword('12345678'), isNull);
      expect(Validators.newPassword('aaaaaaaa'), isNull);
      expect(Validators.newPassword('x' * 500), isNull);
    });

    test('login: any non-empty password (no length rule)', () {
      expect(Validators.loginPassword(''), isNotNull);
      expect(Validators.loginPassword('a'), isNull);
    });

    test('confirm must match', () {
      expect(Validators.confirmPassword('', 'abcdefgh'), isNotNull);
      expect(
        Validators.confirmPassword('abcdefgx', 'abcdefgh'),
        'Passwords do not match',
      );
      expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
    });
  });

  group('name / phone', () {
    test('name required, max 100', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('   '), isNotNull);
      expect(Validators.name('Kavitha'), isNull);
      expect(Validators.name('x' * 100), isNull);
      expect(Validators.name('x' * 101), isNotNull);
    });

    test('phone optional, max 20', () {
      expect(Validators.optionalPhone(null), isNull);
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone('+91 98765 43210'), isNull);
      expect(Validators.optionalPhone('1' * 21), isNotNull);
    });
  });
}
