import 'package:flutter/material.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';

void main() {}

FutureBuilder buildConnectButton(BuildContext context) {
  final onedrive = OneDrive(callbackSchema: "your callback schema", clientID: "your client id");

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
            final success = await onedrive.connect();
            if (success) {
              // Download files
              final txtBytes = await onedrive.pull("/xxx/xxx.txt");
              // Upload files
              await onedrive.push(txtBytes!, "/xxx/xxx.txt");
            }
          },
        );
      }
    },
  );
}
