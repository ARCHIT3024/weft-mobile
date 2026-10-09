/// Form validators that mirror the backend's request rules exactly, so the
/// client rejects what the server would reject — and nothing more.
///
/// Source of truth: `weft-backend/app/schemas/auth.py` (`RegisterRequest`,
/// `LoginRequest`) and `weft-backend/app/schemas/user.py`.
///
/// Each validator returns `null` when valid, otherwise an error message
/// (Flutter `FormField.validator` convention).
///
/// NOTE (task 4.13): messages are English literals for now. When ARB
/// localisation lands, swap the strings for `AppLocalizations` lookups — the
/// validators already take no BuildContext, so pass the localised messages in
/// or wrap these functions.
library;

class Validators {
  Validators._();

  /// `EMAIL_PATTERN` in schemas/auth.py — a pragmatic shape check.
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// `EMAIL_MAX_LENGTH`.
  static const int emailMaxLength = 255;

  /// `PASSWORD_MIN_LENGTH` (registration only — login has no length rule so
  /// that legacy/temporary credentials still authenticate).
  static const int passwordMinLength = 8;

  /// `RegisterRequest.name` / `UpdateProfileRequest.name` max_length.
  static const int nameMaxLength = 100;

  /// `RegisterRequest.phone` max_length (phone is optional).
  static const int phoneMaxLength = 20;

  /// The backend strips whitespace and lower-cases emails before validating
  /// and storing them; do the same before sending.
  static String normaliseEmail(String raw) => raw.trim().toLowerCase();

  static String? email(String? value) {
    final v = normaliseEmail(value ?? '');
    if (v.isEmpty) return 'Enter your email address';
    if (v.length > emailMaxLength) {
      return 'Email must be at most $emailMaxLength characters';
    }
    if (!emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Login: any non-empty password (no length rule on `LoginRequest`).
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  /// Registration: at least [passwordMinLength] characters. The backend
  /// imposes no complexity rule and no maximum, so neither does the client.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < passwordMinLength) {
      return 'Password must be at least $passwordMinLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Re-enter your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// `name` is a required field on `RegisterRequest` (max 100). The schema
  /// would accept an empty string, but a blank display name is never what a
  /// citizen means, so the client requires at least one visible character.
  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your name';
    if (v.length > nameMaxLength) {
      return 'Name must be at most $nameMaxLength characters';
    }
    return null;
  }

  /// Optional phone: empty is fine; otherwise at most 20 characters (the only
  /// server-side rule; uniqueness is checked by the server → 409).
  static String? optionalPhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (v.length > phoneMaxLength) {
      return 'Phone number must be at most $phoneMaxLength characters';
    }
    return null;
  }
}
