## Features

* Download files from onedrive
* Upload files to onedrive

## Getting started

```dart
import 'package:flutter_onedrive/flutter_onedrive.dart';
```

## Usage

```dart
final onedrive = OneDrive(callbackSchema: "your callback schema", clientID: "your client id");
final success = await onedrive.connect();
if (success) {
  // Download files
  final txtBytes = await onedrive.pull("/xxx/xxx.txt");
  // Upload files
  await onedrive.push(txtBytes!, "/xxx/xxx.txt");
}
```
