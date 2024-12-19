import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/material.dart';

class NativeLibraryLoader {
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
}

class SetupTerminal extends StatelessWidget {
  final String projectDir;
  SetupTerminal({super.key,this.projectDir="/data/data/com.vsdroid/files/home"});

  final terminal = Terminal();
  final terminalController = TerminalController();

  Future<void> setupTerminal() async {
    final appPath = await NativeLibraryLoader.loadLibrary("libbash.so");
    final workDir = Directory(projectDir);
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    final enVars = <String, String>{
      'HOME': workDir.path,
      'PATH': '/bin:/usr/bin:/sbin:/usr/sbin'
    };

    _startPty(appPath, workDir.path, enVars);
  }

  void _startPty(String execPath, String workDir, Map<String, String> enVars) {
    final pty = Pty.start(execPath,
        workingDirectory: workDir,
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
