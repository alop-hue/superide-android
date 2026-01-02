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

Map<String, String> gitEnvs(String sharedPath) => {
  'PATH': '$binDir:/bin:/usr/bin',
  'GIT_EXEC_PATH': '$binDir/git-core',
  'GIT_SSL_CAINFO': '$certDir/cacert.pem',
  'LD_LIBRARY_PATH': "$sharedPath:$libDir",
  'VSDROID_SHARED_PATH': sharedPath
};

Future<void> cloneRepo(
  String location,
  String url,
  void Function(double progress) onProgress,
) async {
  final sharedPath = await NativeChannel.getLibraryPath();

  final process = await Process.start(
    '$binDir/git',
    ['clone', '--progress', url],
    workingDirectory: location,
    environment: gitEnvs(sharedPath),
  );

  final progressRegex = RegExp(
    r'(Receiving objects|Resolving deltas|Compressing objects):\s+(\d+)%'
  );

  process.stderr.listen((data) {
    final text = String.fromCharCodes(data);

    final match = progressRegex.firstMatch(text);
    if (match != null) {
      final percent = double.parse(match.group(2)!);
      onProgress(percent / 100);
    }
  });

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('git clone failed with exit code $exitCode');
  }
}


Future<void> initRepo(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["init"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
  );
  
  await Process.run(
    "$binDir/git",
    ["config", "--local", "user.name", "VSdroid user"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
  );
  
  await Process.run(
    "$binDir/git",
    ["config", "--local", "user.email", "vsdroid@local"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
  );
}

Future<ProcessResult> getRepoStatus(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["status", "--porcelain=v1", "-uall"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
  );
}

Future<void> stageChange(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["add", fileName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
  );
}

Future<void> stageAll(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["add", "--all"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
  );
}

Future<void> unstageChange(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final env = gitEnvs(sharedPath);

  final hasHead = await _hasInitialCommit(workspacePath, env);

  final args = hasHead
      ? ["restore", "--staged", fileName]
      : ["reset", fileName];

  await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: env,
  );
}


Future<void> unstageAll(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final env = gitEnvs(sharedPath);

  final hasHead = await _hasInitialCommit(workspacePath, env);

  final args = hasHead
      ? ["restore", "--staged", "."]
      : ["reset", "."];

  await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: env,
  );
}


Future<bool> _hasInitialCommit(
  String workspacePath,
  Map<String, String> env,
) async {
  final result = await Process.run(
    "$binDir/git",
    ["rev-parse", "--verify", "HEAD"],
    workingDirectory: workspacePath,
    environment: env,
  );

  return result.exitCode == 0;
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
    environment: gitEnvs(sharedPath)
  );

  return result;
}

