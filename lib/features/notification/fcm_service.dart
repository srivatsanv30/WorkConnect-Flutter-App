import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      debugPrint('FCM: requesting permission...');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM: permission status = ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: permission denied, stopping');
        return;
      }

      String? token;
      try {
        token = await _messaging.getToken();
        debugPrint('FCM: token = $token');
      } catch (e) {
        debugPrint('FCM: getToken failed: $e');
      }

      if (token != null) {
        await NotificationService().registerDeviceToken(token);
        debugPrint('FCM: token sent to backend');
      }

      _messaging.onTokenRefresh.listen((newToken) {
        NotificationService().registerDeviceToken(newToken);
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground notification: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('FCM initialization failed (non-fatal): $e');
    }
  }
}