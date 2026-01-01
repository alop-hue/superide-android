import 'dart:convert';
import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../terminal/terminal.dart';
import '../utils/constants.dart';
import '../utils/languages.dart';

Future<Directory> setupProjectDir() async {
  final target = Directory(projectDir);
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<Directory> setupFilesDir() async{
  final target = Directory(filesDir);
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }

  final currentFiles = File('${target.path}/.current_files.json');

  if (!await currentFiles.exists()) {
    await currentFiles.writeAsString(jsonEncode({}));
    return target;
  }

  try {
    final raw = await currentFiles.readAsString();
    if (raw.trim().isEmpty) {
      await currentFiles.writeAsString(jsonEncode({}));
      return target;
    }

    final Map<String, dynamic> data = jsonDecode(raw);
    final Map<String, String> cleaned = {};

    for (final entry in data.entries) {
      final filePath = '${target.path}/${entry.key}';
      if (await File(filePath).exists()) {
        cleaned[entry.key] = entry.value.toString();
      }
    }

    await currentFiles.writeAsString(
      jsonEncode(cleaned),
      flush: true,
    );
  } catch (e) {
    await currentFiles.writeAsString(jsonEncode({}), flush: true);
  }

  return target;
}

Future<Directory> setupTempDir() async {
  final target = Directory(templateDir);
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<File> setTempFile(String extension) async {
  final dir = await setupTempDir();
  File target;
  if (dir.existsSync()) {
    if(extension == 'html'){
      target = File('${dir.path}/index.html');  
    }
    else if(extension == 'css'){
      target = File('${dir.path}/style.css');  
    }
    else if(extension == 'js'){
      target = File('${dir.path}/script.js');  
    }
    else{
      target = File('${dir.path}/tempCode.$extension');
    }
    if (!target.existsSync() || (target.existsSync() && target.readAsStringSync().isEmpty)) {
      await target.create(recursive: true);
      await target.writeAsString(
        languages.firstWhere(
          (lang)=> lang.extension.contains(path.extension(target.path).replaceFirst(".", "")),
          orElse: () =>languages[0]
        ).helloWorld
      );
      return target;
    }
  }
  throw PathNotFoundException(dir.path, OSError("Failed to create the `Templates` directory."));
}

Future<void> cloneRepo(
  String location,
  String url,
  void Function(double progress) onProgress,
) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final process = await Process.start(
    '$binDir/git',
    ['clone', url],
    workingDirectory: location,
    environment: {
      'PATH': '$binDir:/bin:/usr/bin',
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );

  process.stderr
      .transform(SystemEncoding().decoder)
      .listen((line) {
        print(line);
    final match = RegExp(r'Receiving objects:\s+(\d+)%')
        .firstMatch(line);

    if (match != null) {
      final percent = double.parse(match.group(1)!);
      onProgress(percent / 100);
    }
  });

  await process.exitCode;
}

Future<void> initRepo(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["init"],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
  
  await Process.run(
    "$binDir/git",
    ["config", "--local", "user.name", "VSdroid user"],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
  
  await Process.run(
    "$binDir/git",
    ["config", "--local", "user.email", "vsdroid@local"],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
}

Future<ProcessResult> getRepoStatus(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["status", "--porcelain=v1", "-uall"],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
}

Future<void> stageChange(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["add", fileName],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
}

Future<void> stageAll(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["add", "--all"],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
}

Future<void> unstageChange(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["restore", "--staged", fileName],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
}

Future<void> unstageAll(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["restore", "--staged", "."],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath
    }
  );
}

Future<ProcessResult> gitCommit(String workspacePath, String message, {bool all = false, bool amend = false}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['commit'];
  if (amend) args.add('--amend');
  if (all) args.add('-a');
  args.addAll(['-m', message]);

  final result = await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath,
    },
  );

  return result;
}

Future<List<CommitNode>> getGraph(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["log", "--all", "--pretty=format:%H%x01%P%x01%an%x01%s"],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath,
    },
  );
  
  final List<CommitNode> commits = [];
  final lines = result.stdout.toString().split('\n');
  
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    
    final parts = line.split('\x01');
    if (parts.length >= 4) {
      final hash = parts[0];
      final parentHashes = parts[1].isEmpty ? <String>[] : parts[1].split(' ');
      final author = parts[2];
      final message = parts[3];
      
      commits.add(CommitNode(
        hash: hash,
        parents: parentHashes,
        author: author,
        message: message,
      ));
    }
  }
  
  return commits;
}

