import 'package:flutter/material.dart';

import '../models/form_config.dart';
import '../models/form_component.dart';
import '../models/file_data.dart';
import '../models/upload_config.dart';
import '../models/components/all_components.dart';
import '../services/upload_service.dart';
import 'mixins/form_navigation_mixin.dart';
import 'mixins/form_state_mixin.dart';
import 'mixins/form_validation_mixin.dart';
import 'mixins/form_visibility_mixin.dart';
import 'mixins/form_calculation_mixin.dart';
import 'mixins/form_datasource_mixin.dart';

class FormController extends ChangeNotifier
    with
        FormStateMixin,
        FormVisibilityMixin,
        FormValidationMixin,
        FormNavigationMixin,
        FormCalculationMixin,
        FormDatasourceMixin {
  @override
  final FormConfig config;

  final Map<String, dynamic> _dsForm = {};

  /// Access dynamic data provided by the application.
  Map<String, dynamic> get dsForm => _dsForm;

  /// Incremented on every [reset] call.
  /// Used by the form builder to force-rebuild all component widgets.
  int _resetGeneration = 0;
  int get resetGeneration => _resetGeneration;

  FormController({
    required this.config,
  }) {
    if (config.dsForm != null) {
      _dsForm.addAll(config.dsForm!);
    }
    initializeValues();
    // Prime the API cache for conditional logic
    refreshConditionalApiValues().then((_) {
      initializeDataSources();
      notifyListeners();
    });
  }

  /// Updates manually provided dynamic data.
  void updateDsForm(Map<String, dynamic> data) {
    _dsForm.addAll(data);
    notifyListeners();
  }

  @override
  void loadDraft(Map<String, dynamic> draftData) {
    isFetchingSuppressed = true;
    try {
      super.loadDraft(draftData);
    } finally {
      isFetchingSuppressed = false;
      // After loading everything, trigger one re-fetch cycle to ensure
      // all dependencies are correctly evaluated for the loaded state.
      initializeDataSources();
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    recalculateValues();
  }

  /// Clears all values, errors, focus nodes, and resets navigation.
  void reset() {
    _resetGeneration++;
    clearFocusNodes(); // Dispose stale FocusNodes so inputs work again
    initializeValues();
    errors.clear();
    resetNavigation();
    notifyListeners();
  }

  /// Orchestrates deferred file uploads (onSubmit) and returns the final resultMap.
  ///
  /// returns null if validation fails or an upload error occurs.
  Future<Map<String, dynamic>?> submitAsync({
    void Function(int current, int total)? onProgress,
  }) async {
    isFetchingSuppressed = true;
    try {
      if (!validate()) return null;

      final allComponents = getAllComponents();
      final List<MapEntry<String, FormComponent>> queue = [];

      // 1. Identify components that have local files needing upload
      for (final component in allComponents) {
        final value = values[component.key];
        if (value == null) continue;

        bool hasLocalFiles = false;
        if (value is FileData) {
          hasLocalFiles = value.status == 'local' && value.uploadedUrl != null;
        } else if (value is List && value.every((e) => e is FileData)) {
          hasLocalFiles = value.any((e) => (e as FileData).status == 'local');
        }

        if (hasLocalFiles) {
          queue.add(MapEntry(component.key, component));
        }
      }

      if (queue.isEmpty) return resultMap;

      // 2. Process the queue
      int completed = 0;
      onProgress?.call(0, queue.length);

      for (final entry in queue) {
        final key = entry.key;
        final component = entry.value;
        final value = values[key];

        String? uploadUrl;
        String uploadType = 'callback';
        OtherUploadConfig? uploadConfig;

        if (component is FileUploadComponent) {
          uploadUrl = component.uploadUrl;
          uploadType = component.uploadType;
          uploadConfig = component.uploadConfig;
        } else if (component is CameraComponent) {
          uploadUrl = component.uploadUrl;
          uploadType = component.uploadType;
          uploadConfig = component.uploadConfig;
        } else if (component is SignatureComponent) {
          uploadUrl = component.uploadUrl;
          uploadType = component.uploadType;
          uploadConfig = component.uploadConfig;
        }

        if (uploadUrl == null || uploadUrl.isEmpty) continue;

        final List<String> pathsToUpload = [];
        if (value is FileData) {
          if (value.status == 'local' && value.localPath != null) {
            pathsToUpload.add(value.localPath!);
          }
        } else if (value is List) {
          for (var f in value) {
            if ((f as FileData).status == 'local' && f.localPath != null) {
              pathsToUpload.add(f.localPath!);
            }
          }
        }

        if (pathsToUpload.isEmpty) {
          completed++;
          onProgress?.call(completed, queue.length);
          continue;
        }

        final result = await UploadService.processAndUpload(
          localPaths: pathsToUpload,
          formController: this,
          uploadUrl: uploadUrl,
          uploadTiming: 'immediate', // Force upload now
          uploadType: uploadType,
          uploadConfig: uploadConfig,
        );

        if (result.isSuccess && result.wasUploaded) {
          if (value is FileData) {
            final updated = value.copyWith(
              status: 'success',
              uploadResponse: result.values.first,
            );
            updateValue(key, updated);
          } else if (value is List) {
            final updatedList = List<FileData>.from(value);
            for (int i = 0; i < updatedList.length; i++) {
              if (updatedList[i].status == 'local') {
                int indexInBatch =
                    pathsToUpload.indexOf(updatedList[i].localPath!);
                if (indexInBatch != -1 && indexInBatch < result.values.length) {
                  updatedList[i] = updatedList[i].copyWith(
                    status: 'success',
                    uploadResponse: result.values[indexInBatch],
                  );
                }
              }
            }
            updateValue(key, updatedList);
          }
        } else {
          errors[key] = result.errorMessage ?? 'Upload failed';
          notifyListeners();
          return null;
        }

        completed++;
        onProgress?.call(completed, queue.length);
      }

      return resultMap;
    } finally {
      isFetchingSuppressed = false;
    }
  }

  @override
  void dispose() {
    disposeValidationResources(); // ValidationMixin
    disposeDatasourceMixin(); // DatasourceMixin
    super.dispose();
  }
}
