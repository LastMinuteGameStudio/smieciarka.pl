import 'package:flutter/foundation.dart';

/// Builds a URI that opens the device's default maps app at [query].
///
/// Android resolves `geo:` to the installed maps app (Google Maps by default).
/// iOS doesn't handle `geo:`, so Apple Maps is used there.
Uri nativeMapsUri(String query) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return Uri.https('maps.apple.com', '/', {'q': query});
  }
  return Uri(scheme: 'geo', path: '0,0', queryParameters: {'q': query});
}
