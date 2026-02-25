import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_picker_logic.dart';

class MapPickerScreen extends StatefulWidget {
  final Map<String, double>? initial;
  final bool autoZoom;

  const MapPickerScreen({
    super.key,
    this.initial,
    this.autoZoom = false,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapPickerLogic logic;

  @override
  void initState() {
    super.initState();
    logic = MapPickerLogic(
      initial: widget.initial,
      autoZoom: widget.autoZoom,
    );
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  void _confirm() {
    if (logic.picked == null) return;
    Navigator.pop(context, {
      'lat': logic.picked!.latitude,
      'lng': logic.picked!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        final center = logic.picked ??
            (widget.initial != null
                ? LatLng(widget.initial!['lat']!, widget.initial!['lng']!)
                : MapPickerLogic.defaultCenter);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pick Location'),
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: 'My Location',
                onPressed: logic.goToCurrentLocation,
              ),
              if (logic.picked != null)
                TextButton(
                  onPressed: _confirm,
                  child: const Text('Confirm',
                      style: TextStyle(color: Colors.black)),
                ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: logic.mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: widget.autoZoom ? 16 : 14,
                  onTap: (tapPosition, point) => logic.onMapTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.form_dynamic_builder',
                  ),
                  if (logic.picked != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: logic.picked!,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Instruction banner
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(
                      logic.picked == null
                          ? 'Tap on the map to select a location'
                          : 'Selected: ${logic.picked!.latitude.toStringAsFixed(6)}, '
                              '${logic.picked!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Floating confirm button at bottom
              if (logic.picked != null)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Location'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
