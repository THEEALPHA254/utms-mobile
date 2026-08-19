// ─────────────────────────────────────────────────────────────────────────────
// AUTH PROVIDER — the single source of truth for "who is logged in?"
//
// KEY CONCEPTS:
//   • Riverpod pattern: STATE (`AuthState`) + NOTIFIER (`AuthNotifier`)
//     + PROVIDER (`authProvider`). The notifier owns mutations; widgets
//     `ref.watch(authProvider)` to read state and `ref.read(...).notifier`
//     to call methods like `login()`.
//   • Immutable state + copyWith: state is never mutated in place — every
//     change assigns a *new* AuthState. This is what triggers rebuilds and
//     avoids subtle bugs where widgets don't notice the change.
//   • The `build()` method returns the INITIAL state and also kicks off
//     `_init()` which restores the session from secure storage. That's how
//     "stay logged in across restarts" works.
//   • The router (`utils/router.dart`) watches this provider — when
//     `isAuthenticated` flips, the app is automatically re-routed.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

// ── Auth State ────────────────────────────────────────────────────────────────
// Immutable value object describing the current auth situation.
// Everything the UI needs to render login/logout/error UX lives here.

class AuthState {
  final Map<String, dynamic>? user;  // full user profile, or null if logged out
  final bool isLoading;              // true while a login/register call is in-flight
  final String? error;               // user-facing error message, if any

  const AuthState({this.user, this.isLoading = false, this.error});

  // Convenience getters used by the router and various screens.
  bool get isAuthenticated => user != null;
  // The backend tags each account with a `role`. Drivers get their own
  // dashboard; anyone else (student/staff) uses the student flows.
  bool get isDriver => user?['role'] == 'driver';

  // Standard "copyWith" pattern — returns a NEW instance with some fields
  // replaced. This preserves immutability and makes state changes explicit.
  AuthState copyWith({Map<String, dynamic>? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
// Contains the methods that mutate auth state (`login`, `register`, `logout`).
// Extends Riverpod's `Notifier<AuthState>` — the generic parameter is what
// consumers get back when they read the provider.

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  // Runs ONCE when the provider is first read. Must return the initial state.
  // We kick off `_init()` fire-and-forget so app startup isn't blocked by the
  // network — the state will flip to "authenticated" a moment later if a
  // valid session was found on disk.
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  // Restore session from secure storage on cold start.
  // If an access token exists, try to hydrate the cached profile; if that
  // fails, nuke storage so we're back to a clean logged-out state.
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

  // Login flow: flip to loading, hit the API, then either surface the user
  // (success) or translate the error into a friendly message (failure).
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.login(email, password);
      final user = await apiService.getMe();
      // Success — replace the entire state with a fresh authenticated one
      // (this also clears any lingering error/isLoading).
      state = AuthState(user: user);
    } catch (e) {
      // Map raw exceptions to something a human can read on the login screen.
      final msg = e.toString();
      String error;
      if (msg.contains('403:')) {
        // Extract message after "403: "
        error = msg.split('403:').last.trim();
        if (error.isEmpty) {
          error = 'Your account has been suspended. Please contact the administration office.';
        }
      } else if (msg.contains('connection') || msg.contains('timeout') || msg.contains('SocketException')) {
        error = 'Cannot reach server. Check your network connection.';
      } else if (msg.contains('401') || msg.contains('Invalid')) {
        error = 'Invalid email or password.';
      } else {
        error = 'Login failed. Please try again.';
      }
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  // Registration mirrors login — backend auto-logs-in on success so we can
  // immediately fetch the user profile and transition to the authenticated state.
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

  // Logout: wipe tokens/profile from secure storage, then reset state to the
  // logged-out sentinel. The router's redirect will bounce to /login on the
  // next navigation.
  Future<void> logout() async {
    await apiService.logout();
    state = const AuthState();
  }
}

// The provider itself — what widgets/other providers reference to read state
// or grab the notifier. `NotifierProvider<N, S>` = "expose Notifier N whose
// state type is S". Read as: `ref.watch(authProvider)` returns an `AuthState`.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
