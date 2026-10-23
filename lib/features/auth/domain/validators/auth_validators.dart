// FILE: features/auth/domain/validators/auth_validators.dart
// Form rules for the sign-in screen and the name editor. Pure functions: null means valid, text
// means what to fix.

String? validateEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())
    ? null
    : 'Enter a valid email address.';

/// Matches the server's rule (supabase/config.toml: minimum_password_length = 8).
String? validateNewPassword(String password) =>
    password.length >= 8 ? null : 'Use at least 8 characters.';

String? validateExistingPassword(String password) =>
    password.isEmpty ? 'Enter your password.' : null;

const maxNameLength = 50;

// Letters from any alphabet, with the spaces, hyphens, apostrophes and full stops real names use
// (Mary-Jane, O'Neil, Chukwuemeka, José, St. John), and the zero-width joiners some Persian and
// Indic names are spelled with.
final _name = RegExp(r"^\p{L}[\p{L}\p{M} '’.\-\u200C\u200D]*$", unicode: true);

enum NamePart { first, last }

/// [part] names the box in the message ("Enter your first name.").
String? validateName(String value, {required NamePart part}) {
  final name = cleanName(value);
  if (name.isEmpty) return 'Enter your ${part.name} name.';
  // The boxes stop typing at the limit, so this one catches pasted or stored names.
  if (name.length > maxNameLength) {
    return 'Keep it under $maxNameLength characters.';
  }
  if (!_name.hasMatch(name)) {
    return "Use letters only, plus - or ' if your name has them.";
  }
  return null;
}

/// A name as it is saved: no spaces at the ends, single spaces inside.
String cleanName(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');
