import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../controllers/auth_cubit.dart';
import '../controllers/auth_state.dart';
import 'account_profile_page_strings.dart';

/// The shared account screen — who you're signed in as, an edit sheet for
/// the cross-app identity fields (name, phone), and sign-out.
///
/// Themed via ambient `Theme.of(context)` exactly like [LoginPage], so each
/// mini-app wraps it in its own theme (and supplies its own [appBar]) rather
/// than this page knowing any one app's colors. Signing out needs no
/// navigation here: the shell's router redirects to `/login` as soon as
/// [AuthCubit] emits.
class AccountProfilePage extends StatelessWidget {
  const AccountProfilePage({
    super.key,
    required this.strings,
    this.appBar,
    this.maxContentWidth = 480,
  });

  final AccountProfilePageStrings strings;
  final PreferredSizeWidget? appBar;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appBar ?? AppBar(title: Text(strings.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                _ProfileHeader(user: user, strings: strings),
                const SizedBox(height: 24),
                _ProfileDetailsCard(user: user, strings: strings),
                const SizedBox(height: 16),
                if (user != null)
                  OutlinedButton.icon(
                    onPressed: () => _showEditSheet(context, user),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(strings.editButton),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  icon: const Icon(Icons.logout),
                  label: Text(strings.signOutButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, AppUser user) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: _EditProfileSheet(user: user, strings: strings),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.savedMessage)));
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.strings});

  final AppUser? user;
  final AccountProfilePageStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = user == null || user!.isAnonymous ? strings.guestName : user!.displayName;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((word) => word[0]).join().toUpperCase();

    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: colorScheme.primaryContainer,
          foregroundImage: user?.avatarUrl == null ? null : NetworkImage(user!.avatarUrl!),
          child: Text(
            initials,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        if (user?.isAnonymous ?? true) ...[
          const SizedBox(height: 8),
          Chip(label: Text(strings.guestBadge), visualDensity: VisualDensity.compact),
        ],
      ],
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.user, required this.strings});

  final AppUser? user;
  final AccountProfilePageStrings strings;

  @override
  Widget build(BuildContext context) {
    final createdAt = user?.createdAt;
    final rows = [
      (Icons.mail_outline, strings.emailLabel, user?.email),
      (Icons.phone_outlined, strings.phoneLabel, user?.phone),
      (Icons.location_on_outlined, strings.addressLabel, user?.address),
      (
        Icons.event_outlined,
        strings.memberSinceLabel,
        createdAt == null ? null : MaterialLocalizations.of(context).formatMediumDate(createdAt.toLocal()),
      ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, (icon, label, value)) in rows.indexed) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              subtitle: Text(value == null || value.isEmpty ? strings.notSet : value),
            ),
          ],
        ],
      ),
    );
  }
}

/// Edits the identity fields shared by every mini-app. Address (and its map
/// coordinates) is passed through unchanged — `updateProfile` clears any
/// field passed as `null`, and picking a location is a per-app concern
/// (AimJung's delivery-address picker), not this generic sheet's.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.strings});

  final AppUser user;
  final AccountProfilePageStrings strings;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameController = TextEditingController(text: widget.user.fullName ?? '');
  late final _phoneController = TextEditingController(text: widget.user.phone ?? '');
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final authCubit = context.read<AuthCubit>();
    final phone = _phoneController.text.trim();
    final saved = await authCubit.updateProfile(
      fullName: _fullNameController.text.trim(),
      phone: phone.isEmpty ? null : phone,
      address: widget.user.address,
      addressLat: widget.user.addressLat,
      addressLng: widget.user.addressLng,
    );
    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      final error = authCubit.state;
      if (error is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.editTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: strings.fullNameLabel),
              validator: (value) => value == null || value.trim().isEmpty ? strings.fullNameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: strings.phoneLabel),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(strings.saveButton),
            ),
          ],
        ),
      ),
    );
  }
}
