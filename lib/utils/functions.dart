import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> getPermission() async {
  final externalStatus = await Permission.manageExternalStorage.status;
  if (!externalStatus.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}

Future<Directory> setupProjectDir() async {
  final target = Directory('/sdcard/VSdroid/Projects');
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<Directory> setupTempDir() async {
  final target = Directory('/sdcard/VSdroid/Temps');
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<File> setTempFile(String extension) async {
  final dir = await setupTempDir();
  if (dir.existsSync()) {
    final target = File('/sdcard/VSdroid/Temps/tempCode.$extension');
    if (!target.existsSync()) {
      await target.create(recursive: true);
      return target;
    }
  }
  return File('/sdcard/VSdroid/Temps/tempCode.$extension');
}

Widget drawerButtons(VoidCallback onPressed, dynamic icon,
    {Color color = const Color(0xff6d6d6d)}) {
  if (icon.runtimeType == IconData) {
    return IconButton(
        onPressed: onPressed, icon: Icon(icon, color: color, size: 38));
  }
  return IconButton(onPressed: onPressed, icon: icon);
}
