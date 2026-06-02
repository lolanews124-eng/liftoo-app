import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  io.Socket? _socket;
  String? _token;
  final Map<String, List<void Function(dynamic)>> _handlers = {};
  final List<void Function()> _connectListeners = [];

  bool get isConnected => _socket?.connected ?? false;

  void onConnect(void Function() listener) {
    _connectListeners.add(listener);
    if (isConnected) listener();
  }

  void offConnect(void Function() listener) {
    _connectListeners.remove(listener);
  }

  void connect(String token) {
    if (_token == token && isConnected) return;
    _token = token;
    disconnect();
    final base = AppConfig.apiUrl.endsWith('/')
        ? AppConfig.apiUrl.substring(0, AppConfig.apiUrl.length - 1)
        : AppConfig.apiUrl;

    _socket = io.io(
      '$base/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1500)
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[Socket] connected');
      for (final listener in List<void Function()>.from(_connectListeners)) {
        listener();
      }
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) debugPrint('[Socket] disconnected');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('[Socket] connect error: $err');
    });

    for (final entry in _handlers.entries) {
      for (final handler in entry.value) {
        _socket!.on(entry.key, handler);
      }
    }

    _socket!.connect();
  }

  void disconnect() {
    _token = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, void Function(dynamic) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic)? handler]) {
    if (handler != null) {
      _handlers[event]?.remove(handler);
      _socket?.off(event, handler);
    } else {
      _handlers.remove(event);
      _socket?.off(event);
    }
  }

  void joinBooking(String bookingId) {
    final socket = _socket;
    if (socket == null) return;
    void emitJoin(_) => socket.emit('join:booking', bookingId);
    if (socket.connected) {
      emitJoin(null);
    } else {
      socket.once('connect', emitJoin);
    }
  }
}
