import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

/// Named `AppAuthState` to avoid colliding with Supabase's own `AuthState`.
sealed class AppAuthState extends Equatable {
  const AppAuthState();

  @override
  List<Object?> get props => [];
}

/// Before the first auth event has been received.
class AuthInitial extends AppAuthState {
  const AuthInitial();
}

class AuthAuthenticated extends AppAuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AppAuthState {
  const AuthUnauthenticated();
}

/// A sign-in/sign-up attempt failed. The ambient session is unchanged, so
/// the UI should present [message] and let the user retry.
class AuthError extends AppAuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
