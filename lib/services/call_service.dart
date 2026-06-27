import 'package:url_launcher/url_launcher.dart';

/// Starts a phone call via the platform dialer (`tel:`). Pure side-effect
/// helper so screens don't reach for `url_launcher` directly. Returns whether
/// the dialer could be opened; the caller decides how to surface a failure.
abstract final class CallService {
  static Future<bool> dial(String phone) {
    final digits = phone.replaceAll(RegExp(r'\s'), '');
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }
}
