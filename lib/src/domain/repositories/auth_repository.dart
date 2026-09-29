import '../entities/app_user.dart';

/// Contract for authentication, implemented by the data layer.
abstract class AuthRepository {
  /// Emits the current [AppUser] whenever the auth session changes, or
  /// `null` when signed out. Emits an initial value immediately based on
  /// any persisted session.
  Stream<AppUser?> authStateChanges();

  Future<void> signInAnonymously();
  Future<void> signInWithEmailPassword(String email, String password);

  /// Returns `true` when the account needs email confirmation before a
  /// session is created (Supabase's default "Confirm email" setting).
  /// [fullName], [phone], and [address] seed the new `profiles` row (via the
  /// `handle_new_user` trigger reading auth signup metadata) — only
  /// [fullName] is required.
  Future<bool> signUpWithEmailPassword(
    String email,
    String password, {
    required String fullName,
    String? phone,
    String? address,
  });
  Future<void> signInWithGoogle();
  Future<void> signOut();

  /// Updates the `profiles` row for [userId] and returns the refreshed
  /// [AppUser]. Passing `null` for [phone]/[address] clears that field.
  Future<AppUser> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? address,
    double? addressLat,
    double? addressLng,
  });
}
