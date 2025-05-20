import 'package:path/path.dart';

class OnedriveFile {
  final String id;
  final String name;
  final String path;
  final bool isFolder;
  final int size;
  final DateTime modifiedTime;

  OnedriveFile(
      {required this.id,
        required this.name,
        required this.path,
        required this.isFolder,
        required this.size,
        required this.modifiedTime});

  factory OnedriveFile.fromJson(Map<String, dynamic> json, bool isAppFolder) {
    final rawPath = json['parentReference']?['path'] ?? '';
    String path = '/';
    if (isAppFolder) {
      final match =
      RegExp(r'^/drive/root:/Apps/[^/]+(/.*)?$').firstMatch(rawPath);
      path = match?.group(1) ??
          '/'; // relative path to Appfolder, turns /Apps/APP_NAME to /
    } else {
      path = join(rawPath.replaceFirst(RegExp(r'^/drive/root:/?'),
          '/')); // replaces :drive/root with / and :drive/root/FOLDER with /FOLDER
    }
    path = join(path, json['name']);

    return OnedriveFile(
        id: json['id'],
        name: json['name'],
        path: path,
        isFolder: json['folder'] != null,
        size: json['size'] ?? 0,
        modifiedTime: DateTime.tryParse(json['3'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0));
  }
}
