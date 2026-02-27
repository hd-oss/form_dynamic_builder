import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:form_dynamic_builder/src/services/data_source_service.dart';

void main() {
  test('ds_form manual update and interpolation test', () {
    final config = FormConfig(
      id: 'test_form',
      title: 'Test Form',
      description: 'Test',
      components: [],
      settings: FormSettings(),
      dsForm: {
        "task": {
          "lcs": {"id": "initial_lcs", "status": "open"},
          "los": {"id": "initial_los", "status": "pending"}
        }
      },
    );

    final controller = FormController(config: config);

    // Initial check
    expect(
      DataSourceService.interpolateUrl('{{ds_form.task.lcs.id}}', controller),
      'initial_lcs',
    );

    // Manual update
    controller.updateDsForm({
      "task": {
        "lcs": {"id": "updated_lcs", "status": "closed"},
        "los": {"id": "updated_los", "status": "approved"}
      }
    });

    // Verify interpolation uses updated values
    expect(
      DataSourceService.interpolateUrl('{{ds_form.task.lcs.id}}', controller),
      'updated_lcs',
    );
    expect(
      DataSourceService.interpolateUrl(
          '{{ds_form.task.los.status}}', controller),
      'approved',
    );

    // Partial update
    controller.updateDsForm({
      "user": {"name": "John"}
    });

    expect(
      DataSourceService.interpolateUrl('{{ds_form.user.name}}', controller),
      'John',
    );
    // Previous data should still be there if merged correctly (addAll is used)
    expect(
      DataSourceService.interpolateUrl('{{ds_form.task.lcs.id}}', controller),
      'updated_lcs',
    );
  });
}
