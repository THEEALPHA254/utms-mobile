import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  // ── Base URL — emulator uses 10.0.2.2 to reach host localhost ────────────────
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.213:8000/api',
  );
  static String get baseUrl => _configuredBaseUrl;

  static const _storage = FlutterSecureStorage();
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('>>> API REQUEST: ${options.method} ${options.uri}');
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        print('>>> API ERROR: ${e.response?.statusCode} ${e.message}');
        print('>>> API ERROR BODY: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _storage.read(key: 'access_token');
            e.requestOptions.headers['Authorization'] = 'Bearer $token';
            return handler.resolve(await _dio.fetch(e.requestOptions));
          }
        }
        return handler.next(e);
      },
    ));
  }

  // ── Token refresh ─────────────────────────────────────────────────────────────
  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh == null) return false;
      final res = await Dio().post('$baseUrl/auth/token/refresh/', data: {'refresh': refresh});
      await _storage.write(key: 'access_token', value: res.data['access']);
      if (res.data['refresh'] != null) {
        await _storage.write(key: 'refresh_token', value: res.data['refresh']);
      }
      return true;
    } catch (_) {
      await _storage.deleteAll();
      return false;
    }
  }

  // ── Response helpers ──────────────────────────────────────────────────────────
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic> && value['results'] is List) {
      return value['results'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  // ── Auth ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login/', data: {'email': email, 'password': password});
    final payload = _asMap(_unwrap(res.data));
    await _storage.write(key: 'access_token', value: payload['access']);
    await _storage.write(key: 'refresh_token', value: payload['refresh']);
    await _storage.write(key: 'user_profile', value: jsonEncode(payload));
    return payload;
  }

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

  Future<Map<String, dynamic>> getMe() async {
    final raw = await _storage.read(key: 'user_profile');
    if (raw == null || raw.isEmpty) throw Exception('No user profile in local storage');
    return _asMap(jsonDecode(raw));
  }

  Future<void> logout() async => await _storage.deleteAll();

  // ── Wallet ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWalletBalance() async {
    final res = await _dio.get('/payments/wallet/balance/');
    return _asMap(_unwrap(res.data));
  }

  Future<Map<String, dynamic>> topUpWallet(Map<String, dynamic> data) async {
    final res = await _dio.post('/payments/wallet/topup/', data: data);
    return _asMap(_unwrap(res.data));
  }

  Future<List<dynamic>> getMyTransactions() async {
    final res = await _dio.get('/payments/my/');
    return _asList(_unwrap(res.data));
  }

  // ── Transport (Student) ───────────────────────────────────────────────────────

  Future<List<dynamic>> getRoutes() async {
    final res = await _dio.get('/transport/routes/');
    return _asList(_unwrap(res.data));
  }

  Future<List<dynamic>> getTrips({String? date, String? routeId}) async {
    final res = await _dio.get('/transport/trips/', queryParameters: {
      if (date != null) 'date': date,
      if (routeId != null) 'schedule__route': routeId,
      'status': 'scheduled',
    });
    return _asList(_unwrap(res.data));
  }

  Future<List<dynamic>> getMyBookings() async {
    final res = await _dio.get('/transport/bookings/');
    return _asList(_unwrap(res.data));
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final res = await _dio.post('/transport/bookings/create/', data: data);
    return _asMap(_unwrap(res.data));
  }

  Future<Map<String, dynamic>> getTripLocation(int tripId) async {
    final res = await _dio.get('/transport/trips/$tripId/location/');
    return _asMap(_unwrap(res.data));
  }

  // ── Transport (Driver) ────────────────────────────────────────────────────────

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
  Future<Map<String, dynamic>> updateTripStatus(int tripId, String status) async {
    final res = await _dio.patch('/transport/trips/$tripId/update_status/', data: {'status': status});
    return _asMap(_unwrap(res.data));
  }

  /// Verify and board a student via QR code
  Future<Map<String, dynamic>> verifyBoarding(String qrCode) async {
    final res = await _dio.post('/transport/bookings/board/', data: {'qr_code': qrCode});
    return _asMap(_unwrap(res.data));
  }

  /// Push live GPS location for a trip
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

  // ── Notifications ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications/');
    return _asList(_unwrap(res.data));
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.post('/notifications/$id/read/');
  }
}

// Singleton
final apiService = ApiService();
