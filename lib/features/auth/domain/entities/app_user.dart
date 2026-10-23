// FILE: features/auth/domain/entities/app_user.dart
// The signed-in person, as the rest of the app sees them. Plain Dart: no Supabase types leak
// past the data layer.

import 'package:meta/meta.dart';

@immutable
class AppUser {
  const AppUser({required this.id, required this.email});
  final String id;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
