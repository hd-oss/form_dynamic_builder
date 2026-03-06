import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'dart:convert';

void main() {
  group('Form Parser Tests', () {
    test('Should parse FormConfig from JSON', () {
      const jsonStr = '''
      {
        "id": "form1",
        "title": "Test Form",
        "description": "A test form",
        "type": "form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "name",
            "label": "Name",
            "required": true
          },
          {
            "id": "c2",
            "type": "number",
            "key": "age",
            "label": "Age"
          }
        ],
        "settings": {
            "submitLabel": "Go"
        }
      }
      ''';

      final jsonMap = json.decode(jsonStr);
      final config = FormConfig.fromJson(jsonMap);

      expect(config.title, 'Test Form');
      expect(config.components.length, 2);
      expect(config.components[0], isA<TextFieldComponent>());
      expect(config.components[1], isA<NumberComponent>());
      expect(config.settings.submitLabel, 'Go');
    });

    test('Should parse wizard JSON correctly', () {
      final jsonMap = {
        "id": "comp_1771384591912_91da61yae",
        "title": "Untitled Form",
        "type": "wizard",
        "components": [],
        "steps": [
          {
            "key": "page1",
            "title": "Page 1",
            "components": [
              {"id": "c1", "type": "textfield", "key": "t1", "label": "Text 1"}
            ]
          },
          {
            "key": "page2",
            "title": "Page 2",
            "components": [
              {"id": "c2", "type": "textfield", "key": "t2", "label": "Text 2"}
            ]
          }
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      expect(config.type, 'wizard');
      expect(config.steps.length, 2);
      expect(config.steps[0].components.length, 1);
      expect(config.steps[1].components.length, 1);
    });
  });

  group('FileComponent Parser Tests', () {
    test('Should parse compressFile, compressPercentage and uploadTiming', () {
      final jsonMap = {
        "id": "comp_1771897366746_706gqqu7w",
        "title": "Untitled Form",
        "type": "form",
        "components": [
          {
            "id": "comp_1771897458039_gal25f0oq",
            "type": "file",
            "key": "file",
            "label": "File Upload",
            "multiple": false,
            "accept": ".pdf,.doc",
            "uploadUrl": "https://api.example.com/upload",
            "compressFile": false,
            "compressPercentage": 80,
            "uploadTiming": "immediate"
          },
          {
            "id": "comp_1771897570601_qbl5cqv92",
            "type": "file",
            "key": "file1",
            "label": "File Upload",
            "multiple": false,
            "accept": ".jpg,.img",
            "maxSize": 50000,
            "compressFile": true,
            "compressPercentage": 60,
            "uploadTiming": "onSubmit",
            "uploadUrl": "https://api.example.com/upload"
          },
          {
            "id": "comp_1771897723129_pjwdnnvju",
            "type": "file",
            "key": "file2",
            "label": "File Upload",
            "multiple": false,
            "accept": ".txt",
            "compressFile": false,
            "uploadTiming": "immediate"
          }
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      expect(config.components.length, 3);

      // Component 0: uploadTiming=immediate, no compress
      final c0 = config.components[0] as FileUploadComponent;
      expect(c0.compressFile, false);
      expect(c0.compressPercentage, 80);
      expect(c0.uploadTiming, 'immediate');
      expect(c0.accept, '.pdf,.doc');

      // Component 1: uploadTiming=onSubmit, compress 60%
      final c1 = config.components[1] as FileUploadComponent;
      expect(c1.compressFile, true);
      expect(c1.compressPercentage, 60);
      expect(c1.uploadTiming, 'onSubmit');
      expect(c1.maxSize, 50000);

      // Component 2: no uploadUrl — uploadTiming=immediate, compress defaults
      final c2 = config.components[2] as FileUploadComponent;
      expect(c2.compressFile, false);
      expect(c2.compressPercentage, 80); // default
      expect(c2.uploadTiming, 'immediate');
      expect(c2.uploadUrl, ''); // not provided
    });

    test(
        'Should use defaults when compressFile/compressPercentage/uploadTiming are absent',
        () {
      final jsonMap = {
        "id": "form_defaults",
        "type": "form",
        "title": "Default Test",
        "components": [
          {"id": "f1", "type": "file", "key": "attach", "label": "Attachment"}
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      final comp = config.components[0] as FileUploadComponent;

      expect(comp.compressFile, false);
      expect(comp.compressPercentage, 80);
      expect(comp.uploadTiming, 'onSubmit');
    });

    test('Should serialize new fields correctly with toJson', () {
      final comp = FileUploadComponent(
        id: 'f1',
        type: 'file',
        key: 'doc',
        label: 'Document',
        compressFile: true,
        compressPercentage: 70,
        uploadTiming: 'immediate',
      );

      final json = comp.toJson();
      expect(json['compressFile'], true);
      expect(json['compressPercentage'], 70);
      expect(json['uploadTiming'], 'immediate');
    });
  });

  group('CameraComponent Parser Tests', () {
    test('Should parse all new camera fields from JSON', () {
      final jsonMap = {
        "id": "comp_1771897366746_706gqqu7w",
        "title": "Untitled Form",
        "type": "form",
        "components": [
          {
            "id": "comp_1771899197800_341eig8uq",
            "type": "camera",
            "key": "camera",
            "label": "Camera",
            "cameraFacing": "both",
            "showTimestamp": true,
            "timestampFormat": "yyyy-MM-dd HH:mm:s",
            "showCoordinates": true,
            "showDeviceInfo": true,
            "compressFile": true,
            "uploadTiming": "immediate"
          },
          {
            "id": "comp_1771899303521_ebnsn8w4h",
            "type": "camera",
            "key": "camera1",
            "label": "Camera",
            "cameraFacing": "front",
            "showTimestamp": true,
            "timestampFormat": "yyyy-MM-dd HH:mm:s",
            "showCoordinates": false,
            "showDeviceInfo": true,
            "compressFile": false,
            "uploadTiming": "immediate"
          },
          {
            "id": "comp_1771899305734_9c4jn9cnt",
            "type": "camera",
            "key": "camera2",
            "label": "Camera",
            "cameraFacing": "rear",
            "showTimestamp": false,
            "timestampFormat": "yyyy-MM-dd HH:mm:s",
            "showCoordinates": false,
            "showDeviceInfo": false,
            "compressFile": false,
            "uploadTiming": "immediate"
          }
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      expect(config.components.length, 3);

      // camera 0: both, all overlays on, compress
      final c0 = config.components[0] as CameraComponent;
      expect(c0.cameraFacing, 'both');
      expect(c0.showTimestamp, true);
      expect(c0.timestampFormat, 'yyyy-MM-dd HH:mm:s');
      expect(c0.showCoordinates, true);
      expect(c0.showDeviceInfo, true);
      expect(c0.compressFile, true);
      expect(c0.uploadTiming, 'immediate');

      // camera 1: front, no coordinates
      final c1 = config.components[1] as CameraComponent;
      expect(c1.cameraFacing, 'front');
      expect(c1.showCoordinates, false);
      expect(c1.showDeviceInfo, true);
      expect(c1.compressFile, false);

      // camera 2: rear, no overlays
      final c2 = config.components[2] as CameraComponent;
      expect(c2.cameraFacing, 'rear');
      expect(c2.showTimestamp, false);
      expect(c2.showDeviceInfo, false);
    });

    test('Should use defaults when camera fields are absent', () {
      final jsonMap = {
        "id": "form_cam_defaults",
        "type": "form",
        "title": "Camera Default Test",
        "components": [
          {"id": "c1", "type": "camera", "key": "cam", "label": "Camera"}
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      final comp = config.components[0] as CameraComponent;

      expect(comp.cameraFacing, 'both');
      expect(comp.showTimestamp, false);
      expect(comp.timestampFormat, 'yyyy-MM-dd HH:mm:ss');
      expect(comp.showCoordinates, false);
      expect(comp.showDeviceInfo, false);
      expect(comp.compressFile, false);
      expect(comp.uploadTiming, 'onSubmit');
    });

    test('Should serialize camera fields correctly with toJson', () {
      final comp = CameraComponent(
        id: 'c1',
        type: 'camera',
        key: 'cam',
        label: 'Camera',
        cameraFacing: 'front',
        showTimestamp: true,
        timestampFormat: 'dd/MM/yyyy',
        showCoordinates: true,
        showDeviceInfo: false,
        compressFile: true,
        uploadTiming: 'immediate',
      );

      final json = comp.toJson();
      expect(json['cameraFacing'], 'front');
      expect(json['showTimestamp'], true);
      expect(json['timestampFormat'], 'dd/MM/yyyy');
      expect(json['showCoordinates'], true);
      expect(json['showDeviceInfo'], false);
      expect(json['compressFile'], true);
      expect(json['uploadTiming'], 'immediate');
    });
  });

  group('LocationComponent Parser Tests', () {
    test('Should parse location components from JSON', () {
      final jsonMap = {
        "id": "comp_1771897366746_706gqqu7w",
        "title": "Untitled Form",
        "type": "form",
        "components": [
          {
            "id": "comp_1771906359044_4rtknnzyi",
            "type": "location",
            "key": "location",
            "label": "Location",
            "enableMapPicker": true,
            "required": false,
            "disabled": false,
            "hidden": false,
            "validation": []
          },
          {
            "id": "comp_1771906361189_2ptmklk0w",
            "type": "location",
            "key": "location1",
            "label": "Location",
            "enableMapPicker": false
          }
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      expect(config.components.length, 2);

      final c0 = config.components[0] as LocationComponent;
      expect(c0.enableMapPicker, true);
      expect(c0.key, 'location');
      expect(c0.label, 'Location');

      final c1 = config.components[1] as LocationComponent;
      expect(c1.enableMapPicker, false);
      expect(c1.key, 'location1');
    });

    test('Should use default enableMapPicker=false when absent', () {
      final jsonMap = {
        "id": "form_loc_default",
        "type": "form",
        "title": "Location Default",
        "components": [
          {"id": "l1", "type": "location", "key": "loc", "label": "Location"}
        ],
        "settings": {}
      };
      final config = FormConfig.fromJson(jsonMap);
      final comp = config.components[0] as LocationComponent;
      expect(comp.enableMapPicker, false);
    });

    test('Should serialize enableMapPicker correctly with toJson', () {
      final comp = LocationComponent(
        id: 'l1',
        type: 'location',
        key: 'loc',
        label: 'Location',
        enableMapPicker: true,
      );
      final json = comp.toJson();
      expect(json['enableMapPicker'], true);
      expect(json['type'], 'location');
      expect(json['key'], 'loc');
    });
  });

  group('SignatureComponent Parser Tests', () {
    test('Should parse SignatureComponent and new upload fields from JSON', () {
      final jsonMap = {
        "id": "form_sig",
        "title": "Sig Form",
        "type": "form",
        "components": [
          {
            "id": "c_sig",
            "type": "signature",
            "key": "sig",
            "label": "Sign Here",
            "width": 300,
            "height": 200,
            "uploadUrl": "https://api.example.com/upload",
            "uploadTiming": "immediate"
          }
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      expect(config.components.length, 1);

      final c0 = config.components[0] as SignatureComponent;
      expect(c0.key, 'sig');
      expect(c0.width, 300);
      expect(c0.height, 200);
      expect(c0.uploadUrl, 'https://api.example.com/upload');
      expect(c0.uploadTiming, 'immediate');
    });

    test('Should use default values for uploadUrl and uploadTiming', () {
      final jsonMap = {
        "id": "form_sig2",
        "type": "form",
        "title": "Sig Form Default",
        "components": [
          {"id": "s1", "type": "signature", "key": "sig", "label": "Sign"}
        ],
        "settings": {}
      };
      final config = FormConfig.fromJson(jsonMap);
      final comp = config.components[0] as SignatureComponent;
      expect(comp.uploadUrl, '');
      expect(comp.uploadTiming, 'onSubmit');
    });
  });
}
