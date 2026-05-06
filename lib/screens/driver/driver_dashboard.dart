import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  List<dynamic> _todayTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final trips = await apiService.getDriverTrips(date: dateStr);
      setState(() {
        _todayTrips = trips;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        color: AppTheme.maroon,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 170,
              pinned: true,
              floating: false,
              backgroundColor: AppTheme.maroon,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_outlined, color: Colors.white),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_bus_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good ${_greeting()}, Driver',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(
                                '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
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
                  // ── Stats row ───────────────────────────────────────────────
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // ── Quick actions ───────────────────────────────────────────
                  const SectionHeader(title: "Driver Actions"),
                  const SizedBox(height: 12),
                  _buildActionGrid(context),
                  const SizedBox(height: 24),

                  // ── Today's trips ───────────────────────────────────────────
                  const SectionHeader(title: "Today's Trips"),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.maroon))
                  else if (_todayTrips.isEmpty)
                    const EmptyState(
                      icon: Icons.directions_bus_outlined,
                      title: 'No trips today',
                      subtitle: 'You have no scheduled trips for today.',
                    )
                  else
                    ..._todayTrips.map((t) => _TripCard(
                          trip: t,
                          onTap: () => context.go('/driver/trip/${t['id']}'),
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _todayTrips.length;
    final inProgress = _todayTrips.where((t) => t['status'] == 'in_progress').length;
    final completed = _todayTrips.where((t) => t['status'] == 'completed').length;

    return Row(
      children: [
        _StatCard(label: 'Today\'s Trips', value: '$total', color: AppTheme.maroon,
            icon: Icons.route_outlined),
        const SizedBox(width: 10),
        _StatCard(label: 'In Progress', value: '$inProgress', color: AppTheme.orange,
            icon: Icons.play_circle_outline),
        const SizedBox(width: 10),
        _StatCard(label: 'Completed', value: '$completed', color: const Color(0xFF2E7D32),
            icon: Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final items = [
      _ActionItem(Icons.qr_code_scanner_rounded, 'Scan QR', AppTheme.maroon,
          () => context.go('/driver/scan')),
      _ActionItem(Icons.map_outlined, 'Track Trip', AppTheme.orange,
          () => context.go('/driver/trips')),
      _ActionItem(Icons.people_outline, 'Passengers', const Color(0xFF1565C0),
          () => context.go('/driver/trips')),
      _ActionItem(Icons.history_outlined, 'Trip History', const Color(0xFF2E7D32),
          () => context.go('/driver/history')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items
          .map((a) => GestureDetector(
                onTap: a.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: a.color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: a.color.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(a.icon, size: 18, color: a.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(a.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: a.color)),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final schedule = trip['schedule_detail'];
    final route = schedule?['route_detail'];
    final bus = schedule?['bus_detail'];
    final status = trip['status'] as String? ?? 'scheduled';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.maroon.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_bus_rounded,
                      size: 18, color: AppTheme.maroon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${route?['origin'] ?? ''} → ${route?['destination'] ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Bus ${bus?['bus_number'] ?? ''} · Dep. ${schedule?['departure_time'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                    label: status.replaceAll('_', ' '),
                    color: StatusBadge.colorForStatus(status)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.people_outline, '${trip['seats_booked'] ?? 0} boarded'),
                const SizedBox(width: 8),
                _chip(Icons.event_seat_outlined,
                    '${trip['available_seats'] ?? '?'} seats left'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      );
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.color, this.onTap);
}
