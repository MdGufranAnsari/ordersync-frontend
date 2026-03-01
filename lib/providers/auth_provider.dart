import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/local_storage.dart';
import '../repositories/auth_repository.dart';
import 'dart:io' as java;
import '../models/user_model.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

// Auth state
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? accountStatus;
  final AuthModel? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.accountStatus,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? accountStatus,
    AuthModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accountStatus: accountStatus ?? this.accountStatus,
      user: user ?? this.user,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _asyncInit();
  }

  Future<void> _asyncInit() async {
    await init();
  }

  Future<void> init() async {
    final token = TokenStorage.getToken();
    if (token == null) return;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final role = payload['role'] as String;
      final status = payload['accountStatus'] as String? ?? 'active';
      AuthModel authUser = AuthModel(
        id: payload['userId'] ?? '',
        name: payload['name'] ?? 'User',
        phone: payload['phone'] ?? '',
        role: role,
        profileImage: payload['profileImage'],
      );

      state = state.copyWith(
        isAuthenticated: true,
        accountStatus: status,
        user: authUser,
      );

      try {
        final meData = await _repository.getMe();
        authUser = AuthModel(
          id: meData['id'] ?? authUser.id,
          name: meData['name'] ?? authUser.name,
          phone: meData['phone'] ?? authUser.phone,
          role: meData['role'] ?? authUser.role,
          profileImage: meData['profile_image'],
        );
        state = state.copyWith(user: authUser);
      } catch (_) {
        // Silently keep token data if fresh fetch fails
      }
    } catch (_) {
      // Decode failed or expired token structure
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        name: name,
        phone: phone,
        password: password,
        role: role,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _repository.login(phone: phone, password: password);

      // Decode role and status from JWT payload
      final parts = token.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final role = payload['role'] as String;
      final status = payload['accountStatus'] as String? ?? 'active';
      
      final authUser = AuthModel(
        id: payload['userId'] ?? '',
        name: payload['name'] ?? 'User',
        phone: payload['phone'] ?? '',
        role: role,
        profileImage: payload['profileImage'],
      );

      await TokenStorage.saveToken(token);
      await TokenStorage.saveRole(role);
      await TokenStorage.saveStatus(status);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accountStatus: status,
        user: authUser,
      );
      return role;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> uploadProfileImage(java.File file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.uploadProfileImage(file);
      // Re-fetch user to get the newly updated profile_image url
      final meData = await _repository.getMe();
      if (state.user != null) {
        final authUser = AuthModel(
          id: meData['id'] ?? state.user!.id,
          name: meData['name'] ?? state.user!.name,
          phone: meData['phone'] ?? state.user!.phone,
          role: meData['role'] ?? state.user!.role,
          profileImage: meData['profile_image'],
        );
        state = state.copyWith(user: authUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
