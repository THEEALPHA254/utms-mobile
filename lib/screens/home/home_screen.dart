import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, dynamic>? _balance;
  List<dynamic> _upcoming = [];
  bool _loading = true;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    ref.read(unreadCountProvider.notifier).refresh();
    setState(() => _loading = true);

    // Run independently so one failure doesn't hide the other
    final balanceFuture = apiService.getWalletBalance().then((v) {
      if (mounted) setState(() => _balance = v);
    }).catchError((_) {});

    final bookingsFuture = apiService.getMyBookings().then((bookings) {
      if (mounted) {
        setState(() {
          _upcoming = bookings
              .where((b) => b['status'] == 'confirmed')
              .take(3)
              .toList();
        });
      }
    }).catchError((_) {});

    await Future.wait([balanceFuture, bookingsFuture]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth    = ref.watch(authProvider);
    final user    = auth.user;
    final profile = user?['student_profile'];
    final unread  = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppTheme.maroon,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 195,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.maroon,
              actions: [
                // Notification bell with unread dot
                _NotificationBell(unreadCount: unread),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () => context.go('/home/profile'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.maroon, AppTheme.maroonDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Hello, ${user?['first_name'] ?? 'Student'}! 👋',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?['admission_number'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?['faculty'] ?? '',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWalletCard(),
                  const SizedBox(height: 22),

                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 22),

                  SectionHeader(
                    title: 'My Bookings',
                    action: 'See all',
                    onAction: () => context.go('/home/my-bookings'),
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(
                        child: CircularProgressIndicator(color: AppTheme.maroon))
                  else if (_upcoming.isEmpty)
                    EmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title: 'No upcoming bookings',
                      subtitle: 'Book a trip to get started!',
                      actionLabel: 'Book Now',
                      onAction: () => context.go('/home/routes'),
                    )
                  else
                    ..._upcoming.map((b) => _BookingCard(booking: b)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final String balanceText;
    if (_loading) {
      balanceText = 'Loading...';
    } else if (_balance == null) {
      balanceText = 'Unavailable';
    } else {
      final amount = double.tryParse(_balance!['balance'].toString()) ?? 0.0;
      balanceText = 'KES ${amount.toStringAsFixed(2)}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.orange, AppTheme.orangeLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.orange.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Wallet Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _balanceVisible = !_balanceVisible),
                      child: Icon(
                        _balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _balanceVisible ? balanceText : '••••••',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.go('/home/wallet'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Top Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.orange,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final actions = [
      _QA(Icons.map_outlined, 'Book Trip', AppTheme.maroon,
          () => context.go('/home/routes')),
      _QA(Icons.confirmation_number_outlined, 'My Bookings',
          const Color(0xFF1565C0), () => context.go('/home/my-bookings')),
      _QA(Icons.account_balance_wallet_outlined, 'Wallet', AppTheme.orange,
          () => context.go('/home/wallet')),
      _QA(Icons.location_on_outlined, 'Track Bus', const Color(0xFF2E7D32),
          () => context.go('/home/routes')),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions
          .map((a) => GestureDetector(
                onTap: a.onTap,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: a.color.withOpacity(0.2)),
                      ),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: labelColor, // explicitly dark so it's always readable
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QA(this.icon, this.label, this.color, this.onTap);
}

// ── Notification Bell with unread dot ────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  const _NotificationBell({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.go('/home/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.maroon, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final trip     = booking['trip_detail'];
    final schedule = trip?['schedule_detail'];
    final route    = schedule?['route_detail'];
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final routeTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final metaTextColor  = isDark ? AppTheme.darkTextSecondary : const Color(0xFF555555);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3A2E2E) : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.maroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus_rounded,
                color: AppTheme.maroon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: routeTextColor, // always dark/readable
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trip?['date'] ?? ''} · ${schedule?['departure_time'] ?? ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: metaTextColor, // readable medium-dark
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/home/track/${trip?['id']}'),
            child: Column(
              children: [
                const Icon(Icons.location_on, color: AppTheme.maroon, size: 20),
                Text(
                  'Track',
                  style: TextStyle(fontSize: 10, color: metaTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
