import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jung_studio_auth/jung_studio_auth.dart';

/// Feeds one signed-in session and a canned `profiles` row to the real
/// repository mapping.
class _DataSource extends AuthRemoteDataSource {
  _DataSource(this.profileRow)
      : super(SupabaseClient('http://localhost', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  final Map<String, dynamic>? profileRow;

  static final user = User(
    id: 'u1',
    appMetadata: const {},
    userMetadata: const {'completed_tours': ['landing']},
    aud: 'authenticated',
    createdAt: '2026-10-30T08:00:00Z',
  );

  @override
  Stream<AuthState> get onAuthStateChange =>
      Stream.value(AuthState(AuthChangeEvent.signedIn, Session(accessToken: 'a', tokenType: 'bearer', user: user)));

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async => profileRow;
}

Future<AppUser> _signedInUser(Map<String, dynamic>? row) async =>
    (await AuthRepositoryImpl(_DataSource(row)).authStateChanges().first)!;

void main() {
  test("falls back to the auth account's creation time when the profile row has none", () async {
    final user = await _signedInUser({'full_name': 'Pung'});
    expect(user.createdAt, DateTime.utc(2026, 10, 30, 8));
  });

  test("uses the profile row's created_at when present", () async {
    final user = await _signedInUser({'created_at': '2026-10-31T09:30:00Z'});
    expect(user.createdAt, DateTime.utc(2026, 10, 31, 9, 30));
  });

  test('no profile row at all still yields a creation time and completed tours', () async {
    final user = await _signedInUser(null);
    expect(user.createdAt, DateTime.utc(2026, 10, 30, 8));
    expect(user.hasCompletedTour('landing'), isTrue);
  });
}
