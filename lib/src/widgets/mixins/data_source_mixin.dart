import 'package:flutter/foundation.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_option.dart';
import '../../models/data_source.dart';
import '../../services/data_source_service.dart';

/// A mixin for Logic classes that need to load data from a dataSource API.
///
/// Supports two modes:
/// - **Options mode** (`initDataSource`): fetches a `List<SelectOption>` for
///   option-based components (Select, Radio, SelectBoxes).
/// - **Default value mode** (`initDefaultValue`): fetches a single value and
///   sets it on the form controller for all other components (TextField, etc.).
///
/// ## Fetch timing:
/// 1. **Initial fetch** — On init. Flutter re-creates widgets when a conditional
///    component becomes visible, so this also handles visibility-triggered
///    re-fetch automatically.
/// 2. **Dependency-based re-fetch** — Only when `{{componentKey}}` values
///    actually change (not on every form event).
mixin DataSourceMixin on ChangeNotifier {
  // --- Options mode state ---
  List<SelectOption> dynamicOptions = [];
  bool isLoadingOptions = false;
  String? dataSourceError;

  // --- Default value mode state ---
  bool isLoadingDefaultValue = false;
  String? defaultValueError;

  bool _isDataSourceDisposed = false;
  FormController? _dsController;
  DataSourceApi? _dsApi;
  String? _dsComponentKey; // used in default value mode
  Set<String> _dependentKeys = {};
  bool _isDefaultValueMode = false;

  /// Tracks last-known values of dependent keys to detect real changes.
  final Map<String, dynamic> _lastDependentValues = {};

  // ---------------------------------------------------------------------------
  // Options mode (Select, Radio, SelectBoxes)
  // ---------------------------------------------------------------------------

  /// Call this in your logic constructor to initialize **options** loading.
  void initDataSource({
    required DataSource? dataSource,
    required FormController controller,
  }) {
    if (dataSource == null || !dataSource.isApi) return;

    _isDefaultValueMode = false;
    _dsController = controller;
    _dsApi = dataSource.api!;
    _dependentKeys = DataSourceService.extractDependentKeys(_dsApi!.url);

    _snapshotDependentValues(controller);

    if (_dependentKeys.isNotEmpty) {
      controller.addListener(_onFormChanged);
    }

    if (_hasAllRequiredDependencies(controller)) {
      _fetchOptions(controller);
    }
  }

  // ---------------------------------------------------------------------------
  // Default value mode (all other components)
  // ---------------------------------------------------------------------------

  /// Call this in your logic constructor to initialize **default value** loading.
  ///
  /// Fetches a single value from the API using `valuePath` and applies it
  /// to the form via `formController.updateValue(componentKey, value)`.
  /// Only fetches if the field currently has no value (does not overwrite).
  void initDefaultValue({
    required DataSource? dataSource,
    required FormController controller,
    required String componentKey,
  }) {
    if (dataSource == null || !dataSource.isApi) return;

    _isDefaultValueMode = true;
    _dsController = controller;
    _dsApi = dataSource.api!;
    _dsComponentKey = componentKey;
    _dependentKeys = DataSourceService.extractDependentKeys(_dsApi!.url);

    _snapshotDependentValues(controller);

    if (_dependentKeys.isNotEmpty) {
      controller.addListener(_onFormChanged);
    }

    if (_hasAllRequiredDependencies(controller)) {
      _fetchDefaultValue(controller);
    }
  }

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------

  bool _hasAllRequiredDependencies(FormController controller) {
    if (_dependentKeys.isEmpty) return true;

    for (final key in _dependentKeys) {
      final val = controller.getValue(key);
      if (val == null || val.toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _onFormChanged() {
    if (_isDataSourceDisposed || _dsController == null || _dsApi == null) {
      return;
    }

    bool hasChanged = false;
    for (final key in _dependentKeys) {
      final currentValue = _dsController!.getValue(key);
      if (currentValue != _lastDependentValues[key]) {
        hasChanged = true;
        break;
      }
    }

    if (!hasChanged) return;

    _snapshotDependentValues(_dsController!);

    if (!_hasAllRequiredDependencies(_dsController!)) {
      // If dependencies are no longer met, clear data
      if (_isDefaultValueMode) {
        if (_dsComponentKey != null) {
          _dsController!.updateValue(_dsComponentKey!, null);
        }
      } else {
        dynamicOptions = [];
        notifyListeners();
      }
      return;
    }

    if (_isDefaultValueMode) {
      _fetchDefaultValue(_dsController!);
    } else {
      _fetchOptions(_dsController!);
    }
  }

  void _snapshotDependentValues(FormController controller) {
    for (final key in _dependentKeys) {
      _lastDependentValues[key] = controller.getValue(key);
    }
  }

  Future<void> _fetchOptions(FormController controller) async {
    if (_isDataSourceDisposed || _dsApi == null) return;

    isLoadingOptions = true;
    dataSourceError = null;
    notifyListeners();

    try {
      final options = await DataSourceService.fetchOptions(
        api: _dsApi!,
        controller: controller,
      );

      if (_isDataSourceDisposed) return;

      dynamicOptions = options;
      isLoadingOptions = false;
    } catch (e) {
      if (_isDataSourceDisposed) return;
      dataSourceError = e.toString();
      isLoadingOptions = false;
    }

    notifyListeners();
  }

  Future<void> _fetchDefaultValue(FormController controller) async {
    if (_isDataSourceDisposed || _dsApi == null || _dsComponentKey == null) {
      return;
    }

    isLoadingDefaultValue = true;
    defaultValueError = null;
    notifyListeners();

    try {
      final value = await DataSourceService.fetchDefaultValue(
        api: _dsApi!,
        controller: controller,
      );

      if (_isDataSourceDisposed) return;

      if (value != null) {
        controller.updateValue(_dsComponentKey!, value);
      }
      isLoadingDefaultValue = false;
    } catch (e) {
      if (_isDataSourceDisposed) return;
      defaultValueError = e.toString();
      isLoadingDefaultValue = false;
    }

    notifyListeners();
  }

  void disposeDataSource() {
    _isDataSourceDisposed = true;
    if (_dependentKeys.isNotEmpty && _dsController != null) {
      _dsController!.removeListener(_onFormChanged);
    }
  }
}
