import 'dart:convert';
import 'dart:io';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:vsdroid/terminal/rcfile.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/material.dart';

class SetupTerminal extends StatefulWidget {
  final String projectDir;
  final List<String> args;
  const SetupTerminal({
    super.key,
    required this.projectDir,
    this.args = const []
  });

  @override
  State<SetupTerminal> createState() => _SetupTerminalState();
}

class _SetupTerminalState extends State<SetupTerminal> {
  final terminal = Terminal();
  final terminalController = TerminalController();

  Future<void> setupTerminal() async {
    const String runtimeDir = '/data/data/com.vsdroid/runtimes';
    final sharedPath = await NativeChannel.getLibraryPath();
    final workDir = Directory(widget.projectDir);
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    final bashrcFile = File('${workDir.path}/.bashrc');
    await bashrcFile.writeAsString(createRcFile(runtimeDir, sharedPath));
    final enVars = <String, String>{
      'HOME': workDir.path,
      'PS1': " \x1b[32m~ \x1b[0m\$ ",
      'PATH': '/bin:/usr/bin:/sbin:/usr/sbin',
    };
    _startPty(
      "$sharedPath/libbash.so",
      enVars,
      args: [
        "--rcfile",
        "${workDir.path}/.bashrc",
        ...widget.args
      ]
    );
  }

  void _startPty(String execPath, Map<String, String> enVars, {List<String> args = const []}) {
    final pty = Pty.start(execPath,
        workingDirectory: enVars['HOME'],
        environment: enVars,
        rows: terminal.viewHeight,
        columns: terminal.viewWidth,
        arguments: args
      );
    pty.output
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);
    pty.exitCode.then((code) {
      terminal.write("[Program finished with exit code $code]");
    });
    terminal.onOutput = (data) {
      pty.write(const Utf8Encoder().convert(data));
    };
  }

  @override
  void dispose() {
    terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: setupTerminal(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return TerminalView(
            terminal,
            controller: terminalController,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            theme: terminalTheme,
          );
        },
      ),
    );
  }
}