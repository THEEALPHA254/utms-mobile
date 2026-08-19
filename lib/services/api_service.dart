// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE — the app's ONLY door to the Django backend
//
// Every screen and provider calls methods on the `apiService` singleton at the
// bottom of this file. Centralising HTTP here means:
//   • Auth headers are attached once (in the interceptor), not per call.
//   • Token refresh on 401 is handled once, transparently.
//   • Response unwrapping (Django returns `{data: ...}` envelopes) happens
//     once, so every caller gets clean typed data.
//
// KEY CONCEPTs:
//   • Dio  — third-party HTTP client (like axios in JS). We use it because
//            interceptors are cleaner than the stdlib `http` package.
//   • Interceptors — middleware that runs on every request/response, so we
//            inject the JWT and catch 401s in one place.
//   • JWT auth — the backend issues an `access` token (short lived) and a
//            `refresh` token (long lived). We store both in Secure Storage
//            (OS-level encrypted, unlike SharedPreferences).
//   • Singleton — a single shared instance keeps the same Dio + interceptors
//            for the whole app.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'dart:convert';
// FlutterSecureStorage writes to the platform's encrypted keystore
// (Android Keystore / iOS Keychain), so tokens survive app restarts but are
// safer than plain SharedPreferences.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  // ── Base URL — read at build-time from --dart-define, falls back to localhost.
  //    Android emulator note: 10.0.2.2 is the emulator's alias for the host
  //    machine's localhost. If you run into "Connection refused", that's usually
  //    why. Pass it via:  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );
  static String get baseUrl => _configuredBaseUrl;

  // A single storage instance shared by every ApiService method.
  static const _storage = FlutterSecureStorage();
  // `late final` = initialised once (in the constructor), then immutable.
  late final Dio _dio;

  ApiService() {
    // Configure the HTTP client with the base URL and sensible timeouts.
    // Every call below is relative to this baseUrl (e.g. '/auth/login/').
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Interceptor pipeline ────────────────────────────────────────────────
    // Runs for EVERY request and error. Think of it as request/response middleware.
    _dio.interceptors.add(InterceptorsWrapper(
      // Before the request leaves the device: attach the JWT if we have one.
      onRequest: (options, handler) async {
        print('>>> API REQUEST: ${options.method} ${options.uri}');
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // `handler.next` means "continue the request". Skipping this would
        // hang the call forever.
        return handler.next(options);
      },
      // When the server returns an error: intercept 401s (expired token) and
      // silently refresh + retry the original request.
      onError: (DioException e, handler) async {
        print('>>> API ERROR: ${e.response?.statusCode} ${e.message}');
        print('>>> API ERROR BODY: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Swap in the new token and replay the ORIGINAL failed request so
            // the caller never sees the 401 or the refresh dance.
            final token = await _storage.read(key: 'access_token');
            e.requestOptions.headers['Authorization'] = 'Bearer $token';
            return handler.resolve(await _dio.fetch(e.requestOptions));
          }
        }
        // If it wasn't a 401 (or refresh failed), let the error bubble up.
        return handler.next(e);
      },
    ));
  }

  // ── Token refresh ─────────────────────────────────────────────────────────
  // Called by the interceptor above. Uses a FRESH `Dio()` (not `_dio`) to
  // avoid re-triggering the interceptor and looping infinitely on 401s.
  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh == null) return false;
      final res = await Dio().post('$baseUrl/auth/token/refresh/', data: {'refresh': refresh});
      // Persist the new access token (and refresh, if the backend rotated it).
      await _storage.write(key: 'access_token', value: res.data['access']);
      if (res.data['refresh'] != null) {
        await _storage.write(key: 'refresh_token', value: res.data['refresh']);
      }
      return true;
    } catch (_) {
      // Refresh itself failed → the session is dead. Wipe storage so the
      // router's auth guard bounces the user back to /login.
      await _storage.deleteAll();
      return false;
    }
  }

  // ── Response helpers ──────────────────────────────────────────────────────
  // The Django API wraps successful payloads as `{status:..., data:..., ...}`.
  // These helpers make callers agnostic to that shape.

  /// If the response has a top-level `data` key, return its value; otherwise
  /// return the payload as-is. Used for both list and object endpoints.
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  /// Safe cast helper — returns an empty map instead of throwing on odd shapes.
  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  /// Safe cast helper — handles both plain lists and DRF paginated
  /// `{results: [...]}` payloads.
  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic> && value['results'] is List) {
      return value['results'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Log a user in. On success: writes access + refresh tokens and the full
  /// user profile to secure storage so subsequent app starts don't need to
  /// re-login.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login/', data: {'email': email, 'password': password});
      final payload = _asMap(_unwrap(res.data));
      await _storage.write(key: 'access_token', value: payload['access']);
      await _storage.write(key: 'refresh_token', value: payload['refresh']);
      await _storage.write(key: 'user_profile', value: jsonEncode(payload));
      return payload;
    } on DioException catch (e) {
      // Rewrite common auth errors into human-readable messages so the UI
      // doesn't have to poke at raw DioException fields.
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        final msg = (data is Map ? data['message'] ?? data['detail'] : null) ??
            'Your account has been suspended. Please contact the administration office.';
        throw Exception('403: $msg');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('401: Invalid email or password.');
      }
      rethrow;
    }
  }

  /// Register a new student. Backend auto-logs-in on success (returns tokens),
  /// so we store them straight away.
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _dio.post('/auth/register/student/', data: data);
    final payload = _asMap(_unwrap(res.data));
    if (payload['access'] != null) {
      await _storage.write(key: 'access_token', value: payload['access']);
      await _storage.write(key: 'refresh_token', value: payload['refresh']);
      await _storage.write(key: 'user_profile', value: jsonEncode(payload));
    }
    return payload;
  }

  /// Reads the cached user profile from local storage (written at login).
  /// We deliberately DO NOT hit the network — this is called on app start to
  /// decide "are we logged in?" without waiting for a round trip.
  Future<Map<String, dynamic>> getMe() async {
    final raw = await _storage.read(key: 'user_profile');
    if (raw == null || raw.isEmpty) throw Exception('No user profile in local storage');
    return _asMap(jsonDecode(raw));
  }

  /// Nuke every token and cached profile — used by AuthProvider.logout().
  Future<void> logout() async => await _storage.deleteAll();

  /// Kicks off "forgot password" — backend emails the user an OTP code.
  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password/', data: {'email': email});
  }

  /// Completes password reset by submitting the OTP + new password together.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _dio.post('/auth/reset-password/', data: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  // ── Wallet ────────────────────────────────────────────────────────────────

  /// Current wallet balance for the logged-in student.
  Future<Map<String, dynamic>> getWalletBalance() async {
    final res = await _dio.get('/payments/wallet/balance/');
    return _asMap(_unwrap(res.data));
  }

  /// Initiates a wallet top-up. Backend triggers an M-Pesa STK push to the
  /// student's phone; the user then completes it on their handset.
  Future<Map<String, dynamic>> topUpWallet(Map<String, dynamic> data) async {
    final res = await _dio.post('/payments/wallet/topup/', data: data);
    return _asMap(_unwrap(res.data));
  }

  /// Poll Safaricom to confirm whether a pending STK push was paid.
  /// Pass the transaction [reference] returned by topUpWallet.
  /// Returns {'status': 'success'/'failed', 'message': ..., 'balance': ...}
  ///
  /// Used by the wallet screen after a top-up — the user is asked to complete
  /// the STK on their phone, and the UI polls this endpoint every few seconds
  /// until success/failure comes back.
  Future<Map<String, dynamic>> checkMpesaPayment(String reference) async {
    final res = await _dio.post('/payments/mpesa/query/', data: {'reference': reference});
    return _asMap(_unwrap(res.data));
  }

  /// Full transaction history (top-ups + trip payments) for the current user.
  Future<List<dynamic>> getMyTransactions() async {
    final res = await _dio.get('/payments/my/');
    return _asList(_unwrap(res.data));
  }

  // ── Transport (Student) ───────────────────────────────────────────────────

  /// Lists every route the student can browse (e.g. "CBD → CUEA").
  Future<List<dynamic>> getRoutes() async {
    final res = await _dio.get('/transport/routes/');
    return _asList(_unwrap(res.data));
  }

  /// Lists trips available for booking. Filters:
  ///   • [date]     — ISO date, e.g. '2026-08-01'
  ///   • [routeId]  — restrict to trips on this route
  /// Backend always filters to `status=scheduled` so past/cancelled trips
  /// don't show up in the booking flow.
  Future<List<dynamic>> getTrips({String? date, String? routeId}) async {
    final res = await _dio.get('/transport/trips/', queryParameters: {
      // Collection-if lets us include a key only when the value is non-null,
      // instead of sending `date=null`.
      if (date != null) 'date': date,
      if (routeId != null) 'schedule__route': routeId,
      'status': 'scheduled',
    });
    return _asList(_unwrap(res.data));
  }

  /// The current user's bookings (upcoming + past).
  Future<List<dynamic>> getMyBookings() async {
    final res = await _dio.get('/transport/bookings/');
    return _asList(_unwrap(res.data));
  }

  /// Creates a booking. Backend deducts the fare from the student's wallet
  /// atomically and returns the booking (with QR-code payload).
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final res = await _dio.post('/transport/bookings/create/', data: data);
    return _asMap(_unwrap(res.data));
  }

  /// Fetches the latest GPS ping for a running trip (used by the tracking
  /// screen to move the bus icon on the map).
  Future<Map<String, dynamic>> getTripLocation(int tripId) async {
    final res = await _dio.get('/transport/trips/$tripId/location/');
    return _asMap(_unwrap(res.data));
  }

  // ── Transport (Driver) ────────────────────────────────────────────────────

  /// Get all trips visible to the driver (their assigned bus's trips)
  Future<List<dynamic>> getDriverTrips({String? date, String? status}) async {
    final res = await _dio.get('/transport/trips/', queryParameters: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    });
    return _asList(_unwrap(res.data));
  }

  /// Get passengers (bookings) for a specific trip
  Future<List<dynamic>> getTripPassengers(int tripId) async {
    final res = await _dio.get('/transport/bookings/', queryParameters: {'trip': tripId});
    return _asList(_unwrap(res.data));
  }

  /// Update trip status (scheduled → in_progress → completed)
  /// The driver hits Start / Complete buttons; backend enforces valid
  /// transitions and timestamps the change.
  Future<Map<String, dynamic>> updateTripStatus(int tripId, String status) async {
    final res = await _dio.patch('/transport/trips/$tripId/update_status/', data: {'status': status});
    return _asMap(_unwrap(res.data));
  }

  /// Verify and board a student via QR code.
  /// Called from the driver's QR scanner screen — [qrCode] is the raw string
  /// decoded from the student's booking QR. Backend validates it belongs to
  /// THIS trip and marks the booking as boarded.
  Future<Map<String, dynamic>> verifyBoarding(String qrCode) async {
    final res = await _dio.post('/transport/bookings/board/', data: {'qr_code': qrCode});
    return _asMap(_unwrap(res.data));
  }

  /// Push live GPS location for a trip.
  /// Driver's device sends this every few seconds during a trip; students
  /// tracking the trip receive the updates via `getTripLocation`.
  Future<void> pushLocation({
    required int tripId,
    required double lat,
    required double lng,
    required double speed,
  }) async {
    await _dio.post('/transport/location/push/', data: {
      'trip_id': tripId,
      'latitude': lat,
      'longitude': lng,
      'speed_kmh': speed,
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// All notifications for the current user (newest first, per backend).
  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications/');
    return _asList(_unwrap(res.data));
  }

  /// Flip a single notification's `is_read` flag.
  Future<void> markNotificationRead(int id) async {
    await _dio.post('/notifications/$id/read/');
  }

  /// Bulk-mark everything read — used by the "Mark all read" button.
  Future<void> markAllNotificationsRead() async {
    await _dio.post('/notifications/mark-all-read/');
  }

  /// Small endpoint that just returns the count — used to render the red
  /// badge on the notifications bell without downloading the full list.
  Future<int> getUnreadNotificationCount() async {
    final res = await _dio.get('/notifications/unread/');
    return (_asMap(_unwrap(res.data))['unread'] as int?) ?? 0;
  }
}

// ── Singleton ────────────────────────────────────────────────────────────────
// Every call site does `import '.../api_service.dart'` and uses this instance.
// Because it's created once at import time, all screens share the same Dio
// instance (and therefore the same interceptor pipeline + token state).
final apiService = ApiService();
