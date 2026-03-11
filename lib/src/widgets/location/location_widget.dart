import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../common/adaptive_button.dart';
import '../field_label.dart';
import 'location_logic.dart';
import 'map_picker_widget.dart';

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
  late final MapController _miniMapController;

  @override
  void initState() {
    super.initState();
    logic = LocationLogic(widget.component, widget.controller);
    _miniMapController = MapController();
  }

  @override
  void dispose() {
    logic.dispose();
    _miniMapController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ACTION HANDLERS
  // ==========================================================================

  Future<void> _openMapPicker() async {
    final current =
        logic.parseLocation(widget.controller.getValue(widget.component.key));

    final result = await Navigator.push<Map<String, double>?>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initial: current,
          autoZoom: widget.component.autoZoomLocation,
        ),
      ),
    );

    if (result == null || !mounted) return;

    logic.updateLocation(result);

    _miniMapController.move(
      LatLng(result['lat']!, result['lng']!),
      15,
    );
  }

  // ==========================================================================
  // COORDINATE INPUT (manual mode)
  // ==========================================================================

  Widget _buildManualInput() {
    return Column(
      children: [
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              enabled: !widget.component.disabled,
              onChanged: (_) => logic.syncControllerFromTextFields(),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
              controller: logic.lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              enabled: !widget.component.disabled,
              onChanged: (_) => logic.syncControllerFromTextFields(),
            )),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================================================
  // MINI MAP PREVIEW
  // ==========================================================================

  Widget _buildMiniMap(Map<String, double> loc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 160,
        child: FlutterMap(
            mapController: _miniMapController,
            options: MapOptions(
                initialCenter: LatLng(loc['lat']!, loc['lng']!),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                )),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.form_dynamic_builder',
              ),
              MarkerLayer(markers: [
                Marker(
                    point: LatLng(loc['lat']!, loc['lng']!),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 36,
                    )),
              ]),
            ]),
      ),
    );
  }

  // ==========================================================================
  // ACTION BUTTONS
  // ==========================================================================

  Widget _buildButtons(Map<String, double>? loc) {
    if (widget.component.disabled) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        alignment: widget.component.enableMapPicker
            ? WrapAlignment.spaceEvenly
            : WrapAlignment.start,
        children: [
          AdaptiveButton(
            onPressed: widget.component.disabled || logic.isLoading
                ? null
                : () => logic.detectLocation(),
            icon: logic.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 16),
            child: Text(logic.isLoading ? 'Detecting...' : 'Detect Location'),
          ),
          if (widget.component.enableMapPicker)
            AdaptiveButton(
              onPressed: widget.component.disabled ? null : _openMapPicker,
              icon: const Icon(Icons.map, size: 16),
              child: Text(loc == null ? 'Pick on Map' : 'Change on Map'),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (_, __) {
          final loc = logic.parseLocation(
            widget.controller.getValue(widget.component.key),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                ),
                child: _buildContent(loc),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(Map<String, double>? loc) {
    return Focus(
      focusNode: widget.controller.getFocusNode(widget.component.key),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.component.enableMapPicker)
            _buildManualInput()
          else if (loc != null) ...[
            Row(children: [
              const Icon(Icons.location_on, size: 20, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(logic.formatLocation(loc),
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              if (!widget.component.disabled)
                GestureDetector(
                    onTap: logic.clearLocation,
                    child: const Icon(Icons.close, size: 25)),
            ]),
            const SizedBox(height: 8),
          ],
          if (loc != null) ...[
            _buildMiniMap(loc),
            const SizedBox(height: 8),
          ],
          _buildButtons(loc),
        ],
      ),
    );
  }
}
