import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';
import 'package:flutter_onedrive/onedrive_file.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class OnedriveExplorerPage extends StatefulWidget {
  final OneDrive oneDrive;

  const OnedriveExplorerPage({super.key, required this.oneDrive});

  @override
  _OnedriveExplorerPageState createState() => _OnedriveExplorerPageState();
}

class _OnedriveExplorerPageState extends State<OnedriveExplorerPage> {
  String currentPath = '/';
  List<OnedriveFile> files = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      isLoading = true;
    });
    try {
      final listedFiles = await widget.oneDrive.listFiles(currentPath);
      setState(() {
        files = listedFiles;
      });
    } catch (e) {
      _showError('Failed to load files: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final localPath = result.files.single.path!;
      final fileName = result.files.single.name;
      final remotePath = path.join(currentPath, fileName);
      try {
        final fileBytes = await File(localPath).readAsBytes();
        await widget.oneDrive.push(fileBytes, remotePath);
        _loadFiles();
      } catch (e) {
        _showError('Upload failed: $e');
      }
    }
  }

  Future<void> _downloadFile(OnedriveFile file) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showError('Storage permission denied. Cannot download the file.');
        return;
      }

      // Use the Downloads directory if possible, else fallback to documents directory
      Directory? downloadsDir;

      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {
        // If getDownloadsDirectory is unavailable (e.g., on iOS), fallback
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null || !await downloadsDir.exists()) {
        _showError('Unable to access a downloads folder.');
        return;
      }

      final localPath = path.join(downloadsDir.path, file.name);
      final response = await widget.oneDrive.pull(file.path);

      if (response.isSuccess) {
        final fileOnDevice = File(localPath);
        await fileOnDevice.create(recursive: true);
        await fileOnDevice.writeAsBytes(response.bodyBytes?.toList() ?? []);
        _showMessage('Downloaded to $localPath', localPath);
      } else {
        _showError('Download failed: ${response.message}');
      }
    } catch (e) {
      _showError('Download failed: $e');
    }
  }

  Future<void> _deleteFile(OnedriveFile file) async {
    try {
      await widget.oneDrive.deleteFile(file.path);
      _loadFiles();
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  Future<void> _createDirectory() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('New Directory'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Directory Name'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final dirName = controller.text.trim();
                  if (dirName.isNotEmpty) {
                    final dirPath = path.join(currentPath, dirName);
                    try {
                      await widget.oneDrive.createDirectory(dirPath);
                      _loadFiles();
                    } catch (e) {
                      _showError('Create directory failed: $e');
                    }
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Create'),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
            ],
          ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showMessage(String message, String? filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action:
            filePath == null
                ? null
                : SnackBarAction(
                  label: 'Open',
                  onPressed: () {
                    OpenFile.open(filePath);
                  },
                ),
      ),
    );
  }

  void _enterDirectory(OnedriveFile file) {
    setState(() {
      currentPath = file.path;
    });
    _loadFiles();
  }

  Future<void> _refresh() async {
    await _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('OneDrive Explorer: $currentPath'),
          actions: [
            IconButton(
              icon: Icon(Icons.create_new_folder),
              onPressed: _createDirectory,
              tooltip: 'New Directory',
            ),
            IconButton(icon: Icon(Icons.upload_file), onPressed: _uploadFile, tooltip: 'Upload File'),
            IconButton(icon: Icon(Icons.refresh), onPressed: _refresh, tooltip: 'Refresh'),
          ],
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : files.isEmpty
                ? Center(child: Text('No files here'))
                : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ListTile(
                      leading: Icon(file.isFolder ? Icons.folder : Icons.insert_drive_file),
                      title: Text(file.name),
                      subtitle: Text(file.isFolder ? 'Directory' : '${file.size} bytes'),
                      onTap: () {
                        if (file.isFolder) {
                          _enterDirectory(file);
                        } else {
                          _downloadFile(file);
                        }
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFile(file),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    // fallback for older devices
    final storageStatus = await Permission.manageExternalStorage.request();
    if (storageStatus.isGranted) {
      return true;
    }
    // fallback for older devices
    return await Permission.storage.request().isGranted;
  }

  Future<bool> _onWillPop() async {
    if (currentPath == '/' || currentPath.isEmpty) {
      return true;
    } else {
      _goOneLevelUp();
      return false;
    }
  }

  void _goOneLevelUp() {
    if (currentPath == '/' || currentPath.isEmpty) {
      return;
    }
    final parentPath = path.dirname(currentPath);
    setState(() {
      currentPath = (parentPath == '.' || parentPath == '') ? '/' : parentPath;
    });
    _loadFiles();
  }
}
