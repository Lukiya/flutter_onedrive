<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

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
