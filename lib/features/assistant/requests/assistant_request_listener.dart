import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import 'assistant_booking_request_flow.dart';

/// Incoming booking requests via socket + polling; shows Accept/Reject popup.
class AssistantRequestListener extends ConsumerStatefulWidget {
  final Widget child;

  const AssistantRequestListener({super.key, required this.child});

  @override
  ConsumerState<AssistantRequestListener> createState() => _AssistantRequestListenerState();
}

class _AssistantRequestListenerState extends ConsumerState<AssistantRequestListener> with WidgetsBindingObserver {
  bool _dialogOpen = false;
  final _openBookingIds = <String>{};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachSocket();
      _syncPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    ref.read(socketServiceProvider).off('booking:request', _onSocketRequest);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _pollOnce();
  }

  void _attachSocket() {
    ref.read(socketServiceProvider).on('booking:request', _onSocketRequest);
    ref.read(socketServiceProvider).onConnect(() {
      if (assistantCanReceiveRequests(ref)) _pollOnce();
    });
  }

  void _syncPolling() {
    _pollTimer?.cancel();
    if (!assistantCanReceiveRequests(ref)) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollOnce());
    _pollOnce();
  }

  BookingModel? _parseBooking(dynamic data) {
    if (data == null) return null;
    try {
      Map<String, dynamic>? json;
      if (data is Map<String, dynamic>) {
        final nested = data['booking'];
        if (nested is Map<String, dynamic>) {
          json = nested;
        } else if (nested is Map) {
          json = Map<String, dynamic>.from(nested);
        } else if (data['id'] != null && data['status'] != null) {
          json = data;
        }
      } else if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final nested = map['booking'];
        if (nested is Map) {
          json = Map<String, dynamic>.from(nested);
        } else if (map['id'] != null) {
          json = map;
        }
      }
      if (json == null) return null;
      return BookingModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onSocketRequest(dynamic data) async {
    final booking = _parseBooking(data);
    if (booking != null && booking.status == 'searching') {
      await _presentIfNew(booking);
    }
  }

  Future<void> _pollOnce() async {
    if (!mounted || !assistantCanReceiveRequests(ref)) return;
    try {
      final list = await ref.read(bookingRepositoryProvider).getNearbyRequests();
      final activeIds = list.map((b) => b.id).toSet();
      _openBookingIds.removeWhere((id) => !activeIds.contains(id));

      for (final booking in list) {
        if (booking.status != 'searching') continue;
        await _presentIfNew(booking);
        if (_dialogOpen) break;
      }
    } catch (_) {}
  }

  Future<void> _presentIfNew(BookingModel booking) async {
    if (!mounted || _dialogOpen) return;
    if (!assistantCanReceiveRequests(ref)) return;
    if (_openBookingIds.contains(booking.id)) return;

    _dialogOpen = true;
    _openBookingIds.add(booking.id);
    try {
      await presentAssistantBookingRequest(ref, booking: booking);
    } finally {
      if (mounted) _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      final wasOnline = prev?.user?.isOnline ?? false;
      final isOnline = next.user?.isOnline ?? false;
      if (next.user?.activeRole == 'assistant' && wasOnline != isOnline) {
        _syncPolling();
      }
    });
    return widget.child;
  }
}
