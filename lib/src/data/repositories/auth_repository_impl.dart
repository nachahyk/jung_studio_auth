import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.onAuthStateChange.asyncMap((authState) async {
      final user = authState.session?.user;
      if (user == null) return null;
      return _buildAppUser(user);
    });
  }

  Future<AppUser> _buildAppUser(User user) async {
    final row = await _remoteDataSource.fetchProfile(user.id);
    return _appUserFromRow(user, row);
  }

  AppUser _appUserFromRow(User user, Map<String, dynamic>? row) {
    return AppUser(
      id: user.id,
      isAnonymous: user.isAnonymous,
      email: (row?['email'] as String?) ?? user.email,
      fullName: row?['full_name'] as String?,
      avatarUrl: row?['avatar_url'] as String?,
      phone: row?['phone'] as String?,
      address: row?['address'] as String?,
      addressLat: (row?['address_lat'] as num?)?.toDouble(),
      addressLng: (row?['address_lng'] as num?)?.toDouble(),
      // The profile row's timestamp when it has one, else the auth account's
      // own (always present) — so "how new is this account" never comes
      // back empty just because the profile row lacks it.
      createdAt: DateTime.tryParse((row?['created_at'] as String?) ?? '') ?? DateTime.tryParse(user.createdAt),
      completedTours: completedToursFromMetadata(user.userMetadata),
    );
  }

  @override
  Future<void> signInAnonymously() => _remoteDataSource.signInAnonymously();

  @override
  Future<void> completeTour(String tourId) => _remoteDataSource.addCompletedTour(tourId);

  @override
  Future<void> signInWithEmailPassword(String email, String password) {
    return _remoteDataSource.signInWithEmailPassword(email, password);
  }

  @override
  Future<bool> signUpWithEmailPassword(
    String email,
    String password, {
    required String fullName,
    String? phone,
    String? address,
  }) async {
    final response = await _remoteDataSource.signUpWithEmailPassword(
      email,
      password,
      fullName: fullName,
      phone: phone,
      address: address,
    );
    return response.session == null;
  }

  @override
  Future<void> signInWithGoogle() => _remoteDataSource.signInWithGoogle();

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  @override
  Future<AppUser> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? address,
    double? addressLat,
    double? addressLng,
  }) async {
    final row = await _remoteDataSource.updateProfile(
      userId,
      fullName: fullName,
      phone: phone,
      address: address,
      addressLat: addressLat,
      addressLng: addressLng,
    );
    return _appUserFromRow(_remoteDataSource.currentUser!, row);
  }
}
