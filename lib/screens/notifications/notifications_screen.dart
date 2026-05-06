import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getNotifications();
      setState(() {
        _notifications = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _categoryIcon(String? cat) {
    return {
          'booking': Icons.confirmation_number_outlined,
          'payment': Icons.payment_outlined,
          'trip': Icons.directions_bus_outlined,
          'system': Icons.info_outline,
        }[cat] ??
        Icons.notifications_outlined;
  }

  Color _categoryColor(String? cat) {
    return {
          'booking': Colors.green,
          'payment': Colors.blue,
          'trip': Colors.orange,
          'system': Colors.purple,
        }[cat] ??
        Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: () async {
                await apiService.markNotificationRead(-1); // all-read endpoint
                _load();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No notifications',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == true;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        tileColor: isRead ? null : Colors.blue.shade50,
                        leading: CircleAvatar(
                          backgroundColor: _categoryColor(n['category'])
                              .withOpacity(0.12),
                          child: Icon(
                            _categoryIcon(n['category']),
                            color: _categoryColor(n['category']),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(n['body'] ?? '',
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              n['created_at'] != null
                                  ? _formatDate(n['created_at'])
                                  : '',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        onTap: () async {
                          if (!isRead) {
                            await apiService
                                .markNotificationRead(n['id']);
                            _load();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
