import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Used when the device location is unavailable.
const warsawCenter = LatLng(52.2297, 21.0122);

/// The device's current position, or [fallback] when location services are
/// off, permission is refused, or the position can't be read in time.
Future<LatLng> currentLocationOr(LatLng fallback) async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!granted || !await Geolocator.isLocationServiceEnabled()) {
      return fallback;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  } on Exception {
    return fallback;
  }
}
