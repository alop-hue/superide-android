import 'dart:io';
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
    final target = File('/storage/emulated/0/Temps/tempCode.$extension');
    if (!target.existsSync()) {
      await target.create(recursive: true);
      return target;
    }
  }
  return File('/storage/emulated/0/Temps/tempCode.$extension');
}

Widget drawerButtons(VoidCallback onPressed, dynamic icon,
    {Color color = const Color(0xff6d6d6d)}) {
  if (icon.runtimeType == IconData) {
    return IconButton(
        onPressed: onPressed, icon: Icon(icon, color: color, size: 38));
  }
  return IconButton(onPressed: onPressed, icon: icon);
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

  static Future<void> runOnTermux(
      Language language, String filePath, BuildContext context) async {
    if (language.command == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xff181818),
          title: const Text("Not executable"),
          content: const Text("This language is not executable on termux"),
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
}
