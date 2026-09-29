import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The deep link Supabase/Google redirect back into the app on mobile.
/// Must also be registered in Supabase Dashboard > Authentication >
/// URL Configuration > Redirect URLs.
const oauthRedirectUrl = 'com.aimjung.aimjung://login-callback/';

/// Thin wrapper around `supabase.auth` and the `profiles` table.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInAnonymously() => _client.auth.signInAnonymously();

  Future<void> signInWithEmailPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password, {
    required String fullName,
    String? phone,
    String? address,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
  }

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : oauthRedirectUrl,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Map<String, dynamic>?> fetchProfile(String userId) {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>> updateProfile(
    String userId, {
    required String fullName,
    String? phone,
    String? address,
    double? addressLat,
    double? addressLng,
  }) {
    return _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone': phone,
          'address': address,
          'address_lat': addressLat,
          'address_lng': addressLng,
        })
        .eq('id', userId)
        .select()
        .single();
  }
}
