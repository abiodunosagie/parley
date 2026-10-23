// FILE: features/auth/domain/validators.dart
// Form rules for the sign-in screen. Pure functions: null means valid, text means what to fix.

String? validateEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())
    ? null
    : 'Enter a valid email address.';

/// Matches the server's rule (supabase/config.toml: minimum_password_length = 8).
String? validateNewPassword(String password) =>
    password.length >= 8 ? null : 'Use at least 8 characters.';

String? validateExistingPassword(String password) =>
    password.isEmpty ? 'Enter your password.' : null;
