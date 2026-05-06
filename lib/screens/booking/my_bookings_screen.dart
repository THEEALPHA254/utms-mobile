import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await apiService.getMyBookings();
    setState(() { _bookings = data; _loading = false; });
  }

  Color _statusColor(String s) {
    return {'confirmed': Colors.green, 'pending': Colors.orange, 'cancelled': Colors.red, 'completed': Colors.blue}[s] ?? Colors.grey;
  }

  void _showQR(BuildContext ctx, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Boarding QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Show this to the driver', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            QrImageView(
              data: booking['qr_code'] ?? booking['id'].toString(),
              version: QrVersions.auto,
              size: 220,
            ),
            const SizedBox(height: 12),
            Text(booking['qr_code'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No bookings yet'),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => context.go('/home/routes'), child: const Text('Book a Trip')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = _bookings[i];
                      final trip = b['trip_detail'];
                      final route = trip?['schedule_detail']?['route_detail'];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: Text('${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(b['status']).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(b['status'], style: TextStyle(color: _statusColor(b['status']), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text('Date: ${trip?['date']}', style: TextStyle(color: Colors.grey.shade600)),
                            Text('Amount: KES ${b['amount_paid']}', style: TextStyle(color: Colors.grey.shade600)),
                            if (b['booked_by_name'] != null)
                              Text('Paid by: ${b['booked_by_name']}', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 12),
                            Row(children: [
                              if (b['status'] == 'confirmed') ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showQR(context, b),
                                    icon: const Icon(Icons.qr_code, size: 18),
                                    label: const Text('Show QR'),
                                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.go('/home/track/${trip?['id']}'),
                                    icon: const Icon(Icons.location_on, size: 18),
                                    label: const Text('Track Bus'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
