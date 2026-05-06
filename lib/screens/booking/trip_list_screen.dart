import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

// ── Trip List ─────────────────────────────────────────────────────────────────

class TripListScreen extends StatefulWidget {
  final String routeId;
  const TripListScreen({super.key, required this.routeId});
  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<dynamic> _trips = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final data = await apiService.getTrips(date: dateStr, routeId: widget.routeId);
    setState(() {
      _trips = data;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Available Trips')),
      body: Column(
        children: [
          // Date picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.maroon.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.maroon, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                          color: AppTheme.maroon, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar, color: AppTheme.maroon, size: 16),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.maroon))
                : _trips.isEmpty
                    ? const EmptyState(
                        icon: Icons.bus_alert,
                        title: 'No trips available',
                        subtitle: 'There are no trips scheduled for this route on the selected date.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _trips.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = _trips[i];
                            final schedule = t['schedule_detail'];
                            final bus = schedule?['bus_detail'];
                            final avail = t['available_seats'] ?? 0;
                            final fare = schedule?['route_detail']?['fare'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.maroon.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.directions_bus_rounded,
                                        color: AppTheme.maroon, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Departs ${schedule?['departure_time'] ?? '—'}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                        Text(
                                          'Bus ${bus?['bus_number']} · ${bus?['plate_number']}',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          '$avail seats left',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: avail > 5
                                                  ? Colors.green
                                                  : Colors.orange),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'KES $fare',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.orange,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      avail > 0
                                          ? ElevatedButton(
                                              onPressed: () =>
                                                  context.go('/home/book/${t['id']}'),
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: const Size(70, 34),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12),
                                              ),
                                              child: const Text('Book'),
                                            )
                                          : const Chip(
                                              label: Text('Full',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11)),
                                              backgroundColor: Colors.red,
                                              padding: EdgeInsets.zero,
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Booking Confirm ───────────────────────────────────────────────────────────

class BookingConfirmScreen extends StatefulWidget {
  final int tripId;
  const BookingConfirmScreen({super.key, required this.tripId});
  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _payForPeer = false;
  final _admissionCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  String _paymentMethod = 'wallet'; // 'wallet' or 'mpesa'
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _admissionCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_paymentMethod == 'mpesa' && _phoneCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your M-Pesa phone number.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final booking = await apiService.createBooking({
        'trip_id': widget.tripId,
        'payment_method': _paymentMethod,
        if (_paymentMethod == 'mpesa') 'phone_number': _phoneCtrl.text.trim(),
        if (_payForPeer && _admissionCtrl.text.isNotEmpty)
          'student_admission': _admissionCtrl.text.trim(),
      });

      if (!mounted) return;
      // Navigate to receipt screen with the booking data
      context.go('/home/receipt', extra: booking);
    } catch (e) {
      final msg = e.toString();
      setState(() {
        _error = msg.contains('Insufficient')
            ? 'Insufficient wallet balance. Please top up.'
            : msg.contains('already has a booking')
                ? 'This student already has a booking for this trip.'
                : 'Booking failed. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip summary
            GradientHeaderCard(
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trip Booking',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Trip #${widget.tripId}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment method
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            _PayMethodSelector(
              selected: _paymentMethod,
              onSelect: (m) => setState(() => _paymentMethod = m),
            ),

            if (_paymentMethod == 'mpesa') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone (e.g. 0712345678)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'An STK push will be sent to your phone. Complete payment on your handset.',
                        style: TextStyle(fontSize: 12, color: AppTheme.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Pay for peer
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: SwitchListTile(
                title: const Text('Pay for a Peer',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Book on behalf of another student',
                    style: TextStyle(fontSize: 12)),
                value: _payForPeer,
                activeColor: AppTheme.maroon,
                onChanged: (v) => setState(() => _payForPeer = v),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),

            if (_payForPeer) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _admissionCtrl,
                decoration: const InputDecoration(
                  labelText: "Peer's Admission Number",
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(_error!),
            ],

            const SizedBox(height: 28),

            LoadingButton(
              loading: _loading,
              onPressed: _confirm,
              label: _paymentMethod == 'wallet'
                  ? 'Confirm & Pay from Wallet'
                  : 'Confirm & Pay via M-Pesa',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Method Selector ───────────────────────────────────────────────────

class _PayMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _PayMethodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Tile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            value: 'wallet',
            selected: selected == 'wallet',
            onTap: () => onSelect('wallet'),
          ),
          const SizedBox(width: 12),
          _Tile(
            icon: Icons.phone_android_outlined,
            label: 'M-Pesa',
            value: 'mpesa',
            selected: selected == 'mpesa',
            onTap: () => onSelect('mpesa'),
          ),
        ],
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _Tile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.maroon.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppTheme.maroon : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    color: selected ? AppTheme.maroon : Colors.grey,
                    size: 24),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      color: selected ? AppTheme.maroon : Colors.grey.shade600,
                      fontSize: 13,
                    )),
              ],
            ),
          ),
        ),
      );
}
