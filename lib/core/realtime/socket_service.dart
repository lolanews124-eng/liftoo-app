import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  io.Socket? _socket;

  void connect(String token) {
    disconnect();
    _socket = io.io(
      '${AppConfig.apiUrl}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, void Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void joinBooking(String bookingId) {
    final socket = _socket;
    if (socket == null) return;
    void emitJoin(_) => socket.emit('join:booking', bookingId);
    if (socket.connected) {
      socket.emit('join:booking', bookingId);
    } else {
      socket.once('connect', emitJoin);
    }
  }
}
