import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  bool get isDriver => user?['role'] == 'driver';

  AuthState copyWith({Map<String, dynamic>? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final user = await apiService.getMe();
        state = state.copyWith(user: user);
      } catch (_) {
        await _storage.deleteAll();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.login(email, password);
      final user = await apiService.getMe();
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Invalid email or password.');
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.register(data);
      final user = await apiService.getMe();
      state = AuthState(user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Check your details.');
    }
  }

  Future<void> logout() async {
    await apiService.logout();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);