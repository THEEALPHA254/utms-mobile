import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

// ── Screens ───────────────────────────────────────────────────────────────────
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final goingToAuth = loc.startsWith('/login') || loc.startsWith('/register');

      if (!loggedIn && !goingToAuth) return '/login';

      if (loggedIn && goingToAuth) {
        // Route to correct dashboard based on role
        return auth.isDriver ? '/driver' : '/home';
      }
      return null;
    },
    routes: [
      // ── Auth ───────────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── Student shell ──────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'routes', builder: (_, __) => const RoutesScreen()),
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
          // Receipt: passed as extra
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
