import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Digital receipt shown after a successful booking/payment.
/// Accepts a booking map and renders full receipt + QR code.
class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const ReceiptScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final trip = booking['trip_detail'] ?? {};
    final schedule = trip['schedule_detail'] ?? {};
    final route = schedule['route_detail'] ?? {};
    final qrCode = booking['qr_code'] ?? booking['id']?.toString() ?? 'N/A';
    final ref = booking['reference'] ?? '#${booking['id']}';
    final amount = booking['amount_paid'] ?? '0.00';
    final status = booking['status'] ?? 'confirmed';
    final createdAt = booking['created_at'];
    final bookedBy = booking['booked_by_name'];

    String formattedDate = '—';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Booking Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Success Header ──────────────────────────────────────────────
            GradientHeaderCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text('Booking Confirmed!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Your seat has been reserved',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Receipt Card ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.maroon.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppTheme.maroon, size: 20),
                        const SizedBox(width: 8),
                        const Text('Transaction Details',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const Spacer(),
                        StatusBadge(
                          label: status,
                          color: StatusBadge.colorForStatus(status),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Details list
                  InfoRowTile(Icons.tag, 'Transaction ID', ref),
                  const Divider(height: 1, indent: 48),
                  InfoRowTile(Icons.route_outlined, 'Route',
                      '${route['origin'] ?? '—'} → ${route['destination'] ?? '—'}'),
                  const Divider(height: 1, indent: 48),
                  InfoRowTile(Icons.calendar_today_outlined, 'Trip Date',
                      trip['date'] ?? '—'),
                  const Divider(height: 1, indent: 48),
                  InfoRowTile(
                      Icons.access_time_outlined,
                      'Departure',
                      schedule['departure_time'] ?? '—'),
                  const Divider(height: 1, indent: 48),
                  InfoRowTile(Icons.schedule_outlined, 'Paid On', formattedDate),
                  if (bookedBy != null) ...[
                    const Divider(height: 1, indent: 48),
                    InfoRowTile(Icons.person_outline, 'Paid By', bookedBy),
                  ],
                  const Divider(height: 1, indent: 48),

                  // Amount — highlighted
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 18, color: AppTheme.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Amount Paid',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'KES $amount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppTheme.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── QR Code Section ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.maroon.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('Boarding QR Code',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Show this to the driver when boarding',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.maroon.withOpacity(0.15), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.maroon,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF2C1414),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    qrCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Actions ────────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () => context.go('/home/my-bookings'),
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('View All Bookings'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
