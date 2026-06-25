import 'package:url_launcher/url_launcher.dart';

/// Opens turn-by-turn navigation in Google Maps using a deep link, with
/// graceful fallbacks for devices without the Maps app installed.
class MapsLauncher {
  MapsLauncher._();

  static Future<bool> navigateTo(double lat, double lng) async {
    // Preferred: Google Maps turn-by-turn navigation intent.
    final navUri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(navUri)) {
      return launchUrl(navUri, mode: LaunchMode.externalApplication);
    }

    // Fallback: geo: scheme (any maps app).
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }

    // Final fallback: web Google Maps directions.
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> dialPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
