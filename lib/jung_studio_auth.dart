/// The shared login/signup/session journey, backed by Supabase.
///
/// Owns cross-app *identity* only (who is this user) — never a mini-app's
/// own role/permission concept. AimJung's staff/admin distinction, for
/// example, is resolved inside the AimJung package, not here.
library;

export 'src/data/datasources/auth_remote_data_source.dart';
export 'src/data/repositories/auth_repository_impl.dart';
export 'src/domain/entities/app_user.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/presentation/controllers/auth_cubit.dart';
export 'src/presentation/controllers/auth_state.dart';
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/login_page_strings.dart';
export 'src/presentation/widgets/google_logo.dart';
