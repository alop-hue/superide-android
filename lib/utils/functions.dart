import 'dart:io';
import 'package:file_icon/src/data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/utils/languages.dart';

Future<bool> getPermission() async {
  final externalStatus = await Permission.manageExternalStorage.status;
  if (!externalStatus.isGranted) {
    await Permission.manageExternalStorage.request();
  }
  return await Permission.manageExternalStorage.status.isGranted;
}

Future<Directory> setupProjectDir() async {
  final target = Directory('/storage/emulated/0/VSdroid/Projects');
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<Directory> setupTempDir() async {
  final target = Directory('/storage/emulated/0/VSdroid/Temps');
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<File> setTempFile(String extension) async {
  await getPermission();
  final dir = await setupTempDir();
  if (dir.existsSync()) {
    final target =
        File('/storage/emulated/0/VSdroid/Temps/tempCode.$extension');
    if (!target.existsSync()) {
      await target.create(recursive: true);
      return target;
    }
  }
  return File('/storage/emulated/0/VSdroid/Temps/tempCode.$extension');
}

Widget drawerButtons(VoidCallback onPressed, dynamic icon,
    {Color color = const Color(0xff6d6d6d),
    Color bgColor = Colors.transparent}) {
  if (icon.runtimeType == IconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Container(
        color: bgColor,
        child: IconButton(
            onPressed: onPressed, icon: Icon(icon, color: color, size: 38)),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: IconButton(onPressed: onPressed, icon: icon),
  );
}

Widget fileTiles(VoidCallback onPressed, String text, dynamic icon,
    {double val = 0}) {
  return Padding(
    padding: const EdgeInsets.only(left: 15),
    child: ListTile(
      onTap: onPressed,
      title: Text(text,
          style: const TextStyle(
              color: Color.fromARGB(255, 118, 180, 234),
              fontWeight: FontWeight.w300)),
      leading: Padding(
        child: icon,
        padding: EdgeInsets.only(left: val),
      ),
      iconColor: const Color(0xff5090c8),
    ),
  );
}

Widget drawerTile(VoidCallback onPressed, String title, dynamic icon) {
  return ListTile(onTap: onPressed, title: Text(title), leading: icon);
}

Future<File?> pickFiles(BuildContext context) async {
  final result = await FilesystemPicker.open(
      requestPermission: () => getPermission(),
      permissionText: "Permission denied",
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
      title: "Select a file",
      folderIconColor: Colors.grey,
      showGoUp: true,
      context: context,
      rootDirectory: Directory('/storage/emulated/0'),
      rootName: "Storage",
      theme: FilesystemPickerTheme(
          fileList: FilesystemPickerFileListThemeData(
              fileTypes: FilesystemPickerFileListFileTypesTheme(
                  List.generate(languages.length, ((index) {
                String? key;
                final fileName = 'file.${languages[index].extension}';
                if (iconSetMap.containsKey(fileName)) {
                  key = fileName;
                } else {
                  var chunks = fileName.split('.').sublist(1);
                  while (chunks.isNotEmpty) {
                    var k = '.${chunks.join()}';
                    if (iconSetMap.containsKey(k)) {
                      key = k;
                      break;
                    }
                    chunks = chunks.sublist(1);
                  }
                }
                key ??= '.txt';
                return FilesystemPickerFileListFileTypesThemeItem(
                    extensions: [languages[index].extension],
                    icon: IconData(iconSetMap[key]!.codePoint,
                        fontFamily: 'Seti', fontPackage: 'file_icon'));
              }))),
              fileIconColor: Colors.grey),
          topBar: FilesystemPickerTopBarThemeData(
              foregroundColor: Colors.grey[300],
              backgroundColor: const Color(0xff4b5365)),
          backgroundColor: const Color(0xff282c35)));
  if (result != null && File(result).existsSync()) {
    final file = File(result);
    return file;
  }
  return null;
}

Future<String?> pickDir() async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  if (selectedDirectory != null) {
    return selectedDirectory;
  }
  return null;
}

Future<File?> createFile(String filename, BuildContext context) async {
  await getPermission();
  final fileDir = Directory("/sdcard/VSdroid/files");
  if (!fileDir.existsSync()) {
    await fileDir.create(recursive: true);
  }
  final file = File("/sdcard/VSdroid/files/$filename");
  if (!file.existsSync()) {
    try {
      await file.create(recursive: true);
      return file;
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(e.toString()),
            title: const Text("Failed to open file",
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
            backgroundColor: const Color(0xff2b2b2b),
            icon: const Icon(Icons.error_outline),
            iconColor: Colors.red[600],
          ),
        );
      }
    }
  }
  return null;
}

Future<HttpServer?> startServer() async {
  try {
    final server = await HttpServer.bind('127.0.0.1', 49258);
    return server;
  } catch (e) {
    return null;
  }
}

Future<String> getSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final savedThemeName = prefs.getString('selectedTheme');
  return savedThemeName??'atom-one-dark';
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class NativeChannel {
  static const MethodChannel _channel = MethodChannel('com.vsdroid');

  static Future<String> loadLibrary(String libName) async {
    try {
      final String result =
          await _channel.invokeMethod('loadLibrary', {"libName": libName});
      return result;
    } on PlatformException catch (e) {
      return "Failed to load library: ${e.message}";
    }
  }

  static Future<void> sendCommand(
      Language language, String filePath, BuildContext context) async {
    if (language.command == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xff181818),
          title: const Text("Not executable",
              style: TextStyle(color: Colors.white)),
          content: const Text("This language is not executable on termux",
              style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.warning_amber_outlined),
          iconColor: Colors.orange[300],
        ),
      );
    }
    await _channel.invokeMethod('sendCommand', {
      "fileName": filePath,
      "languageCommand": language.command,
    });
  }

  static Future<void> installOnTermux(String packageName) async {
    await _channel.invokeMethod("installOnTermux", {
      "packageName": packageName,
    });
  }
}
