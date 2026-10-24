import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants.dart';
import '../auth/auth_service.dart';

class ChatService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect({
    required String jobId,
    required Function(Map<String, dynamic>) onMessage,
    Function(Map<String, dynamic>)? onMessageDeleted,
    Function(Map<String, dynamic>)? onMessageDeletedForMe,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    // constants.dart has https://.../api — strip /api for socket base URL
    final baseUrl = AppConstants.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1500)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _socket!.emit('join_job_room', jobId);
    });

    _socket!.on('reconnect', (_) {
      _isConnected = true;
      _socket!.emit('join_job_room', jobId);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.on('new_message', (data) {
      if (data is Map) {
        onMessage(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_deleted', (data) {
      if (data is Map && onMessageDeleted != null) {
        onMessageDeleted(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('message_deleted_for_me', (data) {
      if (data is Map && onMessageDeletedForMe != null) {
        onMessageDeletedForMe(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void sendMessage(String jobId, String text, {String? imageUrl}) {
    final payload = <String, dynamic>{'jobId': jobId, 'text': text};
    if (imageUrl != null) {
      payload['imageUrl'] = imageUrl;
    }
    _socket?.emit('send_message', payload);
  }

  void deleteMessage({
    required String jobId,
    required String messageId,
    required bool forEveryone,
  }) {
    _socket?.emit('delete_message', {
      'jobId': jobId,
      'messageId': messageId,
      'forEveryone': forEveryone,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
  }
}