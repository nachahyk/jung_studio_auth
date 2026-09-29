import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AppAuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    _subscription = _repository.authStateChanges().listen(
      (user) => emit(user != null ? AuthAuthenticated(user) : const AuthUnauthenticated()),
      onError: (Object error) => emit(AuthError(error.toString())),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> signInAnonymously() async {
    try {
      await _repository.signInAnonymously();
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _repository.signInWithEmailPassword(email, password);
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  /// Returns `true` when the account needs email confirmation before a
  /// session is created.
  Future<bool> signUpWithEmailPassword(
    String email,
    String password, {
    required String fullName,
    String? phone,
    String? address,
  }) async {
    try {
      return await _repository.signUpWithEmailPassword(
        email,
        password,
        fullName: fullName,
        phone: phone,
        address: address,
      );
    } catch (error) {
      emit(AuthError(error.toString()));
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _repository.signInWithGoogle();
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> signOut() => _repository.signOut();

  /// Returns `true` on success. On failure, emits [AuthError] and leaves the
  /// caller to read [AppAuthState] for the message (matching the other
  /// sign-in/up methods' error-reporting convention).
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? address,
    double? addressLat,
    double? addressLng,
  }) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return false;

    try {
      final updated = await _repository.updateProfile(
        userId: currentState.user.id,
        fullName: fullName,
        phone: phone,
        address: address,
        addressLat: addressLat,
        addressLng: addressLng,
      );
      emit(AuthAuthenticated(updated));
      return true;
    } catch (error) {
      emit(AuthError(error.toString()));
      return false;
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
