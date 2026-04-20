import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../core/constants/supabase_constants.dart';

class SupabaseAuthDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) throw Exception('User tidak ditemukan');
      return await _fetchProfile(res.user!.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal login: Periksa koneksi atau API Key anda');
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      // 1. Signup
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = res.user;
      if (user == null) throw Exception('Registrasi gagal');

      // 2. Buat profil di tabel profiles
      // Kita gunakan upsert agar jika data sudah ada tidak error
      await _client.from(SupabaseConstants.profilesTable).upsert({
        'id': user.id,
        'username': username,
        'full_name': fullName,
        'role': 'user',
      });

      // 3. Ambil data profil lengkap
      return await _fetchProfile(user.id);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Gagal membuat profil: Masalah izin database (RLS).');
      }
      throw Exception('Gagal registrasi: $e');
    }
  }

  Future<void> logout() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _fetchProfile(String userId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      // Fallback jika profil belum terbuat
      return UserModel(
        id: userId,
        username: 'user',
        fullName: 'New User',
        role: 'user',
        createdAt: DateTime.now(),
      );
    }
  }
}
