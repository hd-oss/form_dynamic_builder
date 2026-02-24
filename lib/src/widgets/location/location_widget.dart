import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'location_logic.dart';

// ---------------------------------------------------------------------------
// DynamicLocation — form field widget
// ---------------------------------------------------------------------------

class DynamicLocation extends StatefulWidget {
  final LocationComponent component;
  final FormController controller;

  const DynamicLocation({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicLocation> createState() => _DynamicLocationState();
}

class _DynamicLocationState extends State<DynamicLocation> {
  late final LocationLogic logic;

  @override
  void initState() {
    super.initState();
    logic = LocationLogic(widget.component, widget.controller);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  Future<void> _handleDetectLocation(BuildContext context) async {
    final success = await logic.detectLocation();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get location. Check permissions.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final current =
        logic.parseLocation(widget.controller.getValue(widget.component.key));
    final result = await Navigator.push<Map<String, double>?>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(initial: current),
      ),
    );
    if (result != null && context.mounted) {
      logic.updateLocation(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
          final loc = logic
              .parseLocation(widget.controller.getValue(widget.component.key));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                ),
                child: Focus(
                  focusNode:
                      widget.controller.getFocusNode(widget.component.key),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Coordinate display or Manual Input ──────────────
                      if (!widget.component.enableMapPicker) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: logic.latController,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                enabled: !widget.component.disabled,
                                onChanged: (_) =>
                                    logic.syncControllerFromTextFields(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: logic.lngController,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                enabled: !widget.component.disabled,
                                onChanged: (_) =>
                                    logic.syncControllerFromTextFields(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else if (loc != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                logic.formatLocation(loc),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            if (!widget.component.disabled)
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Clear location',
                                onPressed: logic.clearLocation,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Mini static map preview when a location is set
                      if (loc != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 160,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(loc['lat']!, loc['lng']!),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none, // read-only
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.form_dynamic_builder',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(loc['lat']!, loc['lng']!),
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // ── Action buttons ──────────────────────────────────
                      if (!widget.component.disabled) ...[
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: logic.isLoading
                                  ? null
                                  : () => _handleDetectLocation(context),
                              icon: logic.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location, size: 16),
                              label: Text(logic.isLoading
                                  ? 'Detecting...'
                                  : 'Detect Location'),
                            ),
                            if (widget.component.enableMapPicker)
                              OutlinedButton.icon(
                                onPressed: () => _openMapPicker(context),
                                icon: const Icon(Icons.map, size: 16),
                                label: Text(loc == null
                                    ? 'Pick on Map'
                                    : 'Change on Map'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MapPickerScreen — full-screen interactive map
// ---------------------------------------------------------------------------

class _MapPickerScreen extends StatefulWidget {
  final Map<String, double>? initial;
  const _MapPickerScreen({this.initial});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  LatLng? _picked;
  late final MapController _mapController;

  // Default center: Indonesia
  static const LatLng _defaultCenter = LatLng(-2.5489, 118.0149);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initial != null) {
      _picked = LatLng(widget.initial!['lat']!, widget.initial!['lng']!);
    }
  }

  void _onTap(TapPosition _, LatLng point) {
    setState(() => _picked = point);
  }

  void _confirm() {
    if (_picked == null) return;
    Navigator.pop(context, {
      'lat': _picked!.latitude,
      'lng': _picked!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ??
        widget.initial.let((i) => LatLng(i['lat']!, i['lng']!)) ??
        _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          if (_picked != null)
            TextButton(
              onPressed: _confirm,
              child:
                  const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.form_dynamic_builder',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _picked == null
                      ? 'Tap on the map to select a location'
                      : 'Selected: ${_picked!.latitude.toStringAsFixed(6)}, '
                          '${_picked!.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Floating confirm button at bottom
          if (_picked != null)
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
  }
}

extension _NullableExt<T> on T? {
  R? let<R>(R Function(T) f) => this != null ? f(this as T) : null;
}
