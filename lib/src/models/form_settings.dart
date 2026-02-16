class FormSettings {
  final String submitLabel;
  final bool showReset;
  final String resetLabel;
  final bool confirmBeforeSubmit;
  final String successMessage;

  FormSettings({
    this.submitLabel = 'Submit',
    this.showReset = false,
    this.resetLabel = 'Reset',
    this.confirmBeforeSubmit = false,
    this.successMessage = 'Form submitted successfully!',
  });

  factory FormSettings.fromJson(Map<String, dynamic> json) {
    return FormSettings(
      submitLabel: json['submitLabel'] ?? 'Submit',
      showReset: json['showReset'] ?? false,
      resetLabel: json['resetLabel'] ?? 'Reset',
      confirmBeforeSubmit: json['confirmBeforeSubmit'] ?? false,
      successMessage: json['successMessage'] ?? 'Form submitted successfully!',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submitLabel': submitLabel,
      'showReset': showReset,
      'resetLabel': resetLabel,
      'confirmBeforeSubmit': confirmBeforeSubmit,
      'successMessage': successMessage,
    };
  }
}
