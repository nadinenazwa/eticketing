import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/supabase_auth_datasource.dart';
import '../../domain/models/user_model.dart';

final authDatasourceProvider = Provider((_) => SupabaseAuthDatasource());

// State auth: null = belum login, UserModel = sudah login
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.read(authDatasourceProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final SupabaseAuthDatasource _ds;

  AuthNotifier(this._ds) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _ds.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.login(email, password));
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.register(
          email: email,
          password: password,
          username: username,
          fullName: fullName,
        ));
  }

  Future<void> logout() async {
    await _ds.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) => _ds.resetPassword(email);
}
