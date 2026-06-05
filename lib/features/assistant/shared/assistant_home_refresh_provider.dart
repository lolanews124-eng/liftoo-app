import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bump to silently reload assistant home / earnings data.
final assistantHomeRefreshProvider = StateProvider<int>((ref) => 0);

void refreshAssistantHome(WidgetRef ref) {
  ref.read(assistantHomeRefreshProvider.notifier).state++;
}
