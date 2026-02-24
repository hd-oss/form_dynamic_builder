# form_dynamic_builder

A Flutter package for rendering dynamic forms from a JSON schema. Supports a rich set of field types including text, number, date, file upload, camera capture, signature, and more.

---

## Features

- 📋 Render forms dynamically from a JSON configuration
- 📷 Camera capture with metadata annotation (timestamp, GPS, device info) burned onto the photo
- 📁 File upload with size validation and compression metadata
- 🗓️ Date & time pickers
- ✍️ Signature pad
- ☑️ Checkbox, radio, select, tags, select-boxes
- 🔢 Number and currency fields
- 🔒 Validation rules (required, minLength, maxLength, etc.)
- 🪄 Conditional visibility logic
- 🧙 Wizard (multi-step) form support

---

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  form_dynamic_builder:
    path: ../form_dynamic_builder  # or your pub.dev version
```

---

## Permissions

Some field types require platform permissions to be declared in your app. Follow the setup below based on which components you use.

---

### 📷 Camera (`type: "camera"`)

Uses the `camera` package to take photos.

#### Android

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

#### iOS

In `ios/Runner/Info.plist`, add inside `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Dibutuhkan untuk mengambil foto pada form.</string>
```

---

### 📍 GPS Coordinates on Photo (`showCoordinates: true`)

When the camera component is configured with `showCoordinates: true`, the app will fetch GPS coordinates and burn them onto the captured photo. This uses the `geolocator` package.

#### Android

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

#### iOS

In `ios/Runner/Info.plist`, add inside `<dict>`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Dibutuhkan untuk menampilkan koordinat GPS pada foto.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Dibutuhkan untuk menampilkan koordinat GPS pada foto.</string>
```

---

### 📁 File Upload (`type: "file"`)

Uses the `file_picker` package. No extra permissions needed on Android 13+ or iOS. For older Android (< API 33), add:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

---

### Full `AndroidManifest.xml` example

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera -->
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- GPS (for camera showCoordinates) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

    <application ...>
        ...
    </application>
</manifest>
```

### Full `Info.plist` example

```xml
<dict>
    <!-- Camera -->
    <key>NSCameraUsageDescription</key>
    <string>Dibutuhkan untuk mengambil foto pada form.</string>

    <!-- GPS (for camera showCoordinates) -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Dibutuhkan untuk menampilkan koordinat GPS pada foto.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Dibutuhkan untuk menampilkan koordinat GPS pada foto.</string>
</dict>
```

---

## Usage

```dart
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:flutter/material.dart';

final formJson = {
  "id": "form_1",
  "title": "My Form",
  "type": "form",
  "components": [
    {
      "id": "c1",
      "type": "textfield",
      "key": "name",
      "label": "Full Name",
      "required": true
    },
    {
      "id": "c2",
      "type": "camera",
      "key": "photo",
      "label": "Photo",
      "cameraFacing": "rear",
      "showTimestamp": true,
      "timestampFormat": "yyyy-MM-dd HH:mm:ss",
      "showCoordinates": true,
      "showDeviceInfo": true,
      "uploadTiming": "onSubmit"
    }
  ],
  "settings": {
    "submitLabel": "Submit"
  }
};

final config = FormConfig.fromJson(formJson);
final controller = FormController(config: config);

// In your widget tree:
FormDynamicBuilder(controller: controller)

// On submit:
if (controller.validate()) {
  final values = controller.values;
  print(values); // { "name": "John", "photo": "/tmp/photo_annotated_xxx.png" }
}
```

---

## Camera Component — Configuration

| Field | Type | Default | Description |
|---|---|---|---|
| `cameraFacing` | `String` | `"both"` | `"front"`, `"rear"`, or `"both"` (allows switching) |
| `showTimestamp` | `bool` | `false` | Burn timestamp onto the photo |
| `timestampFormat` | `String` | `"yyyy-MM-dd HH:mm:ss"` | Date format for the timestamp |
| `showCoordinates` | `bool` | `false` | Burn GPS coordinates onto the photo |
| `showDeviceInfo` | `bool` | `false` | Burn device OS info onto the photo |
| `compressFile` | `bool` | `false` | Flag for the consuming app to compress before upload |
| `uploadTiming` | `String` | `"onSubmit"` | `"immediate"` or `"onSubmit"` |

---

## File Upload Component — Configuration

| Field | Type | Default | Description |
|---|---|---|---|
| `multiple` | `bool` | `false` | Allow multiple file selection |
| `accept` | `String` | `""` | Accepted extensions, e.g. `".pdf,.doc"` |
| `maxSize` | `int` | `0` | Max file size in bytes (0 = unlimited) |
| `uploadUrl` | `String` | `""` | Target upload endpoint URL |
| `compressFile` | `bool` | `false` | Flag for the consuming app to compress |
| `compressPercentage` | `int` | `80` | Compression quality 0–100% |
| `uploadTiming` | `String` | `"onSubmit"` | `"immediate"` or `"onSubmit"` |

---

## Additional information

- File issues at the project repository
- Contributions are welcome via pull request
