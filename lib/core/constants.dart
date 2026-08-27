import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide constants.
///
/// baseUrl depends on where you're running the app:
///   - Chrome / web            -> http://localhost:5000/api   (use this one)
///   - Android emulator        -> http://10.0.2.2:5000/api
///   - iOS simulator           -> http://localhost:5000/api
///   - Physical phone          -> http://`your-computer-LAN-IP`:5000/api
class AppConstants {
  AppConstants._();

  static const String appName = 'WorkConnect';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }
}
