import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:form_dynamic_builder/src/controller/form_controller.dart';
import 'package:form_dynamic_builder/src/models/data_source.dart';
import 'package:form_dynamic_builder/src/models/form_config.dart';
import 'package:form_dynamic_builder/src/models/form_settings.dart';
import 'package:form_dynamic_builder/src/services/data_source_service.dart';

void main() {
  group('DataSourceService Deep Nesting Tests', () {
    late FormController controller;

    setUp(() {
      controller = FormController(
        config: FormConfig(
          id: 'test',
          title: 'Test',
          components: [],
          settings: FormSettings(),
          description: '',
        ),
      );
    });

    test('should resolve deep nested paths like data[0].path[0].display',
        () async {
      const jsonResponse = '''
      {
        "data": [
          {
            "path": [
              { "display": "Deep Value 1" },
              { "display": "Deep Value 2" }
            ]
          },
          {
            "path": [
              { "display": "Other Value" }
            ]
          }
        ]
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://example.com/api',
        valuePath: 'data[0].path[1].display',
      );

      final result = await DataSourceService.fetchDefaultValue(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(result, equals('Deep Value 2'));
    });

    test('should support paths starting with index like [0].name', () async {
      const jsonResponse = '''
      [
        { "name": "Item 1" },
        { "name": "Item 2" }
      ]
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://example.com/api',
        valuePath: '[1].name',
      );

      final result = await DataSourceService.fetchDefaultValue(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(result, equals('Item 2'));
    });

    test('should return null for out of bounds index', () async {
      const jsonResponse = '''
      [
        { "name": "Item 1" }
      ]
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://example.com/api',
        valuePath: '[5].name',
      );

      final result = await DataSourceService.fetchDefaultValue(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(result, isNull);
    });

    test(
        'should use dataKey to drill down and valuePath to extract specific field',
        () async {
      const jsonResponse = '''
      {
        "status": "success",
        "result": {
          "user": {
            "profile": { "fullname": "John Doe" }
          }
        }
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://example.com/api',
        dataKey: 'result.user',
        valuePath: 'profile.fullname',
      );

      final result = await DataSourceService.fetchDefaultValue(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(result, equals('John Doe'));
    });

    test(
        'should handle dataKey pointing to array item and valuePath getting field',
        () async {
      const jsonResponse = '''
      {
        "data": [
          { "id": "A1", "meta": { "title": "First" } },
          { "id": "A2", "meta": { "title": "Second" } }
        ]
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://example.com/api',
        dataKey: 'data[1].meta',
        valuePath: 'title',
      );

      final result = await DataSourceService.fetchDefaultValue(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(result, equals('Second'));
    });

    test(
        'fetchOptions should use dataKey for list and valuePath for item field',
        () async {
      const jsonResponse = '''
      {
        "items": [
          { "code": "C1", "name": "Option 1" },
          { "code": "C2", "name": "Option 2" }
        ]
      }
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://example.com/api',
        dataKey: 'items',
        labelPath: 'name',
        valuePath: 'code',
      );

      final result = await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(result.length, 2);
      expect(result[0].label, "Option 1");
      expect(result[0].value, "C1");
    });
  });
}
