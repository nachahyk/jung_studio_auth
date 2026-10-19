import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jung_studio_auth/jung_studio_auth.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.initialUser);

  final AppUser initialUser;
  final _controller = StreamController<AppUser?>();
  Map<String, Object?>? lastUpdate;
  bool signedOut = false;

  @override
  Stream<AppUser?> authStateChanges() {
    _controller.add(initialUser);
    return _controller.stream;
  }

  @override
  Future<AppUser> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? address,
    double? addressLat,
    double? addressLng,
  }) async {
    lastUpdate = {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'addressLat': addressLat,
      'addressLng': addressLng,
    };
    return AppUser(
      id: userId,
      isAnonymous: false,
      email: initialUser.email,
      fullName: fullName,
      phone: phone,
      address: address,
      addressLat: addressLat,
      addressLng: addressLng,
    );
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    _controller.add(null);
  }

  @override
  Future<void> signInAnonymously() async {}
  @override
  Future<void> signInWithEmailPassword(String email, String password) async {}
  @override
  Future<bool> signUpWithEmailPassword(String email, String password,
          {required String fullName, String? phone, String? address}) async =>
      false;
  @override
  Future<void> signInWithGoogle() async {}
}

const _strings = AccountProfilePageStrings(
  title: 'Profile',
  guestName: 'Guest',
  guestBadge: 'Guest account',
  emailLabel: 'Email',
  phoneLabel: 'Phone',
  addressLabel: 'Address',
  memberSinceLabel: 'Member since',
  notSet: 'Not set',
  editButton: 'Edit profile',
  editTitle: 'Edit your profile',
  fullNameLabel: 'Full name',
  fullNameRequired: 'Please enter your name',
  saveButton: 'Save',
  savedMessage: 'Profile updated',
  signOutButton: 'Sign out',
);

const _user = AppUser(
  id: 'u1',
  isAnonymous: false,
  email: 'nok@example.com',
  fullName: 'Nok Jung',
  address: '1 Sukhumvit Rd',
  addressLat: 13.7,
  addressLng: 100.5,
);

Future<_FakeAuthRepository> _pump(WidgetTester tester, AppUser user) async {
  final repository = _FakeAuthRepository(user);
  final cubit = AuthCubit(repository);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: const MaterialApp(home: AccountProfilePage(strings: _strings)),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('shows identity details, with a placeholder for empty fields', (tester) async {
    await _pump(tester, _user);

    expect(find.text('Nok Jung'), findsOneWidget);
    expect(find.text('NJ'), findsOneWidget);
    expect(find.text('nok@example.com'), findsOneWidget);
    expect(find.text('1 Sukhumvit Rd'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2)); // phone + member since
    expect(find.text('Guest account'), findsNothing);
  });

  testWidgets('anonymous users are shown as a guest', (tester) async {
    await _pump(tester, const AppUser(id: 'g', isAnonymous: true));

    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Guest account'), findsOneWidget);
  });

  testWidgets('editing saves name and phone without clearing the address', (tester) async {
    final repository = await _pump(tester, _user);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Nok J.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone'), '0812345678');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdate, {
      'fullName': 'Nok J.',
      'phone': '0812345678',
      'address': '1 Sukhumvit Rd',
      'addressLat': 13.7,
      'addressLng': 100.5,
    });
    expect(find.text('Edit your profile'), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Nok J.'), findsOneWidget);
  });

  testWidgets('an empty name is rejected', (tester) async {
    final repository = await _pump(tester, _user);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), '  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(repository.lastUpdate, isNull);
  });

  testWidgets('sign out calls the repository', (tester) async {
    final repository = await _pump(tester, _user);

    // Below the fold on the default 800x600 test surface.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(repository.signedOut, isTrue);
  });
}
