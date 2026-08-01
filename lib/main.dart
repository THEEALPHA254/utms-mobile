// ─────────────────────────────────────────────────────────────────────────────
// APP ENTRY POINT
// This is the very first Dart file Flutter runs. Its job is to:
//   1. Bootstrap the Flutter engine (WidgetsFlutterBinding).
//   2. Wrap the whole app in a Riverpod `ProviderScope` so any widget below
//      can read state via `ref.watch(...)`.
//   3. Build a `MaterialApp.router` that hands routing/theming to
//      go_router and our AppTheme.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
// Riverpod is the state-management library we use. `ProviderScope` is the
// root container that stores every provider's value; `ConsumerWidget` gives a
// widget access to `ref` so it can read those providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';   // exposes the current ThemeMode (light/dark/system)
import 'utils/app_theme.dart';            // holds the light + dark ThemeData
import 'utils/router.dart';               // holds the go_router config (all routes + auth guard)

void main() async {
  // Required whenever `main` does anything before `runApp` (async work,
  // plugin channels, etc.). Prepares the Flutter engine bindings.
  WidgetsFlutterBinding.ensureInitialized();

  // `runApp` mounts the widget tree. Wrapping in `ProviderScope` is how
  // Riverpod stores state — no ProviderScope means providers cannot be read.
  runApp(const ProviderScope(child: UTMSApp()));
}

// `ConsumerWidget` = a stateless widget that also receives `ref`, letting us
// subscribe to Riverpod providers inside `build`. When a watched provider
// changes, `build` re-runs automatically.
class UTMSApp extends ConsumerWidget {
  const UTMSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `ref.watch` subscribes: whenever the router or theme mode changes,
    // this widget rebuilds so the whole app picks up the new value.
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // `MaterialApp.router` is used (instead of the plain `MaterialApp`) because
    // navigation is driven declaratively by go_router.
    return MaterialApp.router(
      title: 'UTMS',
      debugShowCheckedModeBanner: false, // hides the red DEBUG banner in dev builds
      theme: AppTheme.light,              // used when themeMode = light
      darkTheme: AppTheme.dark,           // used when themeMode = dark
      themeMode: themeMode,               // chooses between the two above (or follows system)
      routerConfig: router,               // wires go_router into MaterialApp
    );
  }
}
