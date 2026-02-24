/// Centralized constants for the form_dynamic_builder library.
/// Eliminates hardcoded strings throughout the codebase.
class FormConstants {
  FormConstants._();

  // ── Component Types ──────────────────────────────────────────────────
  static const String typeTextField = 'textfield';
  static const String typeTextArea = 'textarea';
  static const String typeNumber = 'number';
  static const String typePassword = 'password';
  static const String typeCurrency = 'currency';
  static const String typeCheckbox = 'checkbox';
  static const String typeSelect = 'select';
  static const String typeSelectBoxes = 'selectboxes';
  static const String typeRadio = 'radio';
  static const String typeDateTime = 'datetime';
  static const String typeFile = 'file';
  static const String typeSignature = 'signature';
  static const String typeButton = 'button';
  static const String typeTags = 'tags';
  static const String typeCamera = 'camera';
  static const String typeLocation = 'location';
  static const String typeUnknown = 'unknown';

  // ── Form Types ───────────────────────────────────────────────────────
  static const String formTypeWizard = 'wizard';
  static const String formTypeDefault = 'form';

  // ── Text Transforms ──────────────────────────────────────────────────
  static const String transformUppercase = 'uppercase';
  static const String transformLowercase = 'lowercase';
  static const String transformNone = 'none';

  // ── Validation Rule Types ────────────────────────────────────────────
  static const String validationRequired = 'required';
  static const String validationMinLength = 'minLength';
  static const String validationMaxLength = 'maxLength';
  static const String validationPattern = 'pattern';

  // ── Validation Messages ──────────────────────────────────────────────
  static const String defaultMessage = 'Invalid value';
  static String requiredMessage(String label) => '$label is required';

  // ── Input Mask Filter Characters ─────────────────────────────────────
  static const String maskDigit = '9';
  static const String maskAlpha = 'a';
  static const String maskAlphaNum = '#';

  // ── Conditional Logic ────────────────────────────────────────────────
  static const String opEquals = 'eq';
  static const String opNotEquals = 'neq';
  static const String opGreaterThan = 'gt';
  static const String opGreaterOrEqual = 'gte';
  static const String opLessThan = 'lt';
  static const String opLessOrEqual = 'lte';
  static const String opContains = 'contains';
  static const String opNotContains = 'notContains';
  static const String opNotEmpty = 'notEmpty';
  static const String opIsEmpty = 'isEmpty';

  static const String logicAnd = 'and';
  static const String logicOr = 'or';

  // ── UI Constants ─────────────────────────────────────────────────────
  static const String requiredSuffix = ' *';
  static const String numericFilterPattern = r'[0-9.]';

  // ── Currency Prefixes ────────────────────────────────────────────────
  static const Map<String, String> currencyPrefixes = {
    'IDR': 'Rp',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'SGD': r'S$',
    'MYR': 'RM',
    'AUD': r'A$',
  };
}
