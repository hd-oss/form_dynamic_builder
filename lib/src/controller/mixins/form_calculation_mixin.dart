import 'package:flutter/material.dart';
import '../../models/form_component.dart';
import '../../models/form_config.dart';
import '../../models/components/all_components.dart';

mixin FormCalculationMixin on ChangeNotifier {
  // Expected from other mixins
  Map<String, dynamic> get values;
  FormConfig get config;
  void updateValue(String key, dynamic value);

  bool _isRecalculating = false;

  /// Iterates through all components and recalculates those with `calculation`.
  void recalculateValues() {
    if (_isRecalculating) return;
    _isRecalculating = true;

    try {
      final allComponents = _getAllComponentsWithCalculation();
      bool anyChanged = false;

      for (var component in allComponents) {
        final formula = _getCalculateValue(component);
        if (formula == null || formula.isEmpty) continue;

        final newValue = _evaluateFormula(formula);
        final currentValue = values[component.key];

        if (newValue != null &&
            newValue.toString() != currentValue?.toString()) {
          updateValue(component.key, newValue);
          anyChanged = true;
        }
      }

      if (anyChanged) {
        // notifyListeners() is already called by updateValue
      }
    } finally {
      _isRecalculating = false;
    }
  }

  List<FormComponent> _getAllComponentsWithCalculation() {
    final comps = <FormComponent>[];

    void collect(List<FormComponent> list) {
      for (var c in list) {
        if (_getCalculateValue(c) != null) {
          comps.add(c);
        }
        if (c is PanelComponent) {
          collect(c.components);
        }
      }
    }

    collect(config.components);
    for (var s in config.steps) {
      collect(s.components);
    }
    return comps;
  }

  String? _getCalculateValue(FormComponent c) {
    if (c is TextFieldComponent) return c.calculation;
    if (c is NumberComponent) return c.calculation;
    if (c is SelectComponent) return c.calculation;
    return null;
  }

  dynamic _evaluateFormula(String formula) {
    // 1. Replace {{ key }} with values
    final regex = RegExp(r'\{\{\s*([a-zA-Z0-9_-]+)\s*\}\}');
    String evaluatedFormula = formula.replaceAllMapped(regex, (match) {
      final key = match.group(1)!;
      final val = values[key];
      return val?.toString() ?? '0';
    });

    // 2. Simple Arithmetic Evaluator
    // Note: In a real world app, we might use a package like 'expressions'
    // For now, we handle basic + - * / for the user's requirement.
    try {
      return _simpleMathEval(evaluatedFormula);
    } catch (e) {
      debugPrint('Error evaluating formula "$formula": $e');
      return null;
    }
  }

  /// Extremely simple math evaluator for basic expressions like "10 + 20 * 5"
  /// Handles numbers and + - * /
  double? _simpleMathEval(String expression) {
    // Clean up
    final clean = expression.replaceAll(' ', '');

    // We'll use a very basic approach:
    // This is a placeholder for a proper expression parser.
    // For now, let's at least handle simple binary operations or sum of parts.

    // If it's just a number, return it
    final soloNum = double.tryParse(clean);
    if (soloNum != null) return soloNum;

    // Very basic support for + and * without full precedence for now
    // (Improved simplified version)

    // Split by + and - first (lower precedence)
    // This is still very basic but handles the user's example "a + b"
    if (clean.contains('+')) {
      final parts = clean.split('+');
      double total = 0;
      for (var p in parts) {
        total += _simpleMathEval(p) ?? 0;
      }
      return total;
    }

    if (clean.contains('-')) {
      final parts = clean.split('-');
      double? total;
      for (var p in parts) {
        final val = _simpleMathEval(p) ?? 0;
        if (total == null) {
          total = val;
        } else {
          total -= val;
        }
      }
      return total;
    }

    if (clean.contains('*')) {
      final parts = clean.split('*');
      double total = 1;
      for (var p in parts) {
        total *= _simpleMathEval(p) ?? 1;
      }
      return total;
    }

    if (clean.contains('/')) {
      final parts = clean.split('/');
      double? total;
      for (var p in parts) {
        final val = _simpleMathEval(p) ?? 1;
        if (total == null) {
          total = val;
        } else {
          if (val == 0) return 0;
          total /= val;
        }
      }
      return total;
    }

    return double.tryParse(clean);
  }
}
