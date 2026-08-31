import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants.dart';
import '../auth/auth_service.dart';

class ChatService {
  io.Socket? _socket;

  Future<void> connect({
    required String jobId,
    required Function(Map<String, dynamic>) onMessage,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    // constants.dart has http://localhost:5000/api — strip the /api for socket base URL
    final baseUrl = AppConstants.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join_job_room', jobId);
    });

    _socket!.on('new_message', (data) {
      onMessage(Map<String, dynamic>.from(data));
    });
  }

  void sendMessage(String jobId, String text, {String? imageUrl}) {
    final payload = <String, dynamic>{'jobId': jobId, 'text': text};
    if (imageUrl != null) {
      payload['imageUrl'] = imageUrl;
    }
    _socket?.emit('send_message', payload);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}