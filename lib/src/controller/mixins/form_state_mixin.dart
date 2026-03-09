import 'package:flutter/material.dart';

import '../../models/file_data.dart';
import '../../models/form_component.dart';
import '../../models/form_config.dart';
import '../../models/components/file_upload_component.dart';
import '../../utils/form_constants.dart';

mixin FormStateMixin on ChangeNotifier {
  // Expected Members from FormController
  FormConfig get config;
  Map<String, String> get errors;

  final Map<String, dynamic> _values = {};
  Map<String, dynamic> get values => _values;

  /// Stores display text (labels) for components that have id/value pairs (e.g. select from API).
  final Map<String, String> _displayTexts = {};
  Map<String, String> get displayTexts => _displayTexts;

  /// Returns a snapshot of the current form state optimized for local storage/drafting.
  /// This captures full [FileData] objects (including local paths and status)
  /// so that the form can be fully restored exactly as it was.
  Map<String, dynamic> get draftMap {
    final draft = <String, dynamic>{};
    _values.forEach((key, value) {
      dynamic serializedValue = value;
      if (value is FileData) {
        serializedValue = value.toJson();
      } else if (value is List<FileData>) {
        serializedValue = value.map((e) => e.toJson()).toList();
      }

      draft[key] = {
        'answerText': _displayTexts[key] ?? '',
        'answerValue': serializedValue,
      };
    });
    return draft;
  }

  void initializeValues() {
    _values.clear();
    _displayTexts.clear();
    final allComponents = getAllComponents();

    for (var component in allComponents) {
      if (component.type == FormConstants.typeButton) continue;
      if (component.defaultValue != null) {
        _values[component.key] = component.defaultValue;
      }
    }
  }

  List<FormComponent> getAllComponents() {
    final allComponents = [...config.components];
    for (var step in config.steps) {
      allComponents.addAll(step.components);
    }
    return allComponents;
  }

  dynamic getValue(String key) {
    return _values[key];
  }

  void updateValue(String key, dynamic value) {
    final component = findComponent(key);
    var processedValue = value;

    if (component != null && value is String) {
      if (component.type == FormConstants.typeNumber ||
          component.type == FormConstants.typeCurrency) {
        processedValue = num.tryParse(value) ?? value;
      } else if (component.textTransform == FormConstants.transformUppercase) {
        processedValue = value.toUpperCase();
      } else if (component.textTransform == FormConstants.transformLowercase) {
        processedValue = value.toLowerCase();
      }
    }

    _values[key] = processedValue;
    _displayTexts.remove(
        key); // clear stale display text when value updated without label
    // Clear error when user types
    if (errors.containsKey(key)) {
      errors.remove(key);
    }
    notifyListeners();
  }

  /// Updates a value along with its human-readable display text.
  /// Used by select/radio/tags widgets that have id+label pairs.
  void updateValueWithLabel(String key, dynamic value, String displayText) {
    updateValue(key, value);
    _displayTexts[key] = displayText;
  }

  /// Loads previously saved draft data into the form state.
  /// Handles both the full state from `draftMap` and the submission format from `resultMap`.
  void loadDraft(Map<String, dynamic> draftData) {
    draftData.forEach((key, value) {
      final component = findComponent(key);
      if (component == null) return;

      if (value is Map<String, dynamic>) {
        final answerFile = value['answerFile'];
        var answerVal = value['answerValue'];
        final answerText = value['answerText'];

        // Hydrate FileData for upload components
        if (component.type == FormConstants.typeFile ||
            component.type == FormConstants.typeCamera ||
            component.type == FormConstants.typeSignature) {
          // Priority 1: Check answerFile (Submission format)
          if (answerFile is List && answerFile.isNotEmpty) {
            final paths = answerText?.toString().split(', ') ?? [];
            final resList = <FileData>[];
            for (int i = 0; i < answerFile.length; i++) {
              final response = answerFile[i];
              // If it's already a FileData JSON (from draftMap), use it directly
              if (response is Map<String, dynamic> &&
                  response.containsKey('status')) {
                resList.add(FileData.fromJson(response));
              } else {
                // Otherwise reconstruct from response (localPath might be missing if from resultMap)
                final path = i < paths.length ? paths[i] : '';
                resList.add(FileData.fromUpload(
                  localPath: path,
                  uploadedUrl: response is String ? response : null,
                  uploadResponse: response is Map ? response : null,
                ));
              }
            }
            final bool isMultiple =
                component is FileUploadComponent && component.multiple;
            answerVal = isMultiple ? resList : resList.first;
          }
          // Priority 2: Check answerValue (Draft format or old resultMap)
          else if (answerVal != null) {
            if (answerVal is List) {
              answerVal = answerVal.map((e) {
                if (e is Map<String, dynamic> && e.containsKey('status')) {
                  return FileData.fromJson(e);
                }
                return e;
              }).toList();
            } else if (answerVal is Map<String, dynamic> &&
                answerVal.containsKey('status')) {
              answerVal = FileData.fromJson(answerVal);
            } else if (answerVal != null ||
                (answerText != null && answerText.toString().isNotEmpty)) {
              // Backward compatibility for the brief localPath-as-answerText phase
              answerVal = FileData.fromUpload(
                localPath: answerText?.toString() ?? '',
                uploadedUrl: answerVal is String ? answerVal : null,
                uploadResponse: answerVal is Map ? answerVal : null,
              );
            }
          }
        }

        if (answerText != null &&
            answerText.toString().isNotEmpty &&
            !(component.type == FormConstants.typeFile ||
                component.type == FormConstants.typeCamera ||
                component.type == FormConstants.typeSignature)) {
          updateValueWithLabel(key, answerVal, answerText.toString());
        } else {
          updateValue(key, answerVal);
        }
      } else {
        // Fallback for primitive/flat map injection
        updateValue(key, value);
      }
    });
  }

  FormComponent? findComponent(String key) {
    for (var component in getAllComponents()) {
      if (component.key == key) return component;
    }
    return null;
  }
}
