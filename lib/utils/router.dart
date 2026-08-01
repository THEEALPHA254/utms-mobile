// ─────────────────────────────────────────────────────────────────────────────
// APP ROUTER — declarative navigation using go_router
//
// KEY CONCEPTS:
//   • go_router is a URL-style router built on top of Flutter's Navigator 2.0.
//     Each screen has a `path`; navigation is `context.go('/wallet')` instead
//     of pushing widgets onto a stack manually.
//   • The `redirect` callback runs on every navigation attempt — this is where
//     we enforce "must be logged in" and "route drivers vs students".
//   • This provider watches `authProvider`; whenever login state changes, the
//     router is rebuilt and the redirect logic re-evaluates, so logging out
//     automatically bounces the user back to /login.
//   • Nested `routes:` create hierarchical paths — `/home/wallet` inherits
//     from `/home`, which mirrors the app's information architecture.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

// ── Screens ───────────────────────────────────────────────────────────────────
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// Student
import '../screens/home/home_screen.dart';
import '../screens/booking/routes_screen.dart';
import '../screens/booking/trip_list_screen.dart';
import '../screens/booking/my_bookings_screen.dart';
import '../screens/booking/receipt_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/tracking/tracking_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';

// Driver
import '../screens/driver/driver_dashboard.dart';
import '../screens/driver/driver_trip_screen.dart';
import '../screens/driver/driver_trips_list.dart';
import '../screens/driver/qr_scanner_screen.dart';

// ── Router Provider ───────────────────────────────────────────────────────────

// Wrapped in a Riverpod `Provider` so that:
//   1. It can `ref.watch(authProvider)` — when auth state flips, the router
//      is rebuilt and redirects re-run.
//   2. `main.dart` can obtain it with `ref.watch(appRouterProvider)`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    // First location shown when the app boots. The redirect below decides
    // whether the user actually stays here or gets sent onward.
    initialLocation: '/login',

    // ── Global auth guard ────────────────────────────────────────────────────
    // Runs on EVERY navigation attempt. Return a path string to redirect, or
    // `null` to allow the navigation to proceed.
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      // Any auth-adjacent route (login / register / forgot password) should
      // remain reachable when NOT logged in.
      final goingToAuth = loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/forgot-password');

      // 1) Not logged in AND trying to reach a protected route → login.
      if (!loggedIn && !goingToAuth) return '/login';

      // 2) Logged in but still on an auth screen → push to the right dashboard
      //    based on role (driver vs student).
      if (loggedIn && goingToAuth) {
        return auth.isDriver ? '/driver' : '/home';
      }

      // Otherwise, allow the navigation as-is.
      return null;
    },

    routes: [
      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(path: '/login',            builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',         builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password',  builder: (_, __) => const ForgotPasswordScreen()),

      // ── Student shell ──────────────────────────────────────────────────────
      // All student-facing screens are nested under /home so URLs look like
      // /home/wallet, /home/my-bookings, etc. — hierarchical + shareable.
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'routes', builder: (_, __) => const RoutesScreen()),
          // `:routeId` is a path PARAMETER; the value is read from state.pathParameters.
          GoRoute(
            path: 'trips/:routeId',
            builder: (_, state) =>
                TripListScreen(routeId: state.pathParameters['routeId']!),
          ),
          GoRoute(
            path: 'book/:tripId',
            builder: (_, state) =>
                BookingConfirmScreen(tripId: int.parse(state.pathParameters['tripId']!)),
          ),
          GoRoute(path: 'my-bookings', builder: (_, __) => const MyBookingsScreen()),
          GoRoute(path: 'wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(
            path: 'track/:tripId',
            builder: (_, state) =>
                TrackingScreen(tripId: int.parse(state.pathParameters['tripId']!)),
          ),
          GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
          // Receipt: complex object passed via `extra` (not URL-serialisable).
          // `context.go('/home/receipt', extra: bookingMap)` is how callers push it.
          GoRoute(
            path: 'receipt',
            builder: (_, state) {
              final booking = state.extra as Map<String, dynamic>? ?? {};
              return ReceiptScreen(booking: booking);
            },
          ),
        ],
      ),

      // ── Driver shell ───────────────────────────────────────────────────────
      // Separate top-level path so drivers never accidentally land on student
      // pages (and vice-versa) — the redirect above enforces the role split.
      GoRoute(
        path: '/driver',
        builder: (_, __) => const DriverDashboard(),
        routes: [
          GoRoute(path: 'trips', builder: (_, __) => const DriverTripsListScreen()),
          GoRoute(
            path: 'trip/:tripId',
            builder: (_, state) =>
                DriverTripScreen(tripId: int.parse(state.pathParameters['tripId']!)),
          ),
          GoRoute(path: 'scan', builder: (_, __) => const QRScannerScreen()),
          GoRoute(path: 'history', builder: (_, __) => const DriverTripsListScreen()),
        ],
      ),
    ],
  );
});
