import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await apiService.getMyBookings();
    setState(() {
      _bookings = data;
      _loading  = false;
    });
  }

  Color _statusColor(String s) => {
        'confirmed': Colors.green,
        'pending':   Colors.orange,
        'cancelled': Colors.red,
        'completed': Colors.blue,
      }[s] ??
      Colors.grey;

  void _showQR(BuildContext ctx, Map<String, dynamic> booking) {
    final qrData = booking['qr_code']?.toString() ??
        booking['id']?.toString() ??
        'invalid';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white, // always white for QR sheet
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            const Text(
              'Boarding QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary, // always dark on white sheet
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Show this to the driver when boarding',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // QR code: always black on white regardless of theme
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.maroon.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.maroon,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A0A0A), // near-black for maximum contrast
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Code text below QR
            Text(
              qrData,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/home/routes'),
                        child: const Text('Book a Trip'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b     = _bookings[i];
                      final trip  = b['trip_detail'];
                      final route =
                          trip?['schedule_detail']?['route_detail'];
                      final statusColor = _statusColor(b['status'] ?? '');

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route + status row
                              Row(children: [
                                Expanded(
                                  child: Text(
                                    '${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    b['status'] ?? '',
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 8),

                              // Meta info — readable in both themes via Card's onSurface
                              _metaRow('Date',
                                  trip?['date']?.toString() ?? '—'),
                              _metaRow('Amount',
                                  'KES ${b['amount_paid'] ?? '—'}'),
                              if (b['booked_by_name'] != null)
                                _metaRow(
                                    'Paid by', b['booked_by_name']),

                              const SizedBox(height: 12),

                              // Action buttons
                              if (b['status'] == 'confirmed')
                                Row(children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showQR(context, b),
                                      icon: const Icon(
                                          Icons.qr_code, size: 18),
                                      label: const Text('Show QR'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size(0, 40),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.go(
                                          '/home/track/${trip?['id']}'),
                                      icon: const Icon(
                                          Icons.location_on,
                                          size: 18),
                                      label: const Text('Track Bus'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize:
                                            const Size(0, 40),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10)),
                                      ),
                                    ),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ]),
      );
}
