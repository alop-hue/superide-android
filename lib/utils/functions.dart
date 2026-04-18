import 'dart:convert';
import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../terminal/terminal.dart';
import '../utils/constants.dart';
import '../utils/languages.dart';

const Set<String> supportedImageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.bmp',
  '.wbmp',
  '.ico',
  '.tif',
  '.tiff',
  '.heic',
  '.heif',
  '.avif',
};

const Set<String> supportedSvgExtensions = {
  '.svg',
  '.svgz',
};

bool isImageFilePath(String filePath) {
  return supportedImageExtensions.contains(
    path.extension(filePath).toLowerCase(),
  );
}

bool isPdfFilePath(String filePath) {
  return path.extension(filePath).toLowerCase() == '.pdf';
}

bool isSvgFilePath(String filePath) {
  return supportedSvgExtensions.contains(
    path.extension(filePath).toLowerCase(),
  );
}

bool isPreviewFilePath(String filePath) {
  return
      isImageFilePath(filePath) ||
      isSvgFilePath(filePath) ||
      isPdfFilePath(filePath);
}

Future<Directory> setupProjectDir() async {
  final target = Directory(projectDir);
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<Directory> setupTempDir() async {
  final target = Directory(tempDir);
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<Directory> setupFilesDir() async {
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

    await currentFiles.writeAsString(jsonEncode(cleaned), flush: true);
  } catch (e) {
    await currentFiles.writeAsString(jsonEncode({}), flush: true);
  }

  return target;
}

Future<Directory> setupTemplateDir() async {
  final target = Directory(templateDir);
  if (!target.existsSync()) {
    await target.create(recursive: true);
  }
  return target;
}

Future<File> setTempFile(String extension) async {
  final dir = await setupTemplateDir();

  File target;
  if (extension == 'html') {
    target = File('${dir.path}/index.html');
  } else if (extension == 'css') {
    target = File('${dir.path}/style.css');
  } else if (extension == 'js') {
    target = File('${dir.path}/script.js');
  } else {
    target = File('${dir.path}/tempCode.$extension');
  }

  if (!target.existsSync() || target.readAsStringSync().isEmpty) {
    await target.create(recursive: true);
    await target.writeAsString(
      languages
          .firstWhere(
            (lang) => lang.extension.contains(
              path.extension(target.path).replaceFirst(".", ""),
            ),
            orElse: () => languages[0],
          )
          .helloWorld,
    );
  }

  return target;
}

Map<String, String> gitEnvs(String sharedPath) => {
  'PATH': '$binDir:/bin:/usr/bin',
  'HOME': homeDir,
  'GIT_EXEC_PATH': '$binDir/git-core',
  'GIT_SSL_CAINFO': '$certDir/cacert.pem',
  'LD_LIBRARY_PATH': "$sharedPath:$libDir",
  'ROXUM_SHARED_PATH': sharedPath,
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
    r'(Receiving objects|Resolving deltas|Compressing objects):\s+(\d+)%',
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

Future<void> initRepo(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["init"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );

  await Process.run(
    "$binDir/git",
    ["config", "--local", "user.name", "Roxum user"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );

  await Process.run(
    "$binDir/git",
    ["config", "--local", "user.email", "roxum@local"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );

  await createGitignoreIfNeeded(workspacePath);
}

Future<void> createGitignoreIfNeeded(String workspacePath) async {
  final gitignoreFile = File('$workspacePath/.gitignore');
  final patterns = _getGitignorePatterns();

  if (await gitignoreFile.exists()) {
    final existingContent = await gitignoreFile.readAsString();
    final existingLines = existingContent
        .split('\n')
        .map((e) => e.trim())
        .toSet();

    final patternsToAdd = <String>[];
    for (final pattern in patterns) {
      final trimmedPattern = pattern.trim();
      if (trimmedPattern.isNotEmpty &&
          !trimmedPattern.startsWith('#') &&
          !existingLines.contains(trimmedPattern)) {
        patternsToAdd.add(pattern);
      }
    }

    if (patternsToAdd.isNotEmpty) {
      await gitignoreFile.writeAsString(
        '$existingContent\n\n# Auto-added by Roxum\n${patternsToAdd.join('\n')}\n',
        mode: FileMode.append,
      );
    }
  } else {
    await gitignoreFile.writeAsString('${patterns.join('\n')}\n');
  }
}

List<String> _getGitignorePatterns() {
  return [
    '# Roxum and Editor files',
    '.vscode/',
    '.idea/',
    '*.swp',
    '*.swo',
    '*~',
    '.DS_Store',
    '',
    '# Language Server Protocol (LSP) cache directories',
    '.ccls-cache/',
    'jdt.ls-java-project',
    '.clangd/',
    '.cache/',
    'compile_commands.json',
    '__pycache__/',
    '*.pyc',
    '.mypy_cache/',
    '.ruff_cache/',
    '.pytest_cache/',
    'pyrightconfig.json',
    '*.jdt.ls/',
    '.settings/',
    '',
    '# Dependencies',
    'node_modules/',
    '.pnpm-store/',
    '.npm/',
    '.yarn/',
    '.venv/',
    'venv/',
    'env/',
    'ENV/',
    '',
    '# Flutter / Dart',
    '.dart_tool/',
    '.packages',
    'pubspec.lock',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    '.metadata',
    '',
    '# Java / Android',
    'bin/',
    '.classpath',
    '.project',
    '.factorypath',
    '*.class',
    '.gradle/',
    'local.properties',
    '.externalNativeBuild/',
    '.cxx/',
    '',
    '# Node / TypeScript',
    'tsconfig.tsbuildinfo',
    '.eslintcache',
    '*.tsbuildinfo',
    '',
    '# Build outputs',
    'build/',
    'dist/',
    'out/',
    'target/',
    '*.o',
    '*.a',
    '*.so',
    '*.dylib',
    '*.dll',
    '*.exe',
    '*.app',
    '*.apk',
    '*.aab',
    '*.ipa',
    '*.so.*',
    '*.dylib.*',
    '',
    '# Logs and databases',
    '*.log',
    '*.sql',
    '*.sqlite',
    '*.db',
    '',
    '# Environment files',
    '.env',
    '.env.*',
    '',
    '# Temporary files',
    '*.tmp',
    '*.temp',
    '*.bak',
    '*.backup',
    '',
    '# Coverage reports',
    'coverage/',
    '.coverage',
    'htmlcov/',
    '',
    '# Package files',
    '*.tar.gz',
    '*.zip',
    '*.rar',
    '*.7z',
    '',
    '# OS files',
    '*.iml',
    'Thumbs.db',
    'Desktop.ini',
    '.Spotlight-V100',
    '.Trashes',
    '',
    '# Shell configuration',
    '.bashrc',
  ];
}

Future<ProcessResult> getRepoStatus(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["status", "--porcelain=v1", "-uall"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<void> stageChange(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["add", fileName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<void> stageAll(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["add", "--all"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
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

  final args = hasHead ? ["restore", "--staged", "."] : ["reset", "."];

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

Future<ProcessResult> gitCommit(
  String workspacePath,
  String message, {
  bool all = false,
  bool amend = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['commit'];
  if (amend) args.add('--amend');
  if (all) args.add('-a');
  args.addAll(['-m', message]);

  final result = await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );

  return result;
}

Future<List<CommitNode>> getGraph(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["log", "--all", "--pretty=format:%H%x01%P%x01%an%x01%s"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
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

      commits.add(
        CommitNode(
          hash: hash,
          parents: parentHashes,
          author: author,
          message: message,
        ),
      );
    }
  }

  return commits;
}

Future<void> gitRestoreFile(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await Process.run(
    "$binDir/git",
    ["restore", fileName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

class GitDiffResult {
  final String diffText;
  final List<(int startLine, int endLine)> addedRanges;
  final List<({int afterLine, String content})> removedRanges;

  GitDiffResult({
    required this.diffText,
    required this.addedRanges,
    required this.removedRanges,
  });
}

Future<GitDiffResult> getGitDiff(String fileName, String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["diff", "--function-context", fileName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );

  final diffTextOriginal = result.stdout as String;
  final addedRanges = <(int, int)>[];
  final removedRanges = <({int afterLine, String content})>[];

  final lines = diffTextOriginal.split('\n');
  final filteredLines = lines
      .where(
        (line) =>
            !line.startsWith('diff --git') &&
            !line.startsWith('index ') &&
            !line.startsWith('--- ') &&
            !line.startsWith('+++ '),
      )
      .toList();

  final visibleLines = <String>[];

  int? currentAddedStart;
  int? currentRemovedAfterLine;
  final removedContent = StringBuffer();

  void flushAdded(int endExclusive) {
    if (currentAddedStart == null) return;
    addedRanges.add((currentAddedStart!, endExclusive - 1));
    currentAddedStart = null;
  }

  void flushRemoved() {
    if (currentRemovedAfterLine == null) return;
    removedRanges.add((
      afterLine: currentRemovedAfterLine!,
      content: removedContent.toString(),
    ));
    currentRemovedAfterLine = null;
    removedContent.clear();
  }

  for (final line in filteredLines) {
    final isAdded = line.startsWith('+');
    final isRemoved = line.startsWith('-');

    if (isRemoved) {
      flushAdded(visibleLines.length);
      currentRemovedAfterLine ??= visibleLines.isEmpty
          ? 0
          : visibleLines.length - 1;
      if (removedContent.isNotEmpty) {
        removedContent.write('\n');
      }
      removedContent.write(line.length > 1 ? line.substring(1) : '');
      continue;
    }

    flushRemoved();

    if (isAdded) {
      currentAddedStart ??= visibleLines.length;
      visibleLines.add(line);
      continue;
    }

    flushAdded(visibleLines.length);
    visibleLines.add(line);
  }

  flushAdded(visibleLines.length);
  flushRemoved();

  final diffText = visibleLines.join('\n');

  return GitDiffResult(
    diffText: diffText,
    addedRanges: addedRanges,
    removedRanges: removedRanges,
  );
}

Future<ProcessResult> gitPush(
  String workspacePath, {
  String? remote,
  String? branch,
  bool setUpstream = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['push'];
  if (setUpstream) args.add('-u');
  if (remote != null) args.add(remote);
  if (branch != null) args.add(branch);
  final result = await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  return result;
}

Future<ProcessResult> gitPull(
  String workspacePath, {
  String? remote,
  String? branch,
  bool rebase = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['pull'];
  if (rebase) args.add('--rebase');
  if (remote != null) args.add(remote);
  if (branch != null) args.add(branch);
  final result = await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  return result;
}

Future<ProcessResult> gitFetch(
  String workspacePath, {
  String? remote,
  bool all = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['fetch'];
  if (all) args.add('--all');
  if (remote != null && !all) args.add(remote);
  final result = await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  return result;
}

Future<ProcessResult> gitSync(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final pullResult = await Process.run(
    "$binDir/git",
    ["pull", "--rebase"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (pullResult.exitCode != 0) return pullResult;

  final pushResult = await Process.run(
    "$binDir/git",
    ["push"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  return pushResult;
}

Future<List<String>> gitListBranches(
  String workspacePath, {
  bool remote = false,
  bool all = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['branch'];
  if (all) {
    args.add('-a');
  } else if (remote) {
    args.add('-r');
  }
  final result = await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return [];
  return (result.stdout as String)
      .split('\n')
      .map((b) => b.replaceFirst('*', '').trim())
      .where((b) => b.isNotEmpty)
      .toList();
}

Future<String?> gitCurrentBranch(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["branch", "--show-current"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return null;
  final branch = (result.stdout as String).trim();

  if (branch.isEmpty) {
    final descResult = await Process.run(
      "$binDir/git",
      ["describe", "--tags", "--exact-match", "HEAD"],
      workingDirectory: workspacePath,
      environment: gitEnvs(sharedPath),
    );
    if (descResult.exitCode == 0) {
      return (descResult.stdout as String).trim();
    }

    final refResult = await Process.run(
      "$binDir/git",
      ["rev-parse", "--short", "HEAD"],
      workingDirectory: workspacePath,
      environment: gitEnvs(sharedPath),
    );
    if (refResult.exitCode == 0) {
      return (refResult.stdout as String).trim();
    }
    return "HEAD";
  }

  return branch;
}

Future<ProcessResult> gitCreateBranch(
  String workspacePath,
  String branchName, {
  String? fromRef,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['checkout', '-b', branchName];
  if (fromRef != null) args.add(fromRef);
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitCheckoutBranch(
  String workspacePath,
  String branchName,
) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["checkout", branchName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitRenameBranch(
  String workspacePath,
  String oldName,
  String newName,
) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["branch", "-m", oldName, newName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitDeleteBranch(
  String workspacePath,
  String branchName, {
  bool force = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["branch", force ? "-D" : "-d", branchName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitDeleteRemoteBranch(
  String workspacePath,
  String branchName, {
  String remote = 'origin',
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["push", remote, "--delete", branchName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitMergeBranch(
  String workspacePath,
  String branchName, {
  bool noFf = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['merge'];
  if (noFf) args.add('--no-ff');
  args.add(branchName);
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitRebaseBranch(
  String workspacePath,
  String branchName,
) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["rebase", branchName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitPublishBranch(
  String workspacePath,
  String branchName, {
  String remote = 'origin',
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["push", "-u", remote, branchName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<List<Map<String, String>>> gitListStashes(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["stash", "list", "--format=%gd%x01%s"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return [];
  final lines = (result.stdout as String)
      .split('\n')
      .where((l) => l.isNotEmpty);
  return lines.map((line) {
    final parts = line.split('\x01');
    return {
      'ref': parts.isNotEmpty ? parts[0] : '',
      'message': parts.length > 1 ? parts[1] : '',
    };
  }).toList();
}

Future<ProcessResult> gitStash(
  String workspacePath, {
  String? message,
  bool includeUntracked = false,
  bool stagedOnly = false,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['stash', 'push'];
  if (includeUntracked) args.add('--include-untracked');
  if (stagedOnly) args.add('--staged');
  if (message != null && message.isNotEmpty) {
    args.addAll(['-m', message]);
  }
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitStashApply(
  String workspacePath, {
  String? stashRef,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['stash', 'apply'];
  if (stashRef != null) args.add(stashRef);
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitStashPop(
  String workspacePath, {
  String? stashRef,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['stash', 'pop'];
  if (stashRef != null) args.add(stashRef);
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitStashDrop(
  String workspacePath, {
  String? stashRef,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['stash', 'drop'];
  if (stashRef != null) args.add(stashRef);
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitStashClear(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["stash", "clear"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<String> gitStashShow(String workspacePath, String stashRef) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["stash", "show", "-p", stashRef],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  return result.stdout as String;
}

Future<List<String>> gitListTags(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["tag", "-l"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return [];
  return (result.stdout as String)
      .split('\n')
      .where((t) => t.isNotEmpty)
      .toList();
}

Future<ProcessResult> gitCreateTag(
  String workspacePath,
  String tagName, {
  String? message,
  String? ref,
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final args = <String>['tag'];
  if (message != null && message.isNotEmpty) {
    args.addAll(['-a', tagName, '-m', message]);
  } else {
    args.add(tagName);
  }
  if (ref != null) args.add(ref);
  return await Process.run(
    "$binDir/git",
    args,
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitDeleteTag(String workspacePath, String tagName) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["tag", "-d", tagName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitDeleteRemoteTag(
  String workspacePath,
  String tagName, {
  String remote = 'origin',
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["push", remote, "--delete", "refs/tags/$tagName"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<ProcessResult> gitPushTag(
  String workspacePath,
  String tagName, {
  String remote = 'origin',
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["push", remote, tagName],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<List<String>> gitListRemotes(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["remote"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return [];
  return (result.stdout as String)
      .split('\n')
      .where((r) => r.isNotEmpty)
      .toList();
}

Future<String?> gitGetRemoteUrl(
  String workspacePath, {
  String remote = 'origin',
}) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["remote", "get-url", remote],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return null;
  return (result.stdout as String).trim();
}

Future<ProcessResult> gitAddRemote(
  String workspacePath,
  String name,
  String url,
) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  return await Process.run(
    "$binDir/git",
    ["remote", "add", name, url],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
}

Future<bool> hasRemote(String workspacePath) async {
  final remotes = await gitListRemotes(workspacePath);
  return remotes.isNotEmpty;
}

Future<int> getUnpushedCommitCount(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["rev-list", "--count", "@{u}..HEAD"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return 0;
  return int.tryParse((result.stdout as String).trim()) ?? 0;
}

Future<int> getUnpulledCommitCount(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  await gitFetch(workspacePath);
  final result = await Process.run(
    "$binDir/git",
    ["rev-list", "--count", "HEAD..@{u}"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  if (result.exitCode != 0) return 0;
  return int.tryParse((result.stdout as String).trim()) ?? 0;
}

Future<bool> hasUpstream(String workspacePath) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final result = await Process.run(
    "$binDir/git",
    ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
    workingDirectory: workspacePath,
    environment: gitEnvs(sharedPath),
  );
  return result.exitCode == 0;
}

Future<String> gitHubSignIn() async {
  final secureStorage = const FlutterSecureStorage();
  const clientId = "Ov23liYO7I8tsbftzDKc";
  const backEndHandler = "https://gihub-auth-handler.vercel.app";

  final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
    'client_id': clientId,
    'scope': 'repo read:user',
    'redirect_uri': 'roxum://oauth',
  });

  try {
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'roxum',
      options: const FlutterWebAuth2Options(),
    );

    final code = Uri.parse(result).queryParameters['code'];

    if (code == null || code.isEmpty) {
      return 'No authorization code received';
    }

    final response = await http
        .post(
          Uri.parse('$backEndHandler/github/oauth'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'code': code}),
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return http.Response('Backend connection timeout', 408);
          },
        );

    if (response.statusCode != 200) {
      return ('${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final accessToken = data['access_token'];

    if (accessToken == null || accessToken.isEmpty) {
      return 'No access token in backend response';
    }

    await secureStorage.write(key: 'github_access_token', value: accessToken);

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      await _configureGitIdentity(jsonDecode(response.body));
      await _configureGitCredentialHelper();
      await _approveGithubCredentials(accessToken);
    } catch (e) {
      debugPrint('Failed to load user info: $e');
    }

    return "success";
  } catch (e) {
    final err = e.toString();
    if (err.contains('PlatformException(CANCELED') ||
        err.toLowerCase().contains('user canceled')) {
      return 'Sign in was canceled';
    }
    return e.toString();
  }
}

String resolveGitEmail(Map<String, dynamic> user) {
  final email = user['email'];
  final login = user['login'];
  if (email != null && email.toString().isNotEmpty) {
    return email;
  }
  return '$login@users.noreply.github.com';
}

Future<void> _configureGitIdentity(Map<String, dynamic> user) async {
  final sharedPath = await NativeChannel.getLibraryPath();
  final name = user['name'] ?? user['login'];
  final email = resolveGitEmail(user);

  await Process.run("$binDir/git", [
    "config",
    "--global",
    "user.name",
    name,
  ], environment: gitEnvs(sharedPath));

  await Process.run("$binDir/git", [
    "config",
    "--global",
    "user.email",
    email,
  ], environment: gitEnvs(sharedPath));
}

Future<void> _configureGitCredentialHelper() async {
  final sharedPath = await NativeChannel.getLibraryPath();

  await Process.run("$binDir/git", [
    "config",
    "--global",
    "credential.helper",
    "store",
  ], environment: gitEnvs(sharedPath));
}

Future<void> _approveGithubCredentials(String token) async {
  final sharedPath = await NativeChannel.getLibraryPath();

  final process = await Process.start("$binDir/git", [
    "credential-store",
    "store",
  ], environment: gitEnvs(sharedPath));

  process.stdin.write(
    "protocol=https\n"
    "host=github.com\n"
    "username=oauth2\n"
    "password=$token\n\n",
  );

  await process.stdin.close();
  await process.exitCode;
}

Future<void> clearGitCredentials() async {
  final sharedPath = await NativeChannel.getLibraryPath();

  await Process.run(
    "$binDir/git",
    ["credential", "reject"],
    environment: gitEnvs(sharedPath),
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  final home = Directory(homeDir);
  final credsFile = File('${home.path}/.git-credentials');
  if (credsFile.existsSync()) {
    credsFile.deleteSync();
  }
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

  await currentFiles.writeAsString(jsonEncode(fileMap), flush: true);

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
  const MethodChannel saf = MethodChannel('roxum/saf');
  final String? treeUri = await saf.invokeMethod<String>('pickSafDir');

  if (treeUri == null) return null;

  final projectPath = await saf.invokeMethod<String>('cloneSafDir', {
    'uri': treeUri,
  });
  if (projectPath == null) return null;
  return Directory(projectPath);
}

Future<String?> selectDir({
  String? dialogeTitle,
  String? initialDirectory,
  Uint8List? bytes,
}) async {
  return await FilePicker.platform.saveFile(
    dialogTitle: dialogeTitle,
    initialDirectory: initialDirectory,
    bytes: bytes,
  );
}

Future<File?> createFile(
  String filename,
  String dirPath,
  BuildContext context,
) async {
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
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300),
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

Future<String> getRecent() async {
  final prefs = await SharedPreferences.getInstance();
  final recent = prefs.getString('recent');
  return recent ?? '[]';
}

const String copilotEnabledPrefKey = 'isCopilotEnabled';
const String copilotSignedPrefKey = 'isSignedCopilot';

Future<bool> ensureCopilotEnabledPrefInitialized() async {
  final prefs = await SharedPreferences.getInstance();
  final currentValue = prefs.getBool(copilotEnabledPrefKey);
  if (currentValue == null) {
    await prefs.setBool(copilotEnabledPrefKey, false);
    return false;
  }
  return currentValue;
}

Future<bool> ensureCopilotSignedPrefInitialized() async {
  final prefs = await SharedPreferences.getInstance();
  final currentValue = prefs.getBool(copilotSignedPrefKey);
  if (currentValue == null) {
    await prefs.setBool(copilotSignedPrefKey, false);
    return false;
  }
  return currentValue;
}

Future<bool> isCopilotSignedPref() async {
  final prefs = await SharedPreferences.getInstance();
  final currentValue = prefs.getBool(copilotSignedPrefKey);
  if (currentValue == null) {
    await prefs.setBool(copilotSignedPrefKey, false);
    return false;
  }
  return currentValue;
}

Future<void> setCopilotSignedPref(bool isSignedIn) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(copilotSignedPrefKey, isSignedIn);
}

Future<bool> isCopilotEnabledPref() async {
  final prefs = await SharedPreferences.getInstance();
  final currentValue = prefs.getBool(copilotEnabledPrefKey);
  if (currentValue == null) {
    await prefs.setBool(copilotEnabledPrefKey, false);
    return false;
  }
  return currentValue;
}

Future<void> setCopilotEnabledPref(bool isEnabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(copilotEnabledPrefKey, isEnabled);
}

Future<String> getAppTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final savedAppTheme = prefs.getString("savedAppTheme");
  return savedAppTheme ?? "dark";
}

Future<String> getCodeForgeConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final defaultConfig = {
    "indentLineStatus": true,
    "lineWrap": false,
    "enableFolding": true,
    "theme": "vs2015",
    "fontFamily": "jetBrainsMono",
    "terminalTheme": "xterm_classic",
    "terminalFontSize": 14.0,
    "isAIEnabled": true,
    "manualCompletion": true,
    "autoSave": true,
    "enableLSP": true,
    "LSPFeatureToggle": {},
  };
  final configString = prefs.getString('codeForgeConfig');
  if (configString == null) {
    return jsonEncode(defaultConfig);
  }
  try {
    final Map<String, dynamic> storedConfig = jsonDecode(configString);
    final mergedConfig = Map<String, dynamic>.from(defaultConfig)
      ..addAll(storedConfig);
    return jsonEncode(mergedConfig);
  } catch (e) {
    return jsonEncode(defaultConfig);
  }
}

Future<String> getAiConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final defaultConfig = {};
  final configString = prefs.getString('aiConfig');
  if (configString == null) {
    return jsonEncode(defaultConfig);
  }
  try {
    final Map<String, dynamic> storedConfig = jsonDecode(configString);
    final mergedConfig = Map<String, dynamic>.from(defaultConfig)
      ..addAll(storedConfig);
    return jsonEncode(mergedConfig);
  } catch (e) {
    return jsonEncode(defaultConfig);
  }
}

Future<String> getModelSelected() async {
  final prefs = await SharedPreferences.getInstance();
  final defaultConfig = {"code": "", "chat": ""};
  final configString = prefs.getString('modelSelected');
  if (configString == null) {
    return jsonEncode(defaultConfig);
  }
  try {
    final Map<String, dynamic> storedConfig = jsonDecode(configString);
    final mergedConfig = Map<String, dynamic>.from(defaultConfig)
      ..addAll(storedConfig);
    return jsonEncode(mergedConfig);
  } catch (e) {
    return jsonEncode(defaultConfig);
  }
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
    return {'error': e.toString()};
  }
}

void runCode(BuildContext context, String command, String rootDir) {
  try {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, scondaryAnimation) => SetupTerminal(
          projectDir: rootDir,
          args: ["-c", command],
          resetImeOnOpen: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SizeTransition(sizeFactor: animation, child: child);
        },
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Execution failed: ${e.toString()}")),
    );
    debugPrint(e.toString());
  }
}

String _resolveLspServerPath(String serverPath) {
  final normalized = serverPath
      .replaceAll('\$extensionDir', extensionDir)
      .replaceAll('\${extensionDir}', extensionDir);
  if (path.isAbsolute(normalized)) return normalized;
  return path.join(extensionDir, normalized);
}

String lspLanguageIdForExtension({
  required String ext,
  required String fallbackLanguageName,
}) {
  final normalizedExt = ext.toLowerCase().replaceFirst('.', '');

  switch (normalizedExt) {
    case 'c':
      return 'c';
    case 'cc':
    case 'cpp':
    case 'cxx':
    case 'c++':
    case 'h':
    case 'hh':
    case 'hpp':
    case 'hxx':
    case 'h++':
      return 'cpp';
    case 'js':
    case 'mjs':
    case 'cjs':
      return 'javascript';
    case 'jsx':
      return 'jsx';
    case 'ts':
      return 'typescript';
    case 'tsx':
      return 'tsx';
    case 'py':
    case 'pyi':
      return 'python';
    case 'sh':
    case 'bash':
    case 'zsh':
      return 'shellscript';
    default:
      break;
  }

  return fallbackLanguageName.trim().toLowerCase();
}

String lspLanguageIdForFile({
  required Language language,
  required String filePath,
}) {
  final ext = path.extension(filePath);
  return lspLanguageIdForExtension(
    ext: ext,
    fallbackLanguageName: language.name,
  );
}

String lspServerExtForExtension({required String ext}) {
  final normalizedExt = ext.toLowerCase().replaceFirst('.', '');
  switch (normalizedExt) {
    case 'jsx':
      return 'js';
    case 'tsx':
      return 'ts';
    default:
      return normalizedExt;
  }
}

String lspServerExtForFilePath(String filePath) {
  return lspServerExtForExtension(ext: path.extension(filePath));
}

bool isLspServerAvailable({
  required String ext,
  required String? executable,
  required List<String> args,
}) {
  if (executable == null || executable.isEmpty) return false;
  final executableExists = File(executable).existsSync();
  if (!executableExists) return false;

  final normalizedExt = ext.toLowerCase();

  if (normalizedExt == 'dart') {
    return File('$runtimesDir/dart/bin/dartaotruntime').existsSync() &&
      File('$runtimesDir/dart/bin/snapshots/analysis_server_aot.dart.snapshot')
        .existsSync();
  }

  if (normalizedExt == 'js' || normalizedExt == 'ts') {
    return File(
      '$runtimesDir/node/lib/node_modules/typescript-language-server/lib/cli.mjs',
    ).existsSync();
  }

  if (normalizedExt == 'java') {
    return File(
      '$extensionDir/JDT-LS/plugins/org.eclipse.equinox.launcher_1.7.100.v20251111-0406.jar',
    ).existsSync();
  }

  if (normalizedExt == 'c' ||
      normalizedExt == 'cpp' ||
      normalizedExt == 'cc' ||
      normalizedExt == 'c++') {
    return true;
  }

  String? serverFile;

  if (['py', 'sh', 'bash', 'zsh'].contains(normalizedExt)) {
    final matched = extensions.where(
      (item) => item.fileExtension.contains(normalizedExt),
    );
    if (matched.isNotEmpty && matched.first.serverFile.isNotEmpty) {
      serverFile = matched.first.serverFile.first;
    }
  } else if (normalizedExt == 'html') {
    final matched = extensions.where(
      (item) => item.fileExtension.any((ex) => ex == 'html'),
    );
    if (matched.isNotEmpty && matched.first.serverFile.isNotEmpty) {
      serverFile = matched.first.serverFile[0];
    }
  } else if (normalizedExt == 'css') {
    final matched = extensions.where(
      (item) => item.fileExtension.any((ex) => ex == 'css'),
    );
    if (matched.isNotEmpty && matched.first.serverFile.length > 1) {
      serverFile = matched.first.serverFile[1];
    }
  } else if (normalizedExt == 'json') {
    final matched = extensions.where(
      (item) => item.fileExtension.any((ex) => ex == 'json'),
    );
    if (matched.isNotEmpty && matched.first.serverFile.length > 2) {
      serverFile = matched.first.serverFile[2];
    }
  }

  if (serverFile != null && serverFile.isNotEmpty) {
    final resolved = _resolveLspServerPath(serverFile);
    return File(resolved).existsSync();
  }

  return true;
}

Future<LspConfig?> startLspServer({
  required String ext,
  required String? executable,
  required List<String> args,
  required String workspacePath,
  required String langId,
  Map<String, String>? environment,
  LspClientCapabilities? capabilities,
}) async {
  if (executable == null) return null;
  try {
    final String sharedPath = await NativeChannel.getLibraryPath();
    final String runtimeDir = runtimesDir;
    final String normalizedExt = ext.toLowerCase();
    final String dartRuntimeDir = '$runtimeDir/dart';
    final String dartRuntimeExecutable = '$dartRuntimeDir/bin/dart';
    final String dartAotRuntimeExecutable = '$dartRuntimeDir/bin/dartaotruntime';
    final String dartAnalysisServerSnapshot =
      '$dartRuntimeDir/bin/snapshots/analysis_server_aot.dart.snapshot';
    final String resolvedExecutable = normalizedExt == 'dart'
      ? dartAotRuntimeExecutable
        : executable;
    List<String> resolveServerArgs(String ext, List<String> args) {
      final normalizedExt = ext.toLowerCase();

      if (['sh', 'bash', 'zsh'].contains(normalizedExt)) {
        final matched = extensions.where(
          (item) => item.fileExtension.contains(normalizedExt),
        );
        if (matched.isNotEmpty && matched.first.serverFile.isNotEmpty) {
          return [matched.first.serverFile.first, ...args];
        }
      }

      if (normalizedExt == 'html') {
        final matched = extensions.where(
          (item) => item.fileExtension.any((ex) => ex == 'html'),
        );
        if (matched.isNotEmpty && matched.first.serverFile.isNotEmpty) {
          return [matched.first.serverFile[0], ...args];
        }
      }

      if (normalizedExt == 'css') {
        final matched = extensions.where(
          (item) => item.fileExtension.any((ex) => ex == 'css'),
        );
        if (matched.isNotEmpty && matched.first.serverFile.length > 1) {
          return [matched.first.serverFile[1], ...args];
        }
      }

      if (normalizedExt == 'json') {
        final matched = extensions.where(
          (item) => item.fileExtension.any((ex) => ex == 'json'),
        );
        if (matched.isNotEmpty && matched.first.serverFile.length > 2) {
          return [matched.first.serverFile[2], ...args];
        }
      }

      return args;
    }

    final resolvedArgs = (() {
      if (normalizedExt == 'ts' || normalizedExt == 'js') {
        return [
          "$runtimeDir/node/lib/node_modules/typescript-language-server/lib/cli.mjs",
          ...args,
        ];
      } else if (normalizedExt == 'py' || normalizedExt == 'pyi') {
        return ["server"];
      } else if (normalizedExt == 'c' ||
          normalizedExt == 'cpp' ||
          normalizedExt == 'cc' ||
          normalizedExt == 'c++' ||
          normalizedExt == 'h' ||
          normalizedExt == 'hpp' ||
          normalizedExt == 'hh' ||
          normalizedExt == 'hxx') {
        return [
          '--init={"cache":{"directory":"$tempDir/.ccls-cache"}, "clang":{"extraArgs":["-isystem","$runtimeDir/clang/sysroot/usr/include/c++/v1","-isystem","$runtimeDir/clang/sysroot/usr/include","-isystem","$runtimeDir/clang/lib/clang/21/include"],"resourceDir":"$runtimeDir/clang/lib/clang/21"}}',
        ];
      } else if (normalizedExt == 'dart') {
        return [
          dartAnalysisServerSnapshot,
          "--protocol=lsp",
          "--dart-sdk=$dartRuntimeDir",
        ];
      } else if (normalizedExt == 'java') {
        return [
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.level=ALL",
          "-Xmx1G",
          "--add-modules=ALL-SYSTEM",
          "--add-opens=java.base/java.util=ALL-UNNAMED",
          "--add-opens=java.base/java.lang=ALL-UNNAMED",
          "-jar",
          "$extensionDir/JDT-LS/plugins/org.eclipse.equinox.launcher_1.7.100.v20251111-0406.jar",
          "-configuration",
          "$extensionDir/JDT-LS/config_linux_arm",
          "-data",
          workspacePath,
          ...args,
        ];
      }
      return resolveServerArgs(ext, args);
    })();

    final resolvedEnvironment = {
      ...environment ?? {},
      'PATH': '$binDir:$runtimeDir/dart/bin:/bin:/usr/bin:${Platform.environment['PATH'] ?? ''}',
      'ROXUM_SHARED_PATH': sharedPath,
      'LD_LIBRARY_PATH': '${normalizedExt == 'dart' ? '$sharedPath:$libDir' : '$libDir:$runtimeDir/clang:$runtimeDir/node/lib:$sharedPath'}:${Platform.environment['LD_LIBRARY_PATH'] ?? ''}',
      if (normalizedExt == 'dart') 'DART_ROOT': dartRuntimeDir,
      'JAVA_HOME': '$runtimeDir/java-21-openjdk',
    };

    if (normalizedExt == 'dart') {
      try {
        final config = await LspStdioConfig.start(
          executable: resolvedExecutable,
          capabilities: capabilities ?? const LspClientCapabilities(),
          args: resolvedArgs,
          environment: resolvedEnvironment,
          workspacePath: workspacePath,
          languageId: langId.toLowerCase(),
        );
        debugPrint('Dart LSP started with AOT runtime executable: $resolvedExecutable');
        return config;
      } catch (primaryError) {
        debugPrint(
          'Primary Dart LSP startup failed with $resolvedExecutable: $primaryError',
        );
        final fallbackExecutable = dartRuntimeExecutable;
        final fallbackConfig = await LspStdioConfig.start(
          executable: fallbackExecutable,
          capabilities: capabilities ?? const LspClientCapabilities(),
          args: [
            'language-server',
            '--protocol=lsp',
            '--sdk=$dartRuntimeDir',
          ],
          environment: resolvedEnvironment,
          workspacePath: workspacePath,
          languageId: langId.toLowerCase(),
        );
        debugPrint('Dart LSP started with fallback executable: $fallbackExecutable');
        return fallbackConfig;
      }
    }

    final config = await LspStdioConfig.start(
      executable: resolvedExecutable,
      capabilities: capabilities ?? const LspClientCapabilities(),
      args: resolvedArgs,
      environment: resolvedEnvironment,
      workspacePath: workspacePath,
      languageId: langId.toLowerCase(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    } catch (e) {
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
  static const MethodChannel _channel = MethodChannel('com.roxum');
  static const MethodChannel _pfdMethodChannel = MethodChannel('roxum/pfd');
  static const EventChannel _pfdEventChannel = EventChannel('roxum/pfd_events');

  static Future<String> getLibraryPath() async {
    try {
      final String result = await _channel.invokeMethod('getLibraryPath');
      return result;
    } on PlatformException catch (e) {
      return "Failed to load library: ${e.message}";
    }
  }

  static Future<List<String>> consumePendingOpenFiles() async {
    try {
      final List<dynamic>? raw = await _channel.invokeMethod<List<dynamic>>(
        'consumePendingOpenFiles',
      );
      if (raw == null) return const [];
      return raw.map((item) => item.toString()).toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to read pending open files: ${e.message}');
      return const [];
    }
  }

  static Future<bool> isModuleInstalled(String moduleName) async {
    try {
      final bool? installed = await _pfdMethodChannel.invokeMethod<bool>(
        'isModuleInstalled',
        {'moduleName': moduleName},
      );
      return installed ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check module install state: ${e.message}');
      return false;
    }
  }

  static Future<void> installModule(String moduleName) async {
    await _pfdMethodChannel.invokeMethod(
      'installModule',
      {'moduleName': moduleName},
    );
  }

  static Future<void> uninstallModule(String moduleName) async {
    await _pfdMethodChannel.invokeMethod(
      'uninstallModule',
      {'moduleName': moduleName},
    );
  }

  static Future<void> copyModuleAssetToPath({
    required String moduleName,
    required String assetName,
    required String targetPath,
  }) async {
    await _pfdMethodChannel.invokeMethod(
      'copyModuleAssetToPath',
      {
        'moduleName': moduleName,
        'assetName': assetName,
        'targetPath': targetPath,
      },
    );
  }

  static Stream<Map<String, dynamic>> moduleInstallEvents() {
    return _pfdEventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    }).where((event) => event.isNotEmpty);
  }
}

class ActiveEditor {
  final File file;
  final CodeForgeController controller;
  final Language languageDetails;
  final UndoRedoController undoRedoController;
  final ScrollController hscroll, vscroll;
  bool isActive;
  FindController? findController;
  String? customTitle;

  ActiveEditor({
    required this.file,
    required this.controller,
    required this.languageDetails,
    required this.undoRedoController,
    required this.hscroll,
    required this.vscroll,
    required this.isActive,
    this.findController,
    this.customTitle,
  });

  Map<String, dynamic> toJsonMap() {
    final json = {
      "file": file.path,
      "text": controller.text,
      "extentOffset": controller.selection.extentOffset,
      "baseOffset": controller.selection.baseOffset,
      "customTitle": customTitle,
      "isActive": isActive,
      "lang": languageDetails.name,
    };

    return json;
  }

  Future<void> dispose() async {
    try {
      final lspConfig = controller.lspConfig;
      if (lspConfig != null) {
        await lspConfig.closeDocument(file.path);
      }
    } catch (e) {
      debugPrint('Error closing LSP document: $e');
    }
  }
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

class AIConversation {
  final String userRequest;
  String? modelResponse;

  AIConversation(this.userRequest, this.modelResponse);

  AIConversation copyWith({String? modelResponse}) =>
      AIConversation(userRequest, modelResponse);

  Map<String, dynamic> toJson() => {
    'userRequest': userRequest,
    'modelResponse': modelResponse,
  };

  factory AIConversation.fromJson(Map<String, dynamic> json) => AIConversation(
    json['userRequest'] as String,
    json['modelResponse'] as String?,
  );
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<AIConversation> conversations;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.conversations,
  });

  ChatSession copyWith({String? title, List<AIConversation>? conversations}) =>
      ChatSession(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        conversations: conversations ?? this.conversations,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'conversations': conversations.map((c) => c.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    conversations: (json['conversations'] as List)
        .map((c) => AIConversation.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}

class CommitNode {
  final String hash;
  final List<String> parents;
  final String author;
  final String message;
  int lane;
  int? childLane;
  bool isMerge;
  bool isBranchStart;

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

class GraphLine {
  final int fromLane;
  final int toLane;
  final int colorIndex;
  final bool isPassThrough;

  GraphLine({
    required this.fromLane,
    required this.toLane,
    required this.colorIndex,
    this.isPassThrough = false,
  });
}

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

List<CommitRowInfo> assignVSCodeLanes(List<CommitNode> commits) {
  if (commits.isEmpty) return [];

  final List<CommitRowInfo> rowInfos = [];

  final Map<String, int> hashToIndex = {};
  for (int i = 0; i < commits.length; i++) {
    hashToIndex[commits[i].hash] = i;
  }

  final Map<int, (String, int)> activeLanes = {};
  final Map<String, int> hashToLane = {};
  final Map<String, int> hashToColor = {};
  int nextColorIndex = 0;

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
      commitLane = expectedLane;
      colorIndex = expectedColor!;
      activeLanes.remove(expectedLane);
    } else {
      commitLane = findAvailableLane(0);
      colorIndex = nextColorIndex++;
      commit.isBranchStart = i > 0;
    }

    commit.lane = commitLane;
    hashToLane[commit.hash] = commitLane;
    hashToColor[commit.hash] = colorIndex;

    for (final entry in activeLanes.entries) {
      lines.add(
        GraphLine(
          fromLane: entry.key,
          toLane: entry.key,
          colorIndex: entry.value.$2,
          isPassThrough: true,
        ),
      );
    }

    for (int p = 0; p < commit.parents.length; p++) {
      final parentHash = commit.parents[p];
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
        parentLane = existingParentLane;
        parentColor = existingParentColor!;
        lines.add(
          GraphLine(
            fromLane: commitLane,
            toLane: parentLane,
            colorIndex: parentColor,
          ),
        );
      } else {
        if (p == 0) {
          parentLane = commitLane;
          parentColor = colorIndex;
        } else {
          parentLane = findAvailableLane(commitLane + 1);
          parentColor = nextColorIndex++;
        }

        activeLanes[parentLane] = (parentHash, parentColor);
        hashToColor[parentHash] = parentColor;

        lines.add(
          GraphLine(
            fromLane: commitLane,
            toLane: parentLane,
            colorIndex: parentColor,
          ),
        );
      }
    }

    rowInfos.add(
      CommitRowInfo(
        commit: commit,
        lines: lines,
        commitLane: commitLane,
        colorIndex: colorIndex,
      ),
    );
  }

  return rowInfos;
}

Map<String, (String, Color)> gitFileStatus = {
  "M": ('M', Color(0xffaf9672)),
  "D": ('D', Colors.red[300]!),
  "UU": ('C', Colors.red[300]!),
  "??": ('U', Colors.green[700]!),
  "A": ('A', Colors.green[700]!),
};

class EditHunk {
  final String id;
  final String type;
  final int startLine, endLine;
  final int sourceStartLine, sourceEndLine;
  final int? afterLine;
  final String oldText;
  final String newText;
  final String? addedText;
  final String? removedText;

  const EditHunk({
    required this.id,
    required this.type,
    required this.startLine,
    required this.endLine,
    required this.sourceStartLine,
    required this.sourceEndLine,
    required this.oldText,
    required this.newText,
    this.afterLine,
    this.addedText,
    this.removedText,
  });

  factory EditHunk.fromJson(Map<String, dynamic> json) {
    return EditHunk(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'modified',
      startLine: (json['startLine'] as num?)?.toInt() ?? 0,
      endLine: (json['endLine'] as num?)?.toInt() ?? 0,
      sourceStartLine:
          (json['sourceStartLine'] as num?)?.toInt() ??
          (json['startLine'] as num?)?.toInt() ??
          0,
      sourceEndLine:
          (json['sourceEndLine'] as num?)?.toInt() ??
          (json['endLine'] as num?)?.toInt() ??
          0,
      oldText: json['oldText']?.toString() ?? '',
      newText: json['newText']?.toString() ?? '',
      afterLine: (json['afterLine'] as num?)?.toInt(),
      addedText: json['addedText']?.toString(),
      removedText: json['removedText']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      "startLine": startLine,
      "endLine": endLine,
      "sourceStartLine": sourceStartLine,
      "sourceEndLine": sourceEndLine,
      "oldText": oldText,
      "newText": newText,
      "afterLine": afterLine,
      "addedText": addedText,
      "removedText": removedText,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class PendingEditFile {
  static const String _prefsKey = 'pendingAgenticEdits';

  final String filePath;
  final String oldText;
  final List<EditHunk> editHunks;

  const PendingEditFile({
    required this.filePath,
    required this.oldText,
    required this.editHunks,
  });

  factory PendingEditFile.fromJson(Map<String, dynamic> json) {
    final hunksRaw = json['editHunks'];
    final hunks = <EditHunk>[];
    if (hunksRaw is List) {
      for (final item in hunksRaw) {
        if (item is Map<String, dynamic>) {
          hunks.add(EditHunk.fromJson(item));
        } else if (item is Map) {
          hunks.add(EditHunk.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return PendingEditFile(
      filePath: json['filePath']?.toString() ?? '',
      oldText: json['oldText']?.toString() ?? '',
      editHunks: hunks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'oldText': oldText,
      'editHunks': editHunks.map((h) => h.toJson()).toList(),
    };
  }

  PendingEditFile copyWith({
    String? filePath,
    String? oldText,
    List<EditHunk>? editHunks,
  }) {
    return PendingEditFile(
      filePath: filePath ?? this.filePath,
      oldText: oldText ?? this.oldText,
      editHunks: editHunks ?? this.editHunks,
    );
  }

  static int _safeLineAtOffset(CodeForgeController controller, int offset) {
    final text = controller.text;
    if (text.isEmpty) return 0;
    final maxOffset = text.length - 1;
    final safeOffset = offset.clamp(0, maxOffset);
    return controller.getLineAtOffset(safeOffset);
  }

  static List<EditHunk> patchesToHunks(
    List<Patch> patches,
    CodeForgeController newController,
    CodeForgeController oldController,
  ) {
    final List<EditHunk> hunks = [];
    final ts = DateTime.now().microsecondsSinceEpoch;
    var idx = 0;

    for (final patch in patches) {
      var newCursor = patch.start2;
      var oldCursor = patch.start1;
      int? changedStartOffset;
      int? changedEndOffset;
      int? changedSourceStartOffset;
      int? changedSourceEndOffset;
      final newText = StringBuffer();
      final oldText = StringBuffer();
      final addedOnlyText = StringBuffer();
      final removedOnlyText = StringBuffer();
      var hasInsert = false;
      var hasDelete = false;

      for (final diff in patch.diffs) {
        if (diff.operation == 0 || diff.operation == -1) {
          oldText.write(diff.text);
        }

        if (diff.operation == 0 || diff.operation == 1) {
          newText.write(diff.text);
        }

        if (diff.operation == -1) {
          hasDelete = true;
          removedOnlyText.write(diff.text);
          changedSourceStartOffset ??= oldCursor;
          changedSourceEndOffset = (oldCursor + diff.text.length) - 1;
        } else if (diff.operation == 1) {
          hasInsert = true;
          addedOnlyText.write(diff.text);
          changedStartOffset ??= newCursor;
          changedEndOffset = (newCursor + diff.text.length) - 1;
        }

        if (diff.operation == 0 || diff.operation == 1) {
          newCursor += diff.text.length;
        }
        if (diff.operation == 0 || diff.operation == -1) {
          oldCursor += diff.text.length;
        }
      }

      final type = hasInsert && hasDelete
          ? 'modified'
          : hasInsert
          ? 'added'
          : 'removed';
      final rangeStartOffset = changedStartOffset ?? patch.start2;
      final rangeEndOffset = changedEndOffset ?? rangeStartOffset;
      final sourceRangeStartOffset = changedSourceStartOffset ?? patch.start1;
      final sourceRangeEndOffset =
          changedSourceEndOffset ?? sourceRangeStartOffset;
      final startLine = _safeLineAtOffset(newController, rangeStartOffset);
      final endLine = _safeLineAtOffset(newController, rangeEndOffset);
      final sourceStartLine = _safeLineAtOffset(
        oldController,
        sourceRangeStartOffset,
      );
      final sourceEndLine = _safeLineAtOffset(
        oldController,
        sourceRangeEndOffset,
      );
      final afterLine = hasDelete ? (startLine > 0 ? startLine - 1 : 0) : null;

      hunks.add(
        EditHunk(
          id: 'hunk-$ts-${idx++}',
          type: type,
          startLine: startLine,
          endLine: endLine,
          sourceStartLine: sourceStartLine,
          sourceEndLine: sourceEndLine,
          oldText: oldText.toString(),
          newText: newText.toString(),
          afterLine: afterLine,
          addedText: addedOnlyText.isEmpty ? null : addedOnlyText.toString(),
          removedText: removedOnlyText.isEmpty
              ? null
              : removedOnlyText.toString(),
        ),
      );
    }

    return hunks;
  }

  ({
    List<(int startLine, int endLine)> addedRanges,
    List<(int startLine, int endLine)> modifiedRanges,
    List<({int afterLine, String content})> removedRanges,
  })
  toDecorationRanges() {
    final addedRanges = <(int, int)>[];
    final modifiedRanges = <(int, int)>[];
    final removedRanges = <({int afterLine, String content})>[];

    String extractOldLines(EditHunk hunk) {
      if (oldText.isEmpty) return '';
      final lines = oldText.split('\n');
      if (lines.isEmpty) return '';
      final safeStart = hunk.sourceStartLine.clamp(0, lines.length - 1);
      final safeEnd = hunk.sourceEndLine.clamp(safeStart, lines.length - 1);
      return lines.sublist(safeStart, safeEnd + 1).join('\n');
    }

    for (final hunk in editHunks) {
      if (hunk.type == 'added') {
        addedRanges.add((hunk.startLine, hunk.endLine));
        continue;
      }

      if (hunk.type == 'modified') {
        modifiedRanges.add((hunk.startLine, hunk.endLine));
        final removed = extractOldLines(hunk);
        if (removed.isNotEmpty) {
          removedRanges.add((
            afterLine:
                hunk.afterLine ?? (hunk.startLine > 0 ? hunk.startLine - 1 : 0),
            content: removed,
          ));
        }
        continue;
      }

      if (hunk.type == 'removed') {
        final removed = extractOldLines(hunk);
        removedRanges.add((
          afterLine:
              hunk.afterLine ?? (hunk.startLine > 0 ? hunk.startLine - 1 : 0),
          content: removed.isNotEmpty
              ? removed
              : (hunk.removedText ?? hunk.oldText),
        ));
      }
    }

    return (
      addedRanges: addedRanges,
      modifiedRanges: modifiedRanges,
      removedRanges: removedRanges,
    );
  }

  void applyDecorations(
    CodeForgeController controller, {
    Color addedColor = const Color(0xFF4CAF50),
    Color removedColor = const Color(0xFFE53935),
    Color modifiedColor = const Color(0xFF4CAF50),
  }) {
    final ranges = toDecorationRanges();
    if (editHunks.isEmpty) {
      controller.clearGitDiffDecorations();
      return;
    }
    controller.setGitDiffDecorations(
      addedRanges: ranges.addedRanges,
      modifiedRanges: ranges.modifiedRanges,
      removedRanges: ranges.removedRanges,
      addedColor: addedColor,
      removedColor: removedColor,
      modifiedColor: modifiedColor,
    );
  }

  static Map<String, dynamic> _decodePrefs(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  static PendingEditFile? _parseFileEntry(dynamic rawEntry) {
    try {
      if (rawEntry is Map<String, dynamic>) {
        return PendingEditFile.fromJson(rawEntry);
      }
      if (rawEntry is Map) {
        return PendingEditFile.fromJson(Map<String, dynamic>.from(rawEntry));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedContent = _decodePrefs(prefs.getString(_prefsKey));
    final existing = _parseFileEntry(savedContent[filePath]);
    final merged = existing == null
        ? this
        : PendingEditFile(
            filePath: filePath,
            oldText: existing.oldText,
            editHunks: [...existing.editHunks, ...editHunks],
          );
    savedContent[filePath] = merged.toJson();
    await prefs.setString(_prefsKey, jsonEncode(savedContent));
  }

  static Future<void> upsert(PendingEditFile pendingEditFile) async {
    final prefs = await SharedPreferences.getInstance();
    final savedContent = _decodePrefs(prefs.getString(_prefsKey));
    savedContent[pendingEditFile.filePath] = pendingEditFile.toJson();
    await prefs.setString(_prefsKey, jsonEncode(savedContent));
  }

  static Future<PendingEditFile?> getForFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final savedContent = _decodePrefs(prefs.getString(_prefsKey));
    return _parseFileEntry(savedContent[filePath]);
  }

  static Future<Map<String, PendingEditFile>> getAllFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedContent = _decodePrefs(prefs.getString(_prefsKey));
    final result = <String, PendingEditFile>{};
    for (final entry in savedContent.entries) {
      final parsed = _parseFileEntry(entry.value);
      if (parsed != null) {
        result[entry.key] = parsed;
      }
    }
    return result;
  }

  static Future<void> removeFile(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final savedContent = _decodePrefs(prefs.getString(_prefsKey));
    savedContent.remove(filePath);
    await prefs.setString(_prefsKey, jsonEncode(savedContent));
  }

  static Future<void> removeHunk(String filePath, String hunkId) async {
    final pending = await getForFile(filePath);
    if (pending == null) return;

    final updated = pending.editHunks.where((h) => h.id != hunkId).toList();
    if (updated.isEmpty) {
      await removeFile(filePath);
      return;
    }

    await upsert(pending.copyWith(editHunks: updated));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode({}));
  }

  static Future<Map<String, dynamic>> getFromPref() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodePrefs(prefs.getString(_prefsKey));
  }
}
