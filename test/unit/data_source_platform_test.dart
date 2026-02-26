import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/src/models/components/all_components.dart';

void main() {
  group('FormComponent Platform DataSource Priority Tests', () {
    test(
        'should prioritize platforms.mobile.dataSource over top-level dataSource',
        () {
      final json = {
        "id": "c1",
        "type": "textfield",
        "key": "text",
        "label": "Text",
        "dataSource": {
          "type": "api",
          "api": {"url": "https://api.example.com/global", "valuePath": "name"}
        },
        "platforms": {
          "mobile": {
            "enabled": true,
            "dataSource": {
              "type": "api",
              "api": {
                "url": "https://api.example.com/mobile",
                "valuePath": "mobile_name"
              }
            }
          }
        }
      };

      final component = TextFieldComponent.fromJson(json);

      expect(component.dataSource, isNotNull);
      expect(component.dataSource!.api!.url,
          equals("https://api.example.com/mobile"));
      expect(component.dataSource!.api!.valuePath, equals("mobile_name"));
    });

    test(
        'should fall back to top-level dataSource if mobile platform has no dataSource',
        () {
      final json = {
        "id": "c1",
        "type": "textfield",
        "key": "text",
        "label": "Text",
        "dataSource": {
          "type": "api",
          "api": {"url": "https://api.example.com/global", "valuePath": "name"}
        },
        "platforms": {
          "web": {
            "enabled": true,
            "dataSource": {"type": "static"}
          }
        }
      };

      final component = TextFieldComponent.fromJson(json);

      expect(component.dataSource, isNotNull);
      expect(component.dataSource!.api!.url,
          equals("https://api.example.com/global"));
    });

    test('should preserve original platforms metadata in toJson', () {
      final json = {
        "id": "c1",
        "type": "textfield",
        "key": "text",
        "label": "Text",
        "platforms": {
          "web": {"enabled": false},
          "mobile": {"enabled": true}
        }
      };

      final component = TextFieldComponent.fromJson(json);
      final resultJson = component.toJson();

      expect(resultJson['platforms'], isNotNull);
      expect(resultJson['platforms']['web']['enabled'], isFalse);
      expect(resultJson['platforms']['mobile']['enabled'], isTrue);
    });
  });
}
