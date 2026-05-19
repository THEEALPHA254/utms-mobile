import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Tracks the number of unread notifications for the badge on the bell icon.
class UnreadCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => _fetch();

  Future<int> _fetch() async {
    try {
      final count = await apiService.getUnreadNotificationCount();
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void clear() => state = const AsyncData(0);
}

final unreadCountProvider =
    AsyncNotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);
