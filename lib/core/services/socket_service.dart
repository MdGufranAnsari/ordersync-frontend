import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  io.Socket? _socket;
  String? _currentUserId;
  final List<VoidCallback> _orderUpdatedListeners = [];

  void init(String userId) {
    if (_socket != null && _currentUserId == userId) {
      return; // Already connected for this user
    }

    // Disconnect previous socket if any
    disconnect();

    _currentUserId = userId;

    _socket = io.io(AppConstants.imageBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('[Socket] Connected');
      }
      // Join the personal user room
      _socket!.emit('join_room', userId);
    });

    _socket!.on('order_updated', (_) {
      if (kDebugMode) {
        print('[Socket] Received order_updated event');
      }
      for (final listener in _orderUpdatedListeners) {
        listener();
      }
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        print('[Socket] Disconnected');
      }
    });
  }

  void addOrderListener(VoidCallback callback) {
    if (!_orderUpdatedListeners.contains(callback)) {
      _orderUpdatedListeners.add(callback);
    }
  }

  void removeOrderListener(VoidCallback callback) {
    _orderUpdatedListeners.remove(callback);
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _currentUserId = null;
  }
}
