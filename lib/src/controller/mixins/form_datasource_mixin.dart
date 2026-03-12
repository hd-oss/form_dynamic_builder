import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/form_config.dart';
import '../../models/form_component.dart';
import '../../models/data_source.dart';
import '../../models/components/all_components.dart';
import '../../services/datasource_api_service.dart';
import '../../services/datasource_db_service.dart';
import '../../services/datasource_service.dart';

mixin FormDatasourceMixin on ChangeNotifier {
  // --- Expected Members ---
  FormConfig get config;
  dynamic getValue(String key);
  void updateValue(String key, dynamic value);
  List<FormComponent> getAllComponents();

  // --- State ---
  final Map<String, List<SelectOption>> _dynamicOptionsMap = {};
  final Map<String, bool> _isLoadingMap = {};
  final Map<String, String?> _errorMap = {};

  // Internal tracking
  final Map<String, Set<String>> _componentDependencies = {};
  final Map<String, Map<String, dynamic>> _lastDependentValues = {};
  bool _isFetchingSuppressed = false;

  /// Enable or disable reactive data source fetching.
  /// Useful to prevent side-effect fetches during submission or bulk updates.
  set isFetchingSuppressed(bool value) => _isFetchingSuppressed = value;
  bool get isFetchingSuppressed => _isFetchingSuppressed;

  /// Access dynamic options for a component.
  List<SelectOption> getDynamicOptions(String key) =>
      _dynamicOptionsMap[key] ?? [];

  /// Check if a component's dataSource is currently loading.
  bool isDataSourceLoading(String key) => _isLoadingMap[key] ?? false;

  /// Get the last error for a component's dataSource.
  String? getDataSourceError(String key) => _errorMap[key];

  /// Initialize all dataSources in the form.
  void initializeDataSources() {
    if (kDebugMode) print('FormDatasourceMixin: Initializing DataSources...');
    _componentDependencies.clear();
    _lastDependentValues.clear();

    final allComponents = getAllComponents();
    for (var component in allComponents) {
      final dataSource = _getDataSource(component);
      if (dataSource == null || !dataSource.isDynamic) continue;

      // Extract dependencies from URL or Query
      Set<String> deps = {};
      if (dataSource.isApi) {
        deps = DatasourceService.extractDependentKeys(dataSource.api!.url);
      } else if (dataSource.isDatabase) {
        deps =
            DatasourceService.extractDependentKeys(dataSource.database!.query);
      }

      if (deps.isNotEmpty) {
        if (kDebugMode) {
          print('FormDatasourceMixin: [${component.key}] depends on: $deps');
        }
        _componentDependencies[component.key] = deps;
        _snapshotDependencies(component.key, deps);
      } else {
        if (kDebugMode) {
          print('FormDatasourceMixin: [${component.key}] has no dependencies');
        }
      }

      // Initial fetch if all required dependencies are met
      if (_hasRequiredDeps(deps)) {
        if (kDebugMode) {
          print(
              'FormDatasourceMixin: [${component.key}] initial fetch triggered');
        }
        _fetchForComponent(component);
      } else {
        if (kDebugMode) {
          print(
              'FormDatasourceMixin: [${component.key}] initial fetch skipped (deps not met: $deps)');
        }
      }
    }

    // Listen to form changes to trigger re-fetches
    removeListener(_onDatasourceFormChanged); // Avoid duplicate listeners
    addListener(_onDatasourceFormChanged);
  }

  void _onDatasourceFormChanged() {
    if (_isFetchingSuppressed) return;
    for (var entry in _componentDependencies.entries) {
      final componentKey = entry.key;
      final deps = entry.value;

      bool changed = false;
      for (var depKey in deps) {
        final currentVal = getValue(depKey);
        if (currentVal != _lastDependentValues[componentKey]?[depKey]) {
          if (kDebugMode) {
            print(
                'FormDatasourceMixin: Dependency [$depKey] for [$componentKey] changed: ${_lastDependentValues[componentKey]?[depKey]} -> $currentVal');
          }
          changed = true;
          break;
        }
      }

      if (changed) {
        _snapshotDependencies(componentKey, deps);

        final component = _findComponentByKey(componentKey);
        if (component == null) continue;

        if (_hasRequiredDeps(deps)) {
          if (kDebugMode) {
            print(
                'FormDatasourceMixin: [$componentKey] requirements met, refetching...');
          }
          _fetchForComponent(component);
        } else {
          if (kDebugMode) {
            print(
                'FormDatasourceMixin: [$componentKey] requirements NOT met after change, clearing options/value');
          }
          // Clear if dependencies missing
          _clearComponentState(componentKey);
          notifyListeners();
        }
      }
    }
  }

  void _snapshotDependencies(String componentKey, Set<String> deps) {
    final snapshot = <String, dynamic>{};
    for (var depKey in deps) {
      snapshot[depKey] = getValue(depKey);
    }
    _lastDependentValues[componentKey] = snapshot;
  }

  bool _hasRequiredDeps(Set<String> deps) {
    if (deps.isEmpty) return true;
    for (var key in deps) {
      final val = getValue(key);
      if (val == null || val.toString().trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _fetchForComponent(FormComponent component) async {
    final dataSource = _getDataSource(component);
    if (dataSource == null) return;

    final key = component.key;
    if (kDebugMode) print('FormDatasourceMixin: Start fetch for [$key]');

    // Clear old data to prevent stale state during/after fetch
    _isLoadingMap[key] = true;
    _errorMap[key] = null;
    _clearComponentState(key);
    notifyListeners();

    try {
      if (kDebugMode) print('FormDatasourceMixin: Fetching for [$key]...');
      if (_isOptionComponent(component)) {
        List<SelectOption> options = [];
        if (dataSource.isApi) {
          options = await DatasourceApiService.fetchOptions(
            api: dataSource.api!,
            controller: this as dynamic,
          );
        } else if (dataSource.isDatabase) {
          options = await DatasourceDbService.fetchDatabaseOptions(
            database: dataSource.database!,
            controller: this as dynamic,
          );
        }
        if (kDebugMode) {
          print(
              'FormDatasourceMixin: [$key] fetched ${options.length} options');
        }
        _dynamicOptionsMap[key] = options;
      } else {
        // Default Value Mode (TextField, etc.)
        dynamic value;
        if (dataSource.isApi) {
          value = await DatasourceApiService.fetchDefaultValue(
            api: dataSource.api!,
            controller: this as dynamic,
          );
        } else if (dataSource.isDatabase) {
          value = await DatasourceDbService.fetchDatabaseDefaultValue(
            database: dataSource.database!,
            controller: this as dynamic,
          );
        }
        if (kDebugMode) {
          print('FormDatasourceMixin: [$key] fetched value: $value');
        }
        // Always update value (clears if null)
        updateValue(key, value);
      }
      _isLoadingMap[key] = false;
    } catch (e) {
      if (kDebugMode) print('FormDatasourceMixin: [$key] fetch error: $e');
      _isLoadingMap[key] = false;
      _errorMap[key] = e.toString();
      // Ensure state is cleared on error
      _clearComponentState(key);
    }
    notifyListeners();
  }

  void _clearComponentState(String key) {
    _dynamicOptionsMap.remove(key);
    updateValue(key, null);
  }

  DataSource? _getDataSource(FormComponent component) {
    if (component is SelectComponent) return component.dataSource;
    if (component is RadioComponent) return component.dataSource;
    if (component is SelectBoxesComponent) return component.dataSource;
    if (component is TagsComponent) return component.dataSource;
    if (component is TextFieldComponent) return component.dataSource;
    if (component is NumberComponent) return component.dataSource;
    return null;
  }

  bool _isOptionComponent(FormComponent component) {
    return component is SelectComponent ||
        component is RadioComponent ||
        component is SelectBoxesComponent ||
        component is TagsComponent;
  }

  FormComponent? _findComponentByKey(String key) {
    for (var component in getAllComponents()) {
      if (component.key == key) return component;
    }
    return null;
  }

  void disposeDatasourceMixin() {
    removeListener(_onDatasourceFormChanged);
  }
}
