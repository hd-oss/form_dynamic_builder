import 'package:flutter/foundation.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_option.dart';
import '../../models/data_source.dart';
import '../datasource_service.dart';

enum DataSourceState {
  initial,
  loading,
  loaded,
  error,
}

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
  // --- Unified DataSource State ---
  DataSourceState dsState = DataSourceState.initial;
  String? dsError;

  // --- Options mode specific ---
  List<SelectOption> dynamicOptions = [];

  bool _isDataSourceDisposed = false;
  FormController? _dsController;
  DataSourceApi? _dsApi;
  DataSourceDatabase? _dsDatabase;
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
    if (dataSource == null || (!dataSource.isApi && !dataSource.isDatabase)) {
      return;
    }

    _isDefaultValueMode = false;
    _dsController = controller;

    if (dataSource.isApi) {
      _dsApi = dataSource.api!;
      _dependentKeys = DatasourceService.extractDependentKeys(_dsApi!.url);
    } else if (dataSource.isDatabase) {
      _dsDatabase = dataSource.database!;
      _dependentKeys =
          DatasourceService.extractDependentKeys(_dsDatabase!.query);
    }

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
    if (dataSource == null || (!dataSource.isApi && !dataSource.isDatabase)) {
      return;
    }

    _isDefaultValueMode = true;
    _dsController = controller;
    _dsComponentKey = componentKey;

    if (dataSource.isApi) {
      _dsApi = dataSource.api!;
      _dependentKeys = DatasourceService.extractDependentKeys(_dsApi!.url);
    } else if (dataSource.isDatabase) {
      _dsDatabase = dataSource.database!;
      _dependentKeys = DatasourceService.extractDependentKeys(
        _dsDatabase!.query,
      );
    }

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
    if (_isDataSourceDisposed ||
        _dsController == null ||
        (_dsApi == null && _dsDatabase == null)) {
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
    if (_isDataSourceDisposed || (_dsApi == null && _dsDatabase == null)) {
      return;
    }

    dsState = DataSourceState.loading;
    dsError = null;
    notifyListeners();

    try {
      List<SelectOption> options = [];
      if (_dsApi != null) {
        options = await DatasourceService.fetchOptions(
          api: _dsApi!,
          controller: controller,
        );
      } else if (_dsDatabase != null) {
        options = await DatasourceService.fetchDatabaseOptions(
          database: _dsDatabase!,
          controller: controller,
        );
      }

      if (_isDataSourceDisposed) return;

      dynamicOptions = options;
      dsState = DataSourceState.loaded;
    } catch (e) {
      if (_isDataSourceDisposed) return;
      dsError = e.toString();
      dsState = DataSourceState.error;
    }

    notifyListeners();
  }

  Future<void> _fetchDefaultValue(FormController controller) async {
    if (_isDataSourceDisposed ||
        (_dsApi == null && _dsDatabase == null) ||
        _dsComponentKey == null) {
      return;
    }

    dsState = DataSourceState.loading;
    dsError = null;
    notifyListeners();

    try {
      dynamic value;
      if (_dsApi != null) {
        value = await DatasourceService.fetchDefaultValue(
          api: _dsApi!,
          controller: controller,
        );
      } else if (_dsDatabase != null) {
        value = await DatasourceService.fetchDatabaseDefaultValue(
          database: _dsDatabase!,
          controller: controller,
        );
      }

      if (_isDataSourceDisposed) return;

      if (value != null) {
        controller.updateValue(_dsComponentKey!, value);
      }
      dsState = DataSourceState.loaded;
    } catch (e) {
      if (_isDataSourceDisposed) return;
      dsError = e.toString();
      dsState = DataSourceState.error;
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
