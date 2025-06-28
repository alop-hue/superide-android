import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:file_icon/src/data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_crafter/code_crafter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:http/http.dart' as http;

Future<bool> getPermission() async {
  final externalStatus = await Permission.manageExternalStorage.status;
  if (!externalStatus.isGranted) {
    await Permission.manageExternalStorage.request();
  }
  return await Permission.manageExternalStorage.status.isGranted;
}

Future<void> startTermuxActivity() async{
  const intent = AndroidIntent(
    componentName: 'com.termux.app.TermuxActivity',
    package: 'com.termux',
  );
  const intent2 = AndroidIntent(
    componentName: 'com.vsdroid.MainActivity',
    package: 'com.vsdroid',
  );
  await intent.launch();
  await Future.delayed(const Duration(milliseconds: 200));
  await intent2.launch();
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
  File target;
  if (dir.existsSync()) {
    if(extension == 'html'){
      target = File('/storage/emulated/0/VSdroid/Temps/index.html');  
    }
    else if(extension == 'css'){
      target = File('/storage/emulated/0/VSdroid/Temps/style.css');  
    }
    else if(extension == 'js'){
      target = File('/storage/emulated/0/VSdroid/Temps/script.js');  
    }
    else{
      target = File('/storage/emulated/0/VSdroid/Temps/tempCode.$extension');
    }
    if (!target.existsSync()) {
      await target.create(recursive: true);
      return target;
    }
  }
  return extension=='html' 
      ?File('/storage/emulated/0/VSdroid/Temps/index.html')
      :extension == 'css'
        ?File('/storage/emulated/0/VSdroid/Temps/style.css')
        :extension == 'js'
          ?File('/storage/emulated/0/VSdroid/Temps/script.js')
          :File('/storage/emulated/0/VSdroid/Temps/tempCode.$extension');
}

Future<File?> pickFiles(BuildContext context, bool isDark) async {
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
              icon: IconData(iconSetMap[key]!.codePoint,fontFamily: 'Seti', fontPackage: 'file_icon'));
        }))),
        fileIconColor: Colors.grey),
    topBar: FilesystemPickerTopBarThemeData(
        foregroundColor: Colors.grey[isDark ? 300 : 800],
        backgroundColor: Color(isDark ? 0xff4b5365 : 0xffd3d3d3)),
    backgroundColor: Color(isDark ? 0xff282c35 : 0xffffffff)));
  if (result != null && File(result).existsSync()) {
    final file = File(result);
    return file;
  }
  return null;
}

Future<String?> pickDir() async {
  return await FilePicker.platform.getDirectoryPath();
}

Future<String?> selectDir({String? dialogeTitle, String? initialDirectory, Uint8List? bytes}) async{
  return await FilePicker.platform.saveFile(
    dialogTitle: dialogeTitle,
    initialDirectory: initialDirectory,
    bytes: bytes
  );
}

Future<File?> createFile(String filename, String dirPath, BuildContext context) async {
  await getPermission();
  final fileDir = Directory(dirPath);
  if (!fileDir.existsSync()) {
    await fileDir.create(recursive: true);
  }
  final file = File("$dirPath/$filename");
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
            title: const Text(
              "Failed to open file",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)
            ),
            backgroundColor: const Color(0xff2b2b2b),
            icon: const Icon(Icons.error_outline),
            iconColor: Colors.red[600],
          ),
        );
      }
    }
  }
  return file;
}

Future<HttpServer?> startServer() async {
  try {
    final server = await HttpServer.bind('127.0.0.1', 49258);
    return server;
  } catch (e) {
    return null;
  }
}

Future<String> getRecent() async{
  final prefs = await SharedPreferences.getInstance();
  final recent = prefs.getString('recent');
  return recent ?? '[]';
}

Future<String> getAppTheme() async{
  final prefs = await SharedPreferences.getInstance();
  final savedAppTheme = prefs.getString("savedAppTheme");
  return savedAppTheme ?? "dark";
}

Future<String> getCodeCrafterConfig() async{
  final prefs = await SharedPreferences.getInstance();
  final config = prefs.getString('codeCrafterConfig');
  return config ?? 
    '{"indentLineStatus":true, "lineWrap":false, "enableFolding":true, "theme":"vs2015", "fontFamily": "monospace"}';
}

Future<String> getAiConfig() async{
  final prefs = await SharedPreferences.getInstance();
  final config = prefs.getString('aiConfig');
  return config ?? '{}';
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

Future<Map<String, dynamic>> sendRequest({
  required String url,
  required String method,
  Map<String, String>? headers,
  Object? body,
}) async {
  final uri = Uri.parse(url);
  http.Response response;

  try {
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: body);
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: body);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    return {
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };
  } catch (e) {
    return {
      'error': e.toString(),
    };
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

  static Future<bool> sendCommand(
      Language language, String filePath, BuildContext context, {bool containInput = false}) async {
    if (language.command == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 49, 49, 49),
          title: const Text("Not executable",
              style: TextStyle(color: Colors.white)),
          content: const Text("Unable to execute this language on termux",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.warning_amber_outlined),
          iconColor: Colors.orange[300],
        ),
      );
      return false;
    }
    try {
      if (language.name == "Java") {
        File(filePath).parent.listSync().forEach((FileSystemEntity item){
          if(item is File && item.path.contains(".class")){
            item.deleteSync(recursive: true);
          }
        });
      } 
    } finally {
        await _channel.invokeMethod('sendCommand', {
          "fileName": filePath,
          "languageCommand": language.command,
          "type": language.type,
         });
      }
    return true;
  }

  static Future<void> closeTermux() async{
    await _channel.invokeMethod("closeTermux");
  }

  static Future<void> installOnTermux(String packageName) async {
    await _channel.invokeMethod("installOnTermux", {
      "packageName": packageName,
    });
  }
}

class ActiveEditors{
  final File filePath;
  final CodeCrafterController controller;
  final Language languageDetails;
  bool isActive;
  String? text;

  ActiveEditors({
    required this.filePath,
    required this.controller,
    required this.languageDetails,
    this.isActive = false,
    this.text
  });
}

class CodeCrafterDemoKey {
  final bool indentLineStatus, lineWrap, enableFolding, isDark;
  final String theme, fontFamily;

  CodeCrafterDemoKey({
    required this.indentLineStatus,
    required this.lineWrap,
    required this.enableFolding,
    required this.theme,
    required this.fontFamily,
    required this.isDark,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
      other is CodeCrafterDemoKey &&
      runtimeType == other.runtimeType &&
      indentLineStatus == other.indentLineStatus &&
      lineWrap == other.lineWrap &&
      enableFolding == other.enableFolding &&
      theme == other.theme &&
      fontFamily == other.fontFamily &&
      isDark == other.isDark;
  }

  @override
  int get hashCode => Object.hash(
    indentLineStatus,
    lineWrap,
    enableFolding,
    theme,
    fontFamily,
    isDark,
  );
}