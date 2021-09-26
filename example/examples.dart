import 'package:flutter_onedrive/flutter_onedrive.dart';

void main() async {
  final onedrive = OneDrive(callbackSchema: "your callback schema", clientID: "your client id");
  final success = await onedrive.connect();

  if (success) {
    // Download files
    final txtBytes = await onedrive.pull("/xxx/xxx.txt");

    // Upload files
    await onedrive.push(txtBytes!, "/xxx/xxx.txt");
  }
}
