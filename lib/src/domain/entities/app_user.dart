/// Domain representation of the signed-in user's cross-app *identity* — the
/// Supabase auth identity merged with its `profiles` row. Deliberately
/// carries no role/permission concept: a mini-app that needs one (e.g.
/// AimJung's staff/admin distinction) resolves it itself, scoped to its own
/// domain, rather than the shared identity model growing one role system
/// per mini-app.
class AppUser {
  const AppUser({
    required this.id,
    required this.isAnonymous,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.address,
    this.addressLat,
    this.addressLng,
    this.createdAt,
    this.completedTours = const {},
  });

  final String id;
  final bool isAnonymous;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final double? addressLat;
  final double? addressLng;
  final DateTime? createdAt;

  /// Ids of the first-run guided tours this account has finished or skipped
  /// (e.g. `'landing'`, `'aim_jung'`) — stored on the account (Supabase auth
  /// user metadata), so each tour shows once per account, on any device.
  final Set<String> completedTours;

  String get displayName => fullName ?? email ?? 'Guest';

  bool hasCompletedTour(String tourId) => completedTours.contains(tourId);

  AppUser withCompletedTour(String tourId) => AppUser(
        id: id,
        isAnonymous: isAnonymous,
        email: email,
        fullName: fullName,
        avatarUrl: avatarUrl,
        phone: phone,
        address: address,
        addressLat: addressLat,
        addressLng: addressLng,
        createdAt: createdAt,
        completedTours: {...completedTours, tourId},
      );
}
