// FILE: features/auth/domain/entities/app_user.dart
// The signed-in person, as the rest of the app sees them: id, email, and the name they gave at
// sign-up. Plain Dart: no Supabase types leak past the data layer.

import 'package:meta/meta.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
  });

  final String id;
  final String email;

  /// Empty for accounts made before names were asked for; they can add one in the account sheet.
  final String firstName;
  final String lastName;

  bool get hasName => firstName.isNotEmpty;

  /// "Ada Lovelace", or the email when no name was given.
  String get displayName => hasName
      ? [firstName, lastName].where((p) => p.isNotEmpty).join(' ')
      : email;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.firstName == firstName &&
      other.lastName == lastName;

  @override
  int get hashCode => Object.hash(id, email, firstName, lastName);
}
