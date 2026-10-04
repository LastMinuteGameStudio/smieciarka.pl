import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/models/alert.dart';
import 'package:uczciwa_cena/models/search_area.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final area = alert.area;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UCPageHeader(title: 'Opis alertu'),
              const SizedBox(height: 24),
              Text(
                alert.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ColorPalette.titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 18,
                  color: ColorPalette.descColor,
                ),
              ),
              if (area != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Obszar poszukiwań',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                _AreaMap(area: area),
                const SizedBox(height: 8),
                Text(
                  'Promień: ${area.radiusKm.round()} km',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColorPalette.descColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only map that frames the alert's search circle.
class _AreaMap extends StatelessWidget {
  const _AreaMap({required this.area});

  final SearchArea area;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: _boundsOf(area),
              padding: const EdgeInsets.all(24),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile_app',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: area.center,
                  radius: area.radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: ColorPalette.mainColor.withValues(alpha: 0.2),
                  borderColor: ColorPalette.mainColor,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: area.center,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: ColorPalette.mainColor,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bounding box of the circle, from points at north, east, south and west.
  static LatLngBounds _boundsOf(SearchArea area) {
    const distance = Distance();
    final radiusM = area.radiusKm * 1000;
    return LatLngBounds.fromPoints([
      for (final bearing in [0.0, 90.0, 180.0, 270.0])
        distance.offset(area.center, radiusM, bearing),
    ]);
  }
}
