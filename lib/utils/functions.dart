import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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
    {Color color = const Color(0xff6d6d6d)}) {
  if (icon.runtimeType == IconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: IconButton(
          onPressed: onPressed, icon: Icon(icon, color: color, size: 38)),
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

Future<File?> pickFiles() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result != null) {
    File file = File(result.files.single.path!);
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

  static Future<void> sendOperations(
      String operation, List<String> args) async {
    await _channel.invokeMethod("sendOperations", {
      "operation": operation,
      "arguments": args,
    });
  }
}
