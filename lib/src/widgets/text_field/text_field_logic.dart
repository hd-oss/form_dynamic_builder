import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/form_component.dart';
import '../../utils/form_constants.dart';

class TextFieldLogic extends ChangeNotifier {
  final FormComponent component;
  final FormController formController;
  final bool initialObscureText;

  late bool obscureText;
  MaskTextInputFormatter? maskFormatter;
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

    final currentValue =
        formController.getValue(component.key)?.toString() ?? '';
    if (maskFormatter != null && currentValue.isNotEmpty) {
      maskFormatter!.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: currentValue),
      );
      textController =
          TextEditingController(text: maskFormatter!.getMaskedText());
    } else {
      textController = TextEditingController(text: currentValue);
    }
  }

  @override
  void dispose() {
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
    }
    formController.updateValue(component.key, valueToStore);
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
        return NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
      } catch (e) {
        return currencyCode;
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
