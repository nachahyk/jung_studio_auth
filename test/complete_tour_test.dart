import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jung_studio_auth/jung_studio_auth.dart';

class _Repo implements AuthRepository {
  _Repo(this.user, {this.failSave = false});

  final AppUser? user;
  final bool failSave;
  final saved = <String>[];

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Future<void> completeTour(String tourId) async {
    if (failSave) throw Exception('offline');
    saved.add(tourId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AuthCubit> _signedIn(_Repo repo) async {
  final cubit = AuthCubit(repo);
  await cubit.stream.firstWhere((s) => s is! AuthInitial);
  return cubit;
}

AppUser? _user(AuthCubit cubit) => switch (cubit.state) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

void main() {
  test('completeTour marks it on the account right away and saves it', () async {
    final repo = _Repo(const AppUser(id: 'u1', isAnonymous: false));
    final cubit = await _signedIn(repo);
    expect(_user(cubit)!.hasCompletedTour('landing'), isFalse);

    await cubit.completeTour('landing');
    expect(_user(cubit)!.hasCompletedTour('landing'), isTrue);
    expect(repo.saved, ['landing']);
  });

  test('completing it twice only saves once', () async {
    final repo = _Repo(const AppUser(id: 'u1', isAnonymous: false));
    final cubit = await _signedIn(repo);
    await cubit.completeTour('landing');
    await cubit.completeTour('landing');
    expect(repo.saved, ['landing']);
  });

  test('a failed save keeps the user signed in with the tour marked done', () async {
    final repo = _Repo(const AppUser(id: 'u1', isAnonymous: false), failSave: true);
    final cubit = await _signedIn(repo);
    await cubit.completeTour('aim_jung');
    expect(cubit.state, isA<AuthAuthenticated>());
    expect(_user(cubit)!.hasCompletedTour('aim_jung'), isTrue);
  });

  test('a guest (anonymous) account can complete tours too', () async {
    final repo = _Repo(const AppUser(id: 'g1', isAnonymous: true));
    final cubit = await _signedIn(repo);
    await cubit.completeTour('aim_jung');
    expect(_user(cubit)!.hasCompletedTour('aim_jung'), isTrue);
    expect(repo.saved, ['aim_jung']);
  });

  test('signed out: nothing to record', () async {
    final repo = _Repo(null);
    final cubit = await _signedIn(repo);
    await cubit.completeTour('landing');
    expect(repo.saved, isEmpty);
  });

  test('completed tours are read from user metadata, tolerating junk', () {
    expect(completedToursFromMetadata({'completed_tours': ['landing', 'aim_jung']}), {'landing', 'aim_jung'});
    expect(completedToursFromMetadata({'completed_tours': ['landing', 3, null]}), {'landing'});
    expect(completedToursFromMetadata({'completed_tours': 'landing'}), isEmpty);
    expect(completedToursFromMetadata({}), isEmpty);
    expect(completedToursFromMetadata(null), isEmpty);
  });
}