Future<void> gitRestoreFile(String fileName, String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["restore", fileName],
    workingDirectory: workspacePath,
    environment: {
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'LD_LIBRARY_PATH': "$sharedPath:$libDir",
      'VSDROID_SHARED_PATH': sharedPath,
    },
  );
}

String extractRepoName(String url) {
  url = url.replaceFirst(RegExp(r'^(https?://|git@)'), '');
  final parts = url.split(RegExp(r'[:/]'));
  if (parts.isEmpty) return '';
  String repoName = parts.last;
  if (repoName.endsWith('.git')) {
    repoName = repoName.substring(0, repoName.length - 4);
  }
  
  return repoName;
}

Future<File?> pickFile() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
  );

  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.first;

  if (picked.path == null && picked.bytes == null) {
    return null;
  }

  final projectDir = await setupFilesDir();
  final currentFiles = File('${projectDir.path}/.current_files.json');

  Map<String, String> fileMap = {};

  if (currentFiles.existsSync() && currentFiles.lengthSync() > 0) {
    fileMap = Map<String, String>.from(
      jsonDecode(currentFiles.readAsStringSync()),
    );
  }

  if (picked.identifier != null) {
    fileMap[picked.name] = picked.identifier!;
  }

  await currentFiles.writeAsString(
    jsonEncode(fileMap),
    flush: true,
  );

  final targetFile = File('${projectDir.path}/${picked.name}');

  if (picked.bytes != null) {
    await targetFile.writeAsBytes(picked.bytes!, flush: true);
  } else {
    final tempFile = File(picked.path!);
    await tempFile.copy(targetFile.path);
  }

  return targetFile;
}


Future<Directory?> pickDir() async {
  const MethodChannel saf = MethodChannel('vsdroid/saf');
  final String? treeUri =
      await saf.invokeMethod<String>('pickSafDir');

  if (treeUri == null) return null;

  final projectPath = await saf.invokeMethod<String>(
    'cloneSafDir',
    {'uri': treeUri},
  );
  if(projectPath == null) return null;
  return Directory(projectPath);
}


Future<String?> selectDir({String? dialogeTitle, String? initialDirectory, Uint8List? bytes}) async{
  return await FilePicker.platform.saveFile(
    dialogTitle: dialogeTitle,
    initialDirectory: initialDirectory,
    bytes: bytes
  );
}

