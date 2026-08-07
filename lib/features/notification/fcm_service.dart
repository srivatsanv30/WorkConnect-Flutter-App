import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    print('FCM: requesting permission...');
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('FCM: permission status = ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('FCM: permission denied, stopping');
      return;
    }

    final token = await _messaging.getToken();
    print('FCM: token = $token');

    if (token != null) {
      await NotificationService().registerDeviceToken(token);
      print('FCM: token sent to backend');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      NotificationService().registerDeviceToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground notification: ${message.notification?.title}');
    });
  }
}