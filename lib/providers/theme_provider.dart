// ─────────────────────────────────────────────────────────────────────────────
// THEME MODE PROVIDER — light / dark / system, persisted across app launches
//
// KEY CONCEPTS:
//   • Riverpod holds the CURRENT choice in memory; SharedPreferences persists
//     it to disk so the user's pick survives an app restart.
//   • SharedPreferences (plain key/value storage) is fine here — a theme
//     preference isn't sensitive. Contrast with tokens which use
//     FlutterSecureStorage (encrypted keystore).
//   • `main.dart` watches `themeModeProvider` and rebuilds MaterialApp when
//     it changes → the entire app re-themes instantly.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences key. Underscore prefix marks it as file-private.
const _kThemeKey = 'app_theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Fire-and-forget load of the persisted preference. Meanwhile we return
    // `light` synchronously so the first frame has something to render — the
    // saved value will overwrite it a moment later once disk read completes.
    _loadSaved();
    return ThemeMode.light; // default until persisted value loads
  }

  // Reads the persisted mode (if any) and applies it to state.
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null) {
      state = _fromString(saved);
    }
  }

  // Public setter — updates in-memory state AND persists to disk so the
  // choice sticks between sessions.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _toString(mode));
  }

  // Quick flip used by the switch on the profile screen.
  void toggle() {
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  // Serialise/deserialise helpers — ThemeMode is an enum, but SharedPreferences
  // only stores primitives, so we map to/from a canonical string.
  static String _toString(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : m == ThemeMode.system ? 'system' : 'light';

  static ThemeMode _fromString(String s) =>
      s == 'dark' ? ThemeMode.dark : s == 'system' ? ThemeMode.system : ThemeMode.light;
}

// Widgets/main.dart read this provider to know which ThemeData to apply.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
