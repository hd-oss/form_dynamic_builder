import 'package:flutter/foundation.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_option.dart';
import '../../models/data_source.dart';
import '../../services/data_source_service.dart';

/// A mixin for Logic classes that need to load options from a dataSource API.
///
/// ## Fetch timing:
/// 1. **Initial fetch** — Called once on `initDataSource()`, which should be
///    invoked from the logic class constructor. Because Flutter re-creates
///    widgets when a conditional component becomes visible, this also handles
///    the visibility-triggered re-fetch automatically.
///
/// 2. **Dependency-based re-fetch** — If the URL contains `{{componentKey}}`
///    placeholders that reference other fields, this mixin listens to form
///    state changes and re-fetches ONLY when those specific dependent values
///    have actually changed. This prevents unnecessary network requests on
///    every keystroke across the form.
mixin DataSourceMixin on ChangeNotifier {
  List<SelectOption> dynamicOptions = [];
  bool isLoadingOptions = false;
  String? dataSourceError;

  bool _isDataSourceDisposed = false;
  FormController? _dsController;
  DataSourceApi? _dsApi;
  Set<String> _dependentKeys = {};

  /// Tracks last-known values of dependent keys to detect real changes.
  final Map<String, dynamic> _lastDependentValues = {};

  /// Call this in your logic constructor to initialize data loading.
  void initDataSource({
    required DataSource? dataSource,
    required FormController controller,
  }) {
    if (dataSource == null || !dataSource.isApi) return;

    _dsController = controller;
    _dsApi = dataSource.api!;
    _dependentKeys = DataSourceService.extractDependentKeys(_dsApi!.url);

    // Snapshot initial dependent values to detect real changes later.
    _snapshotDependentValues(controller);

    // Listen to form changes only if URL has dependencies.
    if (_dependentKeys.isNotEmpty) {
      controller.addListener(_onFormChanged);
    }

    // Initial fetch.
    _fetchOptions(controller);
  }

  void _onFormChanged() {
    if (_isDataSourceDisposed || _dsController == null || _dsApi == null) {
      return;
    }

    // Check if any of the dependent values have ACTUALLY changed.
    bool hasChanged = false;
    for (final key in _dependentKeys) {
      final currentValue = _dsController!.getValue(key);
      if (currentValue != _lastDependentValues[key]) {
        hasChanged = true;
        break;
      }
    }

    if (!hasChanged) return;

    // Update snapshot and re-fetch.
    _snapshotDependentValues(_dsController!);
    _fetchOptions(_dsController!);
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

  void disposeDataSource() {
    _isDataSourceDisposed = true;
    if (_dependentKeys.isNotEmpty && _dsController != null) {
      _dsController!.removeListener(_onFormChanged);
    }
  }
}
