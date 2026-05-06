import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'package:go_router/go_router.dart';

/// Driver view for managing a single active trip:
/// - Start / complete trip controls
/// - Live GPS push to backend every 5 seconds
/// - Passenger list with boarding status
class DriverTripScreen extends StatefulWidget {
  final int tripId;
  const DriverTripScreen({super.key, required this.tripId});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  Map<String, dynamic>? _trip;
  List<dynamic> _passengers = [];
  bool _loading = true;

  // GPS state
  bool _trackingActive = false;
  Timer? _locationTimer;
  Position? _currentPosition;
  final _mapController = MapController();

  static const _campusCenter = LatLng(-1.3019, 36.7813);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadTrip();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _stopTracking();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    setState(() => _loading = true);
    try {
      final trips = await apiService.getDriverTrips();
      final trip = trips.firstWhere(
        (t) => t['id'] == widget.tripId,
        orElse: () => <String, dynamic>{},
      );
      final passengers = await apiService.getTripPassengers(widget.tripId);
      setState(() {
        _trip = trip.isNotEmpty ? trip : null;
        _passengers = passengers;
        _loading = false;
        // Auto-start tracking if trip is already in_progress
        if (_trip?['status'] == 'in_progress') _startTracking();
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── Trip Status Controls ──────────────────────────────────────────────────────

  Future<void> _startTrip() async {
    final confirm = await _confirm('Start Trip',
        'This will mark the trip as IN PROGRESS and begin live tracking.');
    if (!confirm) return;
    try {
      await apiService.updateTripStatus(widget.tripId, 'in_progress');
      _startTracking();
      await _loadTrip();
      _showSnack('Trip started! Live tracking is now active.', color: Colors.green);
    } catch (e) {
      _showSnack('Failed to start trip. Try again.');
    }
  }

  Future<void> _completeTrip() async {
    final confirm = await _confirm('Complete Trip', 'Mark this trip as completed?');
    if (!confirm) return;
    try {
      _stopTracking();
      await apiService.updateTripStatus(widget.tripId, 'completed');
      await _loadTrip();
      _showSnack('Trip completed successfully!', color: Colors.green);
    } catch (e) {
      _showSnack('Failed to complete trip. Try again.');
    }
  }

  // ── GPS Tracking ──────────────────────────────────────────────────────────────

  Future<void> _startTracking() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    setState(() => _trackingActive = true);
    // Push location every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pushLocation());
    _pushLocation(); // immediate first push
  }

  void _stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    setState(() => _trackingActive = false);
  }

  Future<void> _pushLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = pos;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      });
      await apiService.pushLocation(
        tripId: widget.tripId,
        lat: pos.latitude,
        lng: pos.longitude,
        speed: pos.speed * 3.6, // m/s → km/h
      );
    } catch (_) {
      // Silent fail — network may momentarily drop
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.maroon)));
    }
    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const EmptyState(icon: Icons.error_outline, title: 'Trip not found'),
      );
    }

    final schedule = _trip!['schedule_detail'];
    final route = schedule?['route_detail'];
    final status = _trip!['status'] as String? ?? 'scheduled';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Trip #${widget.tripId}'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Passengers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildOverview(route, schedule, status),
          _buildPassengers(),
        ],
      ),
    );
  }

  Widget _buildOverview(dynamic route, dynamic schedule, String status) {
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _campusCenter;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route summary card
          GradientHeaderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    StatusBadge(
                      label: status.replaceAll('_', ' '),
                      color: status == 'in_progress'
                          ? Colors.greenAccent
                          : Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _tripStat('Departure', schedule?['departure_time'] ?? '—'),
                    const SizedBox(width: 24),
                    _tripStat('Date', _trip!['date'] ?? '—'),
                    const SizedBox(width: 24),
                    _tripStat('Passengers', '${_passengers.length}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // GPS Map
          const SectionHeader(title: 'Live Location'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.utms.mobile',
                  ),
                  if (_currentPosition != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.maroon,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.maroon.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),

          if (_trackingActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Broadcasting live location every 5s',
                    style:
                        TextStyle(fontSize: 11, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action buttons
          if (status == 'scheduled')
            LoadingButton(
              loading: false,
              onPressed: _startTrip,
              label: '▶  Start Trip & Begin Tracking',
              color: const Color(0xFF2E7D32),
            )
          else if (status == 'in_progress')
            Column(
              children: [
                LoadingButton(
                  loading: false,
                  onPressed: _completeTrip,
                  label: '✓  Mark Trip as Completed',
                  color: AppTheme.maroon,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go('/driver/scan'),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan Student QR Code'),
                ),
              ],
            )
          else if (status == 'completed')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('This trip has been completed.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tripStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildPassengers() {
    if (_passengers.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No passengers yet',
        subtitle: 'No confirmed bookings for this trip.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrip,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _passengers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final p = _passengers[i];
          final student = p['student_detail'] ?? {};
          final profile = student['student_profile'] ?? {};
          final boarded = p['boarded'] == true;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: boarded
                      ? Colors.green.shade200
                      : Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: boarded
                      ? Colors.green.shade50
                      : AppTheme.maroon.withOpacity(0.08),
                  child: Text(
                    '${student['first_name']?[0] ?? ''}${student['last_name']?[0] ?? ''}',
                    style: TextStyle(
                      color: boarded ? Colors.green : AppTheme.maroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        profile['admission_number'] ?? '—',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (boarded)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else
                  StatusBadge(
                    label: p['status'] ?? 'pending',
                    color: StatusBadge.colorForStatus(p['status']),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }
}
