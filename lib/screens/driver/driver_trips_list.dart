import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Driver's full trip list with date filter and status tabs.
class DriverTripsListScreen extends StatefulWidget {
  const DriverTripsListScreen({super.key});

  @override
  State<DriverTripsListScreen> createState() => _DriverTripsListScreenState();
}

class _DriverTripsListScreenState extends State<DriverTripsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _allTrips = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final date =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final trips = await apiService.getDriverTrips(date: date);
      setState(() {
        _allTrips = trips;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _filtered(String status) =>
      _allTrips.where((t) => t['status'] == status).toList();

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
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
      appBar: AppBar(
        title: const Text('My Trips'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Scheduled (${_filtered('scheduled').length})'),
            Tab(text: 'Active (${_filtered('in_progress').length})'),
            Tab(text: 'Done (${_filtered('completed').length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date selector
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.maroon))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildList(_filtered('scheduled')),
                      _buildList(_filtered('in_progress')),
                      _buildList(_filtered('completed')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> trips) {
    if (trips.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'No trips here',
        subtitle: 'No trips match the current filter.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final t = trips[i];
          final sched = t['schedule_detail'];
          final route = sched?['route_detail'];
          final bus = sched?['bus_detail'];
          final status = t['status'] as String? ?? '';

          return GestureDetector(
            onTap: () => context.go('/driver/trip/${t['id']}'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: status == 'in_progress'
                    ? Border.all(color: Colors.green.shade300, width: 1.5)
                    : Border.all(color: Colors.grey.shade100),
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
                        color: AppTheme.maroon, size: 20),
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
                        const SizedBox(height: 2),
                        Text(
                          'Bus ${bus?['bus_number']} · ${sched?['departure_time']}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${t['seats_booked'] ?? 0} passengers boarded',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: status.replaceAll('_', ' '),
                    color: StatusBadge.colorForStatus(status),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
