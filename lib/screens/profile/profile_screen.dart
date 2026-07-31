import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _liveBalance;
  bool _balanceLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _balanceLoading = true);
    try {
      final data = await apiService.getWalletBalance();
      if (mounted) {
        setState(() {
          _liveBalance = double.tryParse(data['balance'].toString())
              ?.toStringAsFixed(2);
          _balanceLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _balanceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth      = ref.watch(authProvider);
    final user      = auth.user;
    final profile   = user?['student_profile'];
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar & name ──────────────────────────────────────────────
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${user?['first_name']?[0] ?? ''}${user?['last_name']?[0] ?? ''}',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${user?['first_name']} ${user?['last_name']}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?['email'] ?? '',
                  style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : Colors.grey.shade600),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Account Details ────────────────────────────────────────────
            _sectionLabel('Account Details'),
            const SizedBox(height: 12),
            _InfoCard(items: [
              _InfoRow(Icons.badge_outlined, 'Admission No',
                  profile?['admission_number'] ?? '—'),
              _InfoRow(Icons.school_outlined, 'Faculty',
                  profile?['faculty'] ?? '—'),
              _InfoRow(Icons.phone_outlined, 'Phone',
                  user?['phone_number'] ?? '—'),
            ]),

            const SizedBox(height: 20),

            // ── Transport Status ───────────────────────────────────────────
            _sectionLabel('Transport Status'),
            const SizedBox(height: 12),
            _InfoCard(items: [
              _InfoRow(
                Icons.directions_bus_outlined,
                'Transport Status',
                profile?['transport_status'] ?? '—',
                valueColor: _statusColor(profile?['transport_status']),
              ),
              _InfoRow(
                Icons.account_balance_wallet_outlined,
                'Wallet Balance',
                _balanceLoading
                    ? 'Loading...'
                    : 'KES ${_liveBalance ?? profile?['wallet_balance'] ?? '0.00'}',
              ),
            ]),

            const SizedBox(height: 20),

            // ── Appearance ─────────────────────────────────────────────────
            _sectionLabel('Appearance'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Light mode tile
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      title: const Text('Light Mode'),
                      secondary: const Icon(Icons.light_mode_outlined),
                      activeColor: theme.colorScheme.primary,
                      onChanged: (m) =>
                          ref.read(themeModeProvider.notifier).setMode(m!),
                    ),
                    Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF3A2E2E)
                            : Colors.grey.shade100),
                    // Dark mode tile
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      title: const Text('Dark Mode'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      activeColor: theme.colorScheme.primary,
                      onChanged: (m) =>
                          ref.read(themeModeProvider.notifier).setMode(m!),
                    ),
                    Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF3A2E2E)
                            : Colors.grey.shade100),
                    // System mode tile
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      title: const Text('Follow System'),
                      secondary:
                          const Icon(Icons.settings_suggest_outlined),
                      activeColor: theme.colorScheme.primary,
                      onChanged: (m) =>
                          ref.read(themeModeProvider.notifier).setMode(m!),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Actions ────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => context.go('/home/wallet'),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Manage Wallet'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out'),
                    content:
                        const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) => Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      );

  Color _statusColor(String? s) =>
      {'active': Colors.green, 'inactive': Colors.grey, 'suspended': Colors.red}[s] ??
      Colors.grey;
}

// ── Info Card & Row ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: items
                .map((row) => ListTile(
                      dense: true,
                      leading: Icon(row.icon, size: 20),
                      title: Text(
                        row.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        row.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: row.valueColor,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      );
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});
}
