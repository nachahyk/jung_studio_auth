/// Every translatable string [AccountProfilePage] shows — caller-supplied for the
/// same reason as [LoginPageStrings]: this package has no l10n of its own.
class AccountProfilePageStrings {
  const AccountProfilePageStrings({
    required this.title,
    required this.guestName,
    required this.guestBadge,
    required this.emailLabel,
    required this.phoneLabel,
    required this.addressLabel,
    required this.memberSinceLabel,
    required this.notSet,
    required this.editButton,
    required this.editTitle,
    required this.fullNameLabel,
    required this.fullNameRequired,
    required this.saveButton,
    required this.savedMessage,
    required this.signOutButton,
  });

  final String title;
  final String guestName;
  final String guestBadge;
  final String emailLabel;
  final String phoneLabel;
  final String addressLabel;
  final String memberSinceLabel;

  /// Shown in place of an empty email/phone/address.
  final String notSet;
  final String editButton;
  final String editTitle;
  final String fullNameLabel;
  final String fullNameRequired;
  final String saveButton;
  final String savedMessage;
  final String signOutButton;
}
