import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

/// Avoid flashing "No internet" when connectivity flickers for a split second.
final debouncedOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityServiceProvider);
  yield await connectivity.isOnline;

  await for (final online in connectivity.onlineStream) {
    if (online) {
      yield true;
      continue;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (await connectivity.isOnline) {
      yield true;
    } else {
      yield false;
    }
  }
});
