import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../services/location_service.dart';

class LocationLogic extends ChangeNotifier {
  final LocationComponent component;
  final FormController formController;

  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();

  Map<String, double>? _lastKnownControllerValue;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  LocationLogic(this.component, this.formController) {
    _syncTextFieldsFromController();
    formController.addListener(_syncTextFieldsFromController);
  }

  @override
  void dispose() {
    formController.removeListener(_syncTextFieldsFromController);
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  Map<String, double>? parseLocation(dynamic value) {
    if (value is Map) {
      final lat = (value['lat'] as num?)?.toDouble();
      final lng = (value['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) return {'lat': lat, 'lng': lng};
    }
    return null;
  }

  String formatLocation(Map<String, double> loc) {
    return '${loc['lat']!.toStringAsFixed(6)}, ${loc['lng']!.toStringAsFixed(6)}';
  }

  void _syncTextFieldsFromController() {
    final loc = parseLocation(formController.getValue(component.key));

    bool changed = false;
    if (loc == null && _lastKnownControllerValue != null) {
      changed = true;
    } else if (loc != null && _lastKnownControllerValue == null) {
      changed = true;
    } else if (loc != null && _lastKnownControllerValue != null) {
      if (loc['lat'] != _lastKnownControllerValue!['lat'] ||
          loc['lng'] != _lastKnownControllerValue!['lng']) {
        changed = true;
      }
    }

    if (changed ||
        (_lastKnownControllerValue == null &&
            loc == null &&
            (latController.text.isNotEmpty || lngController.text.isNotEmpty))) {
      _lastKnownControllerValue = loc;
      if (loc != null) {
        latController.text = loc['lat']!.toStringAsFixed(6);
        lngController.text = loc['lng']!.toStringAsFixed(6);
      } else {
        latController.text = '';
        lngController.text = '';
      }
      notifyListeners();
    }
  }

  void syncControllerFromTextFields() {
    final lat = double.tryParse(latController.text);
    final lng = double.tryParse(lngController.text);
    if (lat != null && lng != null) {
      final newLoc = {'lat': lat, 'lng': lng};
      _lastKnownControllerValue = newLoc;
      formController.updateValue(component.key, newLoc);
    } else if (latController.text.isEmpty && lngController.text.isEmpty) {
      _lastKnownControllerValue = null;
      formController.updateValue(component.key, null);
    }
  }

  Future<bool> detectLocation() async {
    _isLoading = true;
    notifyListeners();

    final loc = await LocationService.detectCurrentLocation();

    _isLoading = false;
    notifyListeners();

    if (loc != null) {
      formController.updateValue(component.key, loc);
      return true;
    }
    return false;
  }

  void updateLocation(Map<String, double>? loc) {
    formController.updateValue(component.key, loc);
  }

  void clearLocation() {
    formController.updateValue(component.key, null);
  }
}
