import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';
import 'onedrive_explorer.dart';

class OneDriveButton extends StatefulWidget {
  const OneDriveButton({super.key});

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

    // Use your own redirect URL, ensuring that the scheme matches the one in AndroidManifest.xml and Info.plist
    // Search "msauth.xpass" in AndroidManifest.xml and Info.plist for examples
    redirectController = TextEditingController(text: "msauth.xpass://auth");
    clientIDController = TextEditingController();
    onedrive = OneDrive(redirectURL: redirectController.text, clientID: clientIDController.text);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      "Connected to OneDrive",
                      style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(200, 48),
                ),
                child: const Text("Disconnect", style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  // Disconnect
                  await onedrive.disconnect();
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(200, 48),
                ),
                child: const Text("Test Connection", style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  const str = "Hello, World!";
                  var data = Uint8List.fromList(utf8.encode(str));

                  // Upload files
                  var response = await onedrive.push(data, "/test/hello.txt");
                  if (!response.isSuccess) {
                    debugPrint('🪲[${response.statusCode}] ${response.message}\n🪲${response.body}');
                    return;
                  }

                  // Download files
                  response = await onedrive.pull("/test/hello.txt");
                  if (!response.isSuccess) {
                    debugPrint('🪲[${response.statusCode}] ${response.message}\n🪲${response.body}');
                    return;
                  }

                  // Delete files
                  response = await onedrive.deleteFile('/test/hello.txt');
                  if (!response.isSuccess) {
                    debugPrint('🪲[${response.statusCode}] ${response.message}\n🪲${response.body}');
                    return;
                  }

                  // Create directory
                  response = await onedrive.createDirectory('/hello');
                  if (!response.isSuccess) {
                    debugPrint('🪲[${response.statusCode}] ${response.message}\n🪲${response.body}');
                    return;
                  }

                  // Delete directory
                  response = await onedrive.deleteFile('/hello');
                  if (!response.isSuccess) {
                    debugPrint('🪲[${response.statusCode}] ${response.message}\n🪲${response.body}');
                    return;
                  }

                  // Success
                  debugPrint('🏆[${response.statusCode}] ${response.message}\n🏆${response.body}');
                },
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(200, 48),
                ),
                child: const Text("Open explorer", style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => OnedriveExplorerPage(oneDrive: onedrive),
                  ));
                },
              ),
            ],
          );
        } else {
          // Hasn't connected
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cancel, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      "Not Connected to OneDrive Yet",
                      style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: redirectController,
                decoration: const InputDecoration(labelText: 'Redirect URL'),
                onChanged: (value) {
                  onedrive = OneDrive(redirectURL: value, clientID: clientIDController.text);
                },
              ),
              TextField(
                controller: clientIDController,
                decoration: const InputDecoration(labelText: 'Client ID'),
                onChanged: (value) {
                  onedrive = OneDrive(redirectURL: redirectController.text, clientID: value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(200, 48),
                ),
                child: const Text("Connect", style: TextStyle(fontSize: 16)),
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
