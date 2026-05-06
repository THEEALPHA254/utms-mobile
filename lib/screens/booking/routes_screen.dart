// ── routes_screen.dart ──────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});
  @override State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<dynamic> _routes = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await apiService.getRoutes();
    setState(() { _routes = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Route')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _routes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = _routes[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.route, color: theme.colorScheme.primary),
                    ),
                    title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${r['origin']} → ${r['destination']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('KES ${r['fare']}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.go('/home/trips/${r['id']}'),
                  ),
                );
              },
            ),
    );
  }
}