Future<File?> createFile(String filename, String dirPath, BuildContext context) async {
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

Future<String> getCodeForgeConfig() async{
  final prefs = await SharedPreferences.getInstance();
  final config = prefs.getString('CodeForgeConfig');
  return config ?? 
    '{"indentLineStatus":true, "lineWrap":false, "enableFolding":true, "theme":"vs2015", "fontFamily": "jetBrainsMono", "isAIEnabled" : true, "manualCompletion": true, "autoSave": true}';
}

Future<String> getAiConfig() async{
  final prefs = await SharedPreferences.getInstance();
  final config = prefs.getString('aiConfig');
  return config ?? '{}';
}

Future<String> getModelSelected() async{
  final prefs = await SharedPreferences.getInstance();
  final model = prefs.getString('modelSelected');
  return model ?? '{}';
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

void runCode(BuildContext context, String compileCommand, String runCommand, String rootDir){
  Navigator.of(context).push(PageRouteBuilder(pageBuilder: (context, animation, scondaryAnimation)=>
    SetupTerminal(
      projectDir: rootDir,
      args: [
        "-c",
        "$compileCommand && $runCommand"
      ]
    ),
    transitionsBuilder: (context ,animation, secondaryAnimation, child){
      return SizeTransition(sizeFactor: animation,child: child);
    }
  ));
}

Future<LspConfig?> startLspServer({
    required String ext,
    required String? executable,
    required List<String> args,
    required String workspacePath,
    required String langId,
    Map<String, String>? environment
  }) async{
  if(executable == null) return null;
    try {
      final String sharedPath = await NativeChannel.getLibraryPath();
      final String runtimeDir = runtimesDir;
      final config = await LspStdioConfig.start(
        executable: executable,
        args: ((){
          if (ext == 'ts' || ext == 'js') {
            return [
              "$runtimeDir/node/lib/node_modules/typescript-language-server/lib/cli.mjs",
              ...args,
            ];
          } else if(ext == 'c' || ext == 'cpp' || ext == 'cc' || ext == 'c++'){
            return null;
          }
          else if(ext == 'java'){
            return [
              '-Dlog.protocol=true',
              '-Dlog.level=ALL',
              "-jar",
              "$extensionDir/JDT-LS/plugins/org.eclipse.equinox.launcher_1.7.0.v20250519-0528.jar",
              "-configuration",
              "$extensionDir/JDT-LS/config_linux_arm",
              "-data",
              workspacePath,
              ...args
            ];
          }

          return [extensions.singleWhere((item) => item.fileExtension == ext).serverFile, ...args];
        })(),
        environment: {
          ...environment ?? {},
          'VSDROID_SHARED_PATH': sharedPath,
          'LD_LIBRARY_PATH': '$runtimeDir/clang:$runtimeDir/node/lib:$sharedPath:${Platform.environment['LD_LIBRARY_PATH'] ?? ''}',
          'JAVA_HOME': '$runtimeDir/java-17-openjdk',
        },
        workspacePath: workspacePath,
        languageId: langId,
      );
      
      return config;
    } catch (e) {
      debugPrint('LSP Initialization failed: $e');
    }
  return null;
}

class Extractor {
  static Future<void> extractZip(
    BuildContext context,
    String inputPath,
    String outputDir, {
    String? archiveName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final progressNotifier = ValueNotifier<double>(0.0);

    final snackbar = SnackBar(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(days: 1),
      content: ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (context, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Extracting${archiveName == null ? "" : " "}${archiveName ?? "..."}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 6),
            LinearPercentIndicator(
              percent: value.clamp(0.0, 1.0),
              progressColor: Colors.greenAccent,
              backgroundColor: Colors.white24,
              barRadius: const Radius.circular(20),
              lineHeight: 8,
              trailing: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  "${(value * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );

    messenger.showSnackBar(snackbar);

    try {
      await ZipFile.extractToDirectory(
        zipFile: File(inputPath),
        destinationDir: Directory(outputDir),
        onExtracting: (entry, rawProgress) {
          progressNotifier.value = rawProgress / 100.0;
          return ZipFileOperation.includeItem;
        },
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('🎉 Extraction complete!')),
      );
    }
    catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('❌ Extraction failed')),
      );
      debugPrint('Extraction error: $e');
    }
  }
}

class NativeChannel {
  static const MethodChannel _channel = MethodChannel('com.vsdroid');

  static Future<String> getLibraryPath() async {
    try {
      final String result = await _channel.invokeMethod('getLibraryPath');
      return result;
    } on PlatformException catch (e) {
      return "Failed to load library: ${e.message}";
    }
  }
}

class ActiveEditors {
  final File filePath;
  final CodeForgeController controller;
  final Language languageDetails;
  final UndoRedoController undoRedoController;
  bool isActive;


  ActiveEditors({
    required this.filePath,
    required this.controller,
    required this.languageDetails,
    required this.undoRedoController,
    required this.isActive,
  });
}

class CodeForgeDemoKey {
  final bool indentLineStatus, lineWrap, enableFolding, isDark;
  final String theme, fontFamily;

  CodeForgeDemoKey({
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
      other is CodeForgeDemoKey &&
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

class AIConversation{
  final String userRequest;
  String? modelResponse;

  AIConversation(this.userRequest, this.modelResponse);

  AIConversation copyWith({String? modelResponse}) =>  AIConversation(userRequest, modelResponse);
}

class CommitNode {
  final String hash;
  final List<String> parents;
  final String author;
  final String message;
  int lane;

  CommitNode({
    required this.hash,
    required this.parents,
    required this.author,
    required this.message,
    this.lane = -1,
  });
}

void assignLanes(List<CommitNode> commits) {
  final Map<String, int> activeLanes = {};
  int nextLane = 0;

  for (final commit in commits) {
    if (activeLanes.containsKey(commit.hash)) {
      commit.lane = activeLanes[commit.hash]!;
    } else {
      commit.lane = nextLane++;
    }

    for (final parent in commit.parents) {
      activeLanes[parent] = commit.lane;
    }

    activeLanes.remove(commit.hash);
  }
}

Map<String, (String, Color)> gitFileStatus = {
  "M" : ('M',  Color(0xffaf9672)),
  "D" : ('D',  Colors.red[300]!),
  "UU" : ('C', Colors.red[300]!),
  "??" : ('U', Colors.green[700]!),
  "A" : ('U', Colors.green[700]!),
};