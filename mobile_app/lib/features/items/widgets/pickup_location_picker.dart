import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uczciwa_cena/core/location/user_location.dart';
import 'package:uczciwa_cena/core/theme/color_palette.dart';

/// Map where the owner drops a pin on the pickup spot.
///
/// Centres on the user's location when it's available. Reports `null` until
/// a pin is placed.
class PickupLocationPicker extends StatefulWidget {
  const PickupLocationPicker({super.key, required this.onChanged});

  final ValueChanged<LatLng?> onChanged;

  @override
  State<PickupLocationPicker> createState() => _PickupLocationPickerState();
}

class _PickupLocationPickerState extends State<PickupLocationPicker> {
  static const _height = 260.0;

  late final Future<LatLng> _initialCenter = currentLocationOr(warsawCenter);

  LatLng? _pin;

  void _placePin(LatLng point) {
    setState(() => _pin = point);
    widget.onChanged(point);
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
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                    onTap: (_, point) => _placePin(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mobile_app',
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
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pin == null
              ? 'Dotknij mapy, aby zaznaczyć miejsce odbioru'
              : 'Miejsce odbioru zaznaczone',
          style: const TextStyle(fontSize: 14, color: ColorPalette.descColor),
        ),
      ],
    );
  }
}
