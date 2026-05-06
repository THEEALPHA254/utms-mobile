import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final profile = user?['student_profile'];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar & name
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(user?['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade600)),
            ]),
          ),
          const SizedBox(height: 28),

          const Text('Account Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          _InfoCard(items: [
            _InfoRow(Icons.badge_outlined, 'Admission No',
                profile?['admission_number'] ?? '—'),
            _InfoRow(Icons.card_membership_outlined, 'Student ID',
                profile?['student_id'] ?? '—'),
            _InfoRow(Icons.school_outlined, 'Faculty',
                profile?['faculty'] ?? '—'),
            _InfoRow(Icons.phone_outlined, 'Phone',
                user?['phone_number'] ?? '—'),
          ]),

          const SizedBox(height: 20),

          const Text('Transport Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          _InfoCard(items: [
            _InfoRow(
              Icons.directions_bus_outlined,
              'Transport Status',
              profile?['transport_status'] ?? '—',
              valueColor: _statusColor(profile?['transport_status']),
            ),
            _InfoRow(Icons.account_balance_wallet_outlined, 'Wallet Balance',
                'KES ${profile?['wallet_balance'] ?? '0.00'}'),
          ]),

          const SizedBox(height: 28),

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
                  content: const Text('Are you sure you want to sign out?'),
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
        ]),
      ),
    );
  }

  Color _statusColor(String? s) {
    return {'active': Colors.green, 'inactive': Colors.grey, 'suspended': Colors.red}[s] ??
        Colors.grey;
  }
}

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
                      leading: Icon(row.icon, size: 20, color: Colors.grey),
                      title: Text(row.label,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      trailing: Text(row.value,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: row.valueColor)),
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
