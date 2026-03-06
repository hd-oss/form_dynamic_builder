import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:form_dynamic_builder/src/services/datasource_service.dart';

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
      DatasourceService.interpolateUrl('{{ds_form.task.lcs.id}}', controller),
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
      DatasourceService.interpolateUrl('{{ds_form.task.lcs.id}}', controller),
      'updated_lcs',
    );
    expect(
      DatasourceService.interpolateUrl(
          '{{ds_form.task.los.status}}', controller),
      'approved',
    );

    // Partial update
    controller.updateDsForm({
      "user": {"name": "John"}
    });

    expect(
      DatasourceService.interpolateUrl('{{ds_form.user.name}}', controller),
      'John',
    );
    // Previous data should still be there if merged correctly (addAll is used)
    expect(
      DatasourceService.interpolateUrl('{{ds_form.task.lcs.id}}', controller),
      'updated_lcs',
    );
  });
}
