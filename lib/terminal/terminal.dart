import 'dart:convert';
import 'dart:io';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/material.dart';

class SetupTerminal extends StatelessWidget {
  final String projectDir;
  SetupTerminal({super.key, required this.projectDir});

  final terminal = Terminal();
  final terminalController = TerminalController();
  Future<void> setupTerminal() async {
    final appPath = await NativeChannel.loadLibrary("libbash.so");
    final workDir = Directory(projectDir);
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    final enVars = <String, String>{
      'HOME': workDir.path,
      'PS1': " \x1b[32m~ \x1b[0m\$ ",
      'PATH':'/bin:/usr/bin:/sbin:/usr/sbin'
    };

    _startPty(appPath, enVars);
  }

  void _startPty(String execPath, Map<String, String> enVars) {
    final pty = Pty.start(execPath,
        workingDirectory: enVars['HOME'],
        environment: enVars,
        rows: terminal.viewHeight,
        columns: terminal.viewWidth);
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
            );
          }),
    );
  }
}
