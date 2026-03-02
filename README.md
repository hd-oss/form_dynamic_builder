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

## File Uploads (IoC)

For components like `Camera`, `File`, and `Signature`, the form builder delegates file uploads back to the Host Application using the `onFileUpload` callback. 

By default, these components use `uploadTiming: "onSubmit"`, meaning they will only store the **local file path** in the form's state. It is up to the host application to upload these files when the entire form is submitted.

However, if a component is configured with `uploadTiming: "immediate"`, the form builder will attempt to upload the file right after it is selected/captured. To support this, you must provide the `onFileUpload` callback:

```dart
final config = FormConfig.fromJson(
  formJson,
  onFileUpload: (String localPath, String uploadUrl) async {
    // Example: Use Dio or http to upload the file to `uploadUrl`
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath('file', localPath));
    
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      return data['url']; // Return the remote URL of the uploaded file
    }
    return null; // Return null on failure (will fallback to storing local path)
  },
);
```

If `onFileUpload` is successful and returns a String (the remote URL), the form will store this remote URL in its state instead of the local path.

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

}
```

---

## Data Source Configuration

The form builder supports fetching dynamic values and options from external sources using the `dataSource` property. There are two supported types: `api` and `database`. Both types use **Inversion of Control (IoC)**, meaning the form builder delegates the actual data fetching (HTTP request or Database query) back to your Host Application.

### `type: "api"`
Fetches data via HTTP requests. Requires connectivity.

```json
"dataSource": {
  "type": "api",
  "api": {
    "url": "https://api.example.com/options?search={{searchQuery}}",
    "method": "GET",
    "dataKey": "data.items",
    "labelPath": "name",
    "valuePath": "id",
    "headers": [{"Authorization": "Bearer token"}],
    "body": ""
  }
}
```

**Host Application Implementation for `api`:**
You must provide the `onApiQuery` callback when initializing the `FormConfig`. The form builder will not make the HTTP request internally.

```dart
final config = FormConfig.fromJson(
  formJson,
  onApiQuery: (String url, String method, Map<String, String> headers, String body) async {
    // Example using http package handling the fetch logic
    final response = await http.get(Uri.parse(url), headers: headers);
    return response.body; // ensure you return a String or decoded JSON Map/List
  },
);
```

### `type: "database"`
Fetches data from a local database (e.g., SQLite) by allowing the host application to execute the query via a callback function. This uses Inversion of Control.

```json
"dataSource": {
  "type": "database",
  "database": {
    "connectionString": "sqlite:browser",
    "dbName": "lcs",
    "query": "SELECT user_name as label, user_id as value FROM mst_users WHERE group_id = {{ds_form.lcs.group_id}};",
    "labelPath": "label",
    "valuePath": "value"
  }
}
```

**Host Application Implementation for `database`:**
You must provide the `onDatabaseQuery` callback when initializing the `FormConfig`.

```dart
final config = FormConfig.fromJson(
  formJson,
  onDatabaseQuery: (String connectionString, String dbName, String query) async {
    // Example using sqflite
    final db = await openDatabase('$dbName.db');
    return await db.rawQuery(query);
  },
);
```

**Placeholders:**
Both `api.url` and `database.query` support placeholders for interpolation:
- `{{componentKey}}`: Injects the current value of another field.
- `{{ds_form.xxx}}`: Injects dynamic data passed via `dsForm`.
- `{{var.static.current_year}}`: Injects static variables (e.g. `current_date`, `current_month`).

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
