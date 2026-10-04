import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/core/widgets/uc_page_header.dart';
import 'package:uczciwa_cena/features/alerts/data/alerts_repository.dart';
import 'package:uczciwa_cena/models/alert.dart';
import 'package:uczciwa_cena/models/search_area.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key, required this.alert});

  final Alert alert;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć alert?'),
        content: const Text('Nie będzie już dopasowywał nowych ogłoszeń.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await GetIt.instance<AlertsRepository>().delete(alert.id);
      if (context.mounted) {
        context.pop();
      }
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się usunąć alertu')),
        );
      }
    }
  }

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
              UCPageHeader(
                title: 'Opis alertu',
                trailing: IconButton(
                  tooltip: 'Usuń alert',
                  onPressed: () => _delete(context),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
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
