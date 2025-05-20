## Features

* Download files from onedrive
* Upload files to onedrive
* List files
* Create directory
* Delete files

## References
Read below documents before you start using this library:
* https://docs.microsoft.com/en-us/onedrive/developer/rest-api/getting-started/app-registration?view=odsp-graph-online
* https://docs.microsoft.com/en-us/onedrive/developer/rest-api/getting-started/msa-oauth?view=odsp-graph-online
* https://learn.microsoft.com/en-us/onedrive/developer/rest-api/concepts/special-folders-appfolder?view=odsp-graph-online
* https://github.com/LinusU/flutter_web_auth

## Getting started

```dart
flutter public add flutter_onedrive
```

```dart
import 'package:flutter_onedrive/flutter_onedrive.dart';
```

## Usage

```dart
final onedrive = OneDrive(redirectURL: "your redirect URL", clientID: "your client id");

return FutureBuilder(
  future: onedrive.isConnected(),
  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.data ?? false) {
      // Has connected
      return const Text("Connected");
    } else {
      // Hasn't connected
      return MaterialButton(
        child: const Text("Connect"),
        onPressed: () async {
          final success = await onedrive.connect(context);
          if (success) {
            // Create directories
            OneDriveResponse response = await onedrive.createDirectory("/test");
            
            // Upload files
            const str = "Hello, World!";
            var data = Uint8List.fromList(utf8.encode(str));
            response = await onedrive.push(data, "/test/hello.txt");
            
            // Download files
            response = await onedrive.pull("/test/hello.txt");

            // List files
            final files = await onedrive.listFiles("/test/");

            // Delete files
            response = await onedrive.deleteFile("/test/hello.txt");

            // Delete directories
            response = await onedrive.deleteFile("/test");
          }
        },
      );
    }
  },
);
```
