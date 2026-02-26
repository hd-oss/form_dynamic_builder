import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/form_component.dart';
import '../../utils/form_constants.dart';
import '../../services/mixins/data_source_mixin.dart';

class TextFieldLogic extends ChangeNotifier with DataSourceMixin {
  final FormComponent component;
  final FormController formController;
  final bool initialObscureText;

  late bool obscureText;
  MaskTextInputFormatter? maskFormatter;
  TextInputFormatter? currencyFormatter;
  late TextEditingController textController;

  TextFieldLogic({
    required this.component,
    required this.formController,
    this.initialObscureText = false,
  }) {
    obscureText = initialObscureText;

    if (component.inputMask.isNotEmpty) {
      maskFormatter = MaskTextInputFormatter(
        mask: component.inputMask,
        filter: {
          FormConstants.maskDigit: RegExp(r'[0-9]'),
          FormConstants.maskAlpha: RegExp(r'[a-zA-Z]'),
          FormConstants.maskAlphaNum: RegExp(r'[a-zA-Z0-9]'),
        },
        type: MaskAutoCompletionType.lazy,
      );
    }

    if (isCurrencyField()) {
      currencyFormatter = CurrencyInputFormatter();
    }

    final currentValue =
        formController.getValue(component.key)?.toString() ?? '';

    if (maskFormatter != null && currentValue.isNotEmpty) {
      maskFormatter!.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: currentValue),
      );
      textController =
          TextEditingController(text: maskFormatter!.getMaskedText());
    } else if (currencyFormatter != null && currentValue.isNotEmpty) {
      final formatted = currencyFormatter!.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: currentValue),
      );
      textController = TextEditingController(text: formatted.text);
    } else {
      textController = TextEditingController(text: currentValue);
    }

    formController.addListener(_onFormControllerChanged);

    initDefaultValue(
      dataSource: component.dataSource,
      controller: formController,
      componentKey: component.key,
    );
  }

  void _onFormControllerChanged() {
    final newValue = formController.getValue(component.key)?.toString() ?? '';

    if (maskFormatter != null && newValue.isNotEmpty) {
      final newFormatted = maskFormatter!.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: newValue),
      );
      if (textController.text != newFormatted.text) {
        textController.text = newFormatted.text;
      }
    } else if (currencyFormatter != null && newValue.isNotEmpty) {
      final newFormatted = currencyFormatter!.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: newValue),
      );
      if (textController.text != newFormatted.text) {
        textController.text = newFormatted.text;
      }
    } else {
      if (textController.text != newValue) {
        textController.text = newValue;
      }
    }
  }

  @override
  void dispose() {
    formController.removeListener(_onFormControllerChanged);
    disposeDataSource();
    textController.dispose();
    super.dispose();
  }

  void toggleObscureText() {
    obscureText = !obscureText;
    notifyListeners();
  }

  void onChanged(String value) {
    dynamic valueToStore = value;
    if (component.inputMask.isNotEmpty && maskFormatter != null) {
      valueToStore = maskFormatter!.getUnmaskedText();
    } else if (currencyFormatter != null) {
      valueToStore = value.replaceAll(RegExp(r'[^0-9.]'), '');
    }
    formController.updateValue(component.key, valueToStore);
  }

  bool isCurrencyField() {
    if (component is NumberComponent) {
      return (component as NumberComponent).enableCurrency;
    }
    return component is CurrencyComponent;
  }

  String? getPrefixText() {
    String? currencyCode;

    if (component is NumberComponent) {
      final numberComponent = component as NumberComponent;
      if (numberComponent.enableCurrency &&
          numberComponent.currency != null &&
          numberComponent.currency!.isNotEmpty) {
        currencyCode = numberComponent.currency;
      }
    } else if (component is CurrencyComponent) {
      final currencyComponent = component as CurrencyComponent;
      if (currencyComponent.currency.isNotEmpty) {
        currencyCode = currencyComponent.currency;
      }
    }

    if (currencyCode != null) {
      try {
        final symbol =
            NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
        return "$symbol ";
      } catch (e) {
        return "$currencyCode ";
      }
    }
    return null;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove any non-numeric characters except for the decimal point
    final String text = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    try {
      final double value = double.parse(text);
      final formatter = NumberFormat.decimalPattern();
      final String newText = formatter.format(value);

      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}
