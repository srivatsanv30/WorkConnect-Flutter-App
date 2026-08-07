/// App-wide constants.
///
/// baseUrl depends on where you're running the app:
///   - Chrome / web            -> http://localhost:5000/api   (use this one)
///   - Android emulator        -> http://10.0.2.2:5000/api
///   - iOS simulator           -> http://localhost:5000/api
///   - Physical phone          -> http://<your-computer-LAN-IP>:5000/api
class AppConstants {
  AppConstants._();

  static const String appName = 'WorkConnect';

static const String baseUrl = 'http://10.0.2.2:5000/api';
}
