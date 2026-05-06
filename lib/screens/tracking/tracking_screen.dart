import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TrackingScreen extends StatefulWidget {
  final int tripId;
  const TrackingScreen({super.key, required this.tripId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  final _mapController = MapController();

  LatLng? _busLocation;
  double _speed = 0;
  String _status = 'Connecting...';
  bool _connected = false;

  // CUEA campus approximate center
  static const _defaultCenter = LatLng(-1.3019, 36.7813);

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    // WebSocket URL — update host for production
    const wsHost = 'ws://10.0.2.2:8000';
    final uri = Uri.parse('$wsHost/ws/trip/${widget.tripId}/');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          if (data['type'] == 'location_update') {
            final lat = double.tryParse(data['latitude'].toString());
            final lng = double.tryParse(data['longitude'].toString());
            final spd = double.tryParse(data['speed_kmh'].toString()) ?? 0;
            if (lat != null && lng != null) {
              setState(() {
                _busLocation = LatLng(lat, lng);
                _speed = spd;
                _status = 'Live tracking active';
                _connected = true;
              });
              _mapController.move(_busLocation!, 15);
            }
          } else if (data['type'] == 'connection') {
            setState(() {
              _status = 'Waiting for bus location...';
              _connected = true;
            });
          }
        },
        onDone: () => setState(() {
          _status = 'Connection closed';
          _connected = false;
        }),
        onError: (_) => setState(() {
          _status = 'Connection error';
          _connected = false;
        }),
      );
    } catch (e) {
      setState(() {
        _status = 'Could not connect';
        _connected = false;
      });
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = _busLocation ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Trip #${widget.tripId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _channel?.sink.close();
              _connectWebSocket();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.utms.mobile',
              ),
              if (_busLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _busLocation!,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 4)
                        ],
                      ),
                      child: const Icon(Icons.directions_bus,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ]),
            ],
          ),

          // Status pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8)
                ],
              ),
              child: Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connected ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_status)),
              ]),
            ),
          ),

          // Speed & info card at bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoTile(
                      icon: Icons.speed,
                      label: 'Speed',
                      value: '${_speed.toStringAsFixed(0)} km/h',
                      color: theme.colorScheme.primary),
                  _InfoTile(
                      icon: Icons.location_on,
                      label: 'Status',
                      value: _busLocation != null ? 'Located' : 'Awaiting',
                      color: _busLocation != null
                          ? Colors.green
                          : Colors.orange),
                  _InfoTile(
                      icon: Icons.trip_origin,
                      label: 'Trip',
                      value: '#${widget.tripId}',
                      color: theme.colorScheme.secondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      );
}
