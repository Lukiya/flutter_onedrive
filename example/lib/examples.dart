import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';

class OneDriveButton extends StatefulWidget {
  const OneDriveButton({Key? key}) : super(key: key);

  @override
  OneDriveButtonState createState() => OneDriveButtonState();
}

class OneDriveButtonState extends State<OneDriveButton> with WidgetsBindingObserver {
  late TextEditingController redirectController;
  late TextEditingController clientIDController;
  late OneDrive onedrive;

  @override
  void initState() {
    super.initState();
    redirectController = TextEditingController();
    clientIDController = TextEditingController();
    onedrive = OneDrive(
      redirectURL: redirectController.text,
      clientID: clientIDController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: onedrive.isConnected(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data ?? false) {
          // Has connected
          return Column(
            children: [
              MaterialButton(
                child: const Text("Disconnect"),
                onPressed: () async {
                  // Disconnect
                  await onedrive.disconnect();
                  setState(() {});
                },
              ),
              MaterialButton(
                child: const Text("Test"),
                onPressed: () async {
                  const str = "Hello, World!";
                  var data = Uint8List.fromList(utf8.encode(str));

                  // Upload files
                  var response = await onedrive.push(data, "/test/hello.txt");
                  if (!response.isSuccess) {
                    debugPrint(response.message);
                    return;
                  }

                  // Download files
                  response = await onedrive.pull("/test/hello.txt");
                  if (!response.isSuccess) {
                    debugPrint(response.message);
                    return;
                  }

                  debugPrint(response.body);
                },
              ),
            ],
          );
        } else {
          // Hasn't connected
          return Column(
            children: [
              TextField(
                controller: redirectController,
                decoration: const InputDecoration(labelText: 'Redirect URL'),
                onChanged: (value) {
                  onedrive = OneDrive(
                    redirectURL: value,
                    clientID: clientIDController.text,
                  );
                },
              ),
              TextField(
                controller: clientIDController,
                decoration: const InputDecoration(labelText: 'Client ID'),
                onChanged: (value) {
                  onedrive = OneDrive(
                    redirectURL: redirectController.text,
                    clientID: value,
                  );
                },
              ),
              MaterialButton(
                child: const Text("Connect"),
                onPressed: () async {
                  bool success = await onedrive.connect(context);
                  if (success) {
                    setState(() {});
                  }
                },
              ),
            ],
          );
        }
      },
    );
  }
}
