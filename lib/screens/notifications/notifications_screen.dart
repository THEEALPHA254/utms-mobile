import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notifications_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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

  Future<void> _markAllRead() async {
    await apiService.markAllNotificationsRead();
    // Clear the badge on the home screen bell
    ref.read(unreadCountProvider.notifier).clear();
    _load();
  }

  Future<void> _markOneRead(dynamic n) async {
    if (n['is_read'] == true) return;
    await apiService.markNotificationRead(n['id'] as int);
    ref.read(unreadCountProvider.notifier).refresh();
    _load();
  }

  IconData _categoryIcon(String? cat) => {
        'booking': Icons.confirmation_number_outlined,
        'payment': Icons.payment_outlined,
        'trip':    Icons.directions_bus_outlined,
        'system':  Icons.info_outline,
      }[cat] ??
      Icons.notifications_outlined;

  Color _categoryColor(String? cat) => {
        'booking': const Color(0xFF2E7D32),
        'payment': const Color(0xFF1565C0),
        'trip':    AppTheme.orange,
        'system':  const Color(0xFF6A1B9A),
      }[cat] ??
      Colors.grey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = _notifications.any((n) => n['is_read'] == false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
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
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications',
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : Colors.grey.shade600),
                      ),
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
                      final n      = _notifications[i];
                      final isRead = n['is_read'] == true;
                      final cat    = n['category'] as String?;
                      final color  = _categoryColor(cat);

                      // Unread: warm maroon/orange tint; Read: plain surface
                      final tileBg = isRead
                          ? null
                          : (isDark
                              ? AppTheme.maroon.withOpacity(0.18)
                              : AppTheme.maroon.withOpacity(0.06));

                      // Always use high-contrast text — never let it wash out
                      final titleColor = isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary;
                      final bodyColor = isDark
                          ? AppTheme.darkTextSecondary
                          : const Color(0xFF3D3535);
                      final timeColor = isDark
                          ? AppTheme.darkTextHint
                          : AppTheme.textHint;

                      return InkWell(
                        onTap: () => _markOneRead(n),
                        child: Container(
                          color: tileBg,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category icon avatar
                              CircleAvatar(
                                backgroundColor: color.withOpacity(0.14),
                                child: Icon(
                                  _categoryIcon(cat),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['title'] ?? '',
                                            style: TextStyle(
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                              fontSize: 14,
                                              color: titleColor,
                                            ),
                                          ),
                                        ),
                                        // Unread indicator dot
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                                left: 6, top: 3),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.maroon,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n['body'] ?? '',
                                      style: TextStyle(
                                          fontSize: 13, color: bodyColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['created_at'] != null
                                          ? _formatDate(n['created_at'])
                                          : '',
                                      style: TextStyle(
                                          fontSize: 11, color: timeColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
