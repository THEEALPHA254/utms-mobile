// ─────────────────────────────────────────────────────────────────────────────
// UNREAD NOTIFICATION COUNT PROVIDER
//
// Powers the red badge on the notifications bell in the app bar. Kept
// deliberately small — just an integer — so it can be refreshed cheaply
// without pulling the whole notifications list.
//
// KEY CONCEPTS:
//   • `AsyncNotifier<int>` is Riverpod's built-in wrapper for async state.
//     The exposed state is `AsyncValue<int>` which is either:
//         - AsyncLoading      (spinner in progress)
//         - AsyncData(value)  (successfully loaded)
//         - AsyncError(err)   (something went wrong)
//     Widgets use `.when(loading:, data:, error:)` to render all three cases.
//   • `AsyncValue.guard(fn)` runs `fn` and wraps any thrown error into an
//     `AsyncError` automatically, so we don't have to try/catch by hand.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Tracks the number of unread notifications for the badge on the bell icon.
class UnreadCountNotifier extends AsyncNotifier<int> {
  // First read = first fetch. Riverpod stores the returned Future so
  // subsequent reads get the same in-flight promise (no double calls).
  @override
  Future<int> build() => _fetch();

  // Actual network call. Fails gracefully to 0 so the badge never crashes
  // the UI when the server is unreachable.
  Future<int> _fetch() async {
    try {
      final count = await apiService.getUnreadNotificationCount();
      return count;
    } catch (_) {
      return 0;
    }
  }

  // Public "force refresh" — screens call this after marking a notification
  // read so the badge updates immediately.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  // Optimistic reset — used when the user hits "Mark all read", we can zero
  // the badge instantly without waiting for the server round-trip.
  void clear() => state = const AsyncData(0);
}

// Exposed as an AsyncNotifierProvider so the widget layer can watch it and
// automatically rebuild when the count changes.
final unreadCountProvider =
    AsyncNotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);
