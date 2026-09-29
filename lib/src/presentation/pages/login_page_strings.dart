/// Every translatable string [LoginPage] shows. `packages/auth` has no l10n
/// of its own (it can't depend on any one app's generated `AppLocalizations`
/// class, and a second mini-app would have a different one entirely) — the
/// caller supplies already-localized strings, so this shared page stays
/// fully translatable without this package needing to own translations.
class LoginPageStrings {
  const LoginPageStrings({
    required this.signInSubtitle,
    required this.signUpSubtitle,
    required this.fullNameLabel,
    required this.fullNameRequired,
    required this.phoneLabel,
    required this.addressLabel,
    required this.emailLabel,
    required this.passwordLabel,
    required this.signInButton,
    required this.createAccountButton,
    required this.toggleToSignUp,
    required this.toggleToSignIn,
    required this.orDivider,
    required this.continueWithGoogle,
    required this.continueAsGuest,
    required this.confirmEmailSent,
  });

  final String signInSubtitle;
  final String signUpSubtitle;
  final String fullNameLabel;
  final String fullNameRequired;
  final String phoneLabel;
  final String addressLabel;
  final String emailLabel;
  final String passwordLabel;
  final String signInButton;
  final String createAccountButton;
  final String toggleToSignUp;
  final String toggleToSignIn;
  final String orDivider;
  final String continueWithGoogle;
  final String continueAsGuest;
  final String confirmEmailSent;
}
