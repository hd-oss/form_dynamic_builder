import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/location_service.dart';

class MapPickerLogic extends ChangeNotifier {
  final Map<String, double>? initial;
  final bool autoZoom;

  LatLng? picked;
  late final MapController mapController;

  // Default center: Indonesia
  static const LatLng defaultCenter = LatLng(-2.5489, 118.0149);

  bool _isDisposed = false;

  MapPickerLogic({this.initial, this.autoZoom = false}) {
    mapController = MapController();
    if (initial != null) {
      picked = LatLng(initial!['lat']!, initial!['lng']!);
    }
  }

  void onMapTap(LatLng point) {
    picked = point;
    notifyListeners();
  }

  Future<void> goToCurrentLocation() async {
    final loc = await LocationService.detectCurrentLocation();
    if (_isDisposed) return;

    if (loc != null) {
      final point = LatLng(loc['lat']!, loc['lng']!);
      mapController.move(point, autoZoom ? 16 : 14);
      picked = point;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    mapController.dispose();
    super.dispose();
  }
}