Future<List<CommitNode>> getGraph(String workspacePath) async{
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["log", "--all", "--pretty=format:%H%x01%P%x01%an%x01%s"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath)
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
    environment: gitEnvs(sharedPath)
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

  static Future<void> extractZipBackground(
    String inputPath,
    String outputDir, {
    String? archiveName,
    Function(double)? onProgress,
  }) async {
    try {
      await ZipFile.extractToDirectory(
        zipFile: File(inputPath),
        destinationDir: Directory(outputDir),
        onExtracting: (entry, rawProgress) {
          onProgress?.call(rawProgress);
          return ZipFileOperation.includeItem;
        },
      );
    } catch (e) {
      debugPrint('Extraction error for $archiveName: $e');
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
  int? childLane; // Lane of the child that points to this commit
  bool isMerge; // Has multiple parents
  bool isBranchStart; // First commit on a new branch

  CommitNode({
    required this.hash,
    required this.parents,
    required this.author,
    required this.message,
    this.lane = -1,
    this.childLane,
    this.isMerge = false,
    this.isBranchStart = false,
  });
}

/// Represents a connection line in the git graph
class GraphLine {
  final int fromLane;
  final int toLane;
  final int colorIndex;
  final bool isPassThrough; // Line just passes through this row
  
  GraphLine({
    required this.fromLane,
    required this.toLane,
    required this.colorIndex,
    this.isPassThrough = false,
  });
}

/// Stores lane information for each commit row
class CommitRowInfo {
  final CommitNode commit;
  final List<GraphLine> lines;
  final int commitLane;
  final int colorIndex;
  
  CommitRowInfo({
    required this.commit,
    required this.lines,
    required this.commitLane,
    required this.colorIndex,
  });
}

/// VSCode-style lane assignment that properly handles merges and branches
/// This does a two-pass approach:
/// 1. First pass: Scan forward to find where each commit appears (to know branch origins)
/// 2. Second pass: Build the graph with proper lane assignments
List<CommitRowInfo> assignVSCodeLanes(List<CommitNode> commits) {
  if (commits.isEmpty) return [];
  
  final List<CommitRowInfo> rowInfos = [];
  
  // Build a map of hash -> index for quick lookup
  final Map<String, int> hashToIndex = {};
  for (int i = 0; i < commits.length; i++) {
    hashToIndex[commits[i].hash] = i;
  }
  
  // Track active lanes: lane -> (expectedHash, colorIndex, originIndex)
  // originIndex is where this lane started (for drawing pass-through from top)
  final Map<int, (String, int)> activeLanes = {};
  final Map<String, int> hashToLane = {};
  final Map<String, int> hashToColor = {};
  int nextColorIndex = 0;
  
  // Find the next available lane (smallest non-negative integer not in use)
  int findAvailableLane(int preferredLane) {
    if (!activeLanes.containsKey(preferredLane)) {
      return preferredLane;
    }
    int lane = 0;
    while (activeLanes.containsKey(lane)) {
      lane++;
    }
    return lane;
  }
  
  for (int i = 0; i < commits.length; i++) {
    final commit = commits[i];
    commit.isMerge = commit.parents.length > 1;
    
    final List<GraphLine> lines = [];
    int commitLane;
    int colorIndex;
    
    // Check if any active lane is expecting this commit
    int? expectedLane;
    int? expectedColor;
    for (final entry in activeLanes.entries) {
      if (entry.value.$1 == commit.hash) {
        expectedLane = entry.key;
        expectedColor = entry.value.$2;
        break;
      }
    }
    
    if (expectedLane != null) {
      // This commit was expected - it's continuing a branch or is a merge target
      commitLane = expectedLane;
      colorIndex = expectedColor!;
      // Remove from active since we've reached it
      activeLanes.remove(expectedLane);
    } else {
      // New branch starting (first commit or branch head not yet seen)
      commitLane = findAvailableLane(0);
      colorIndex = nextColorIndex++;
      commit.isBranchStart = i > 0;
    }
    
    commit.lane = commitLane;
    hashToLane[commit.hash] = commitLane;
    hashToColor[commit.hash] = colorIndex;
    
    // Draw pass-through lines for all OTHER active lanes
    for (final entry in activeLanes.entries) {
      lines.add(GraphLine(
        fromLane: entry.key,
        toLane: entry.key,
        colorIndex: entry.value.$2,
        isPassThrough: true,
      ));
    }
    
    // Process parents and add connecting lines
    for (int p = 0; p < commit.parents.length; p++) {
      final parentHash = commit.parents[p];
      
      // Check if this parent is already being tracked in a lane
      int? existingParentLane;
      int? existingParentColor;
      for (final entry in activeLanes.entries) {
        if (entry.value.$1 == parentHash) {
          existingParentLane = entry.key;
          existingParentColor = entry.value.$2;
          break;
        }
      }
      
      int parentLane;
      int parentColor;
      
      if (existingParentLane != null) {
        // Parent is already tracked - draw merge line to that lane
        parentLane = existingParentLane;
        parentColor = existingParentColor!;
        // Draw connecting line from commit to existing parent lane
        lines.add(GraphLine(
          fromLane: commitLane,
          toLane: parentLane,
          colorIndex: parentColor,
        ));
      } else {
        if (p == 0) {
          // First parent continues on the same lane
          parentLane = commitLane;
          parentColor = colorIndex;
        } else {
          // Additional parent (merge) - assign a new lane
          parentLane = findAvailableLane(commitLane + 1);
          parentColor = nextColorIndex++;
        }
        
        // Add this parent to active lanes
        activeLanes[parentLane] = (parentHash, parentColor);
        hashToColor[parentHash] = parentColor;
        
        // Draw connecting line
        lines.add(GraphLine(
          fromLane: commitLane,
          toLane: parentLane,
          colorIndex: parentColor,
        ));
      }
    }
    
    rowInfos.add(CommitRowInfo(
      commit: commit,
      lines: lines,
      commitLane: commitLane,
      colorIndex: colorIndex,
    ));
  }
  
  return rowInfos;
}

Map<String, (String, Color)> gitFileStatus = {
  "M" : ('M',  Color(0xffaf9672)),
  "D" : ('D',  Colors.red[300]!),
  "UU" : ('C', Colors.red[300]!),
  "??" : ('U', Colors.green[700]!),
  "A" : ('U', Colors.green[700]!),
};