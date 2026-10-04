import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/core/location/user_location.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';
import 'package:uczciwa_cena/models/search_area.dart';

/// Map where the user drops a pin and picks the search radius around it.
///
/// Centres on the user's location when it's available, otherwise on Warsaw.
/// Reports `null` until a pin is placed.
class SearchAreaPicker extends StatefulWidget {
  const SearchAreaPicker({super.key, required this.onChanged});

  final ValueChanged<SearchArea?> onChanged;

  @override
  State<SearchAreaPicker> createState() => _SearchAreaPickerState();
}

class _SearchAreaPickerState extends State<SearchAreaPicker> {
  static const _minRadiusKm = 1.0;
  static const _maxRadiusKm = 50.0;
  static const _height = 260.0;

  late final Future<LatLng> _initialCenter = currentLocationOr(warsawCenter);

  LatLng? _pin;
  double _radiusKm = 5;

  void _notify() {
    final pin = _pin;
    widget.onChanged(
      pin == null ? null : SearchArea(center: pin, radiusKm: _radiusKm),
    );
  }

  void _placePin(LatLng point) {
    setState(() => _pin = point);
    _notify();
  }

  void _changeRadius(double radiusKm) {
    setState(() => _radiusKm = radiusKm);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: _height,
            child: FutureBuilder<LatLng>(
              future: _initialCenter,
              builder: (context, snapshot) {
                final center = snapshot.data;
                if (center == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorPalette.mainColor,
                    ),
                  );
                }
                return _buildMap(center, pin);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pin == null
              ? 'Dotknij mapy, aby zaznaczyć środek obszaru'
              : 'Promień: ${_radiusKm.round()} km',
          style: const TextStyle(fontSize: 14, color: ColorPalette.descColor),
        ),
        Slider(
          value: _radiusKm,
          min: _minRadiusKm,
          max: _maxRadiusKm,
          divisions: (_maxRadiusKm - _minRadiusKm).round(),
          label: '${_radiusKm.round()} km',
          activeColor: ColorPalette.mainColor,
          onChanged: _changeRadius,
        ),
      ],
    );
  }

  Widget _buildMap(LatLng center, LatLng? pin) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        onTap: (_, point) => _placePin(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mobile_app',
        ),
        if (pin != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: pin,
                radius: _radiusKm * 1000,
                useRadiusInMeter: true,
                color: ColorPalette.mainColor.withValues(alpha: 0.2),
                borderColor: ColorPalette.mainColor,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        if (pin != null)
          MarkerLayer(
            markers: [
              Marker(
                point: pin,
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
    );
  }
}
