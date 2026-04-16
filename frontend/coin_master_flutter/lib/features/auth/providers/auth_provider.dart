import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/storage/secure_storage.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    user: user ?? this.user,
    error: error,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<bool> checkAuth() async {
    final token = await SecureStorage.getToken();
    if (token == null) return false;
    try {
      final data = await ApiClient.get<Map<String, dynamic>>(
        ApiEndpoints.me,
      );
      state = state.copyWith(
        user: UserModel.fromJson(data),
        isAuthenticated: true,
      );
      return true;
    } catch (_) {
      await SecureStorage.clearAll();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      await SecureStorage.saveToken(data['token'] as String);
      await SecureStorage.saveUserId(
        (data['user'] as Map<String, dynamic>)['id'] as String,
      );
      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      await SecureStorage.saveToken(data['token'] as String);
      await SecureStorage.saveUserId(
        (data['user'] as Map<String, dynamic>)['id'] as String,
      );
      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        isAuthenticated: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(),
    );
