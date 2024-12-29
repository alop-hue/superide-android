import 'dart:convert';
import 'dart:io';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/material.dart';

class SetupTerminal extends StatefulWidget {
  final String projectDir;
  final HttpServer? server;
  const SetupTerminal({super.key, required this.projectDir, this.server});

  @override
  State<SetupTerminal> createState() => _SetupTerminalState();
}

class _SetupTerminalState extends State<SetupTerminal> {
  final terminal = Terminal();

  final terminalController = TerminalController();

  Future<void> setupTerminal() async {
    final appPath = await NativeChannel.loadLibrary("libbash.so");
    final workDir = Directory(widget.projectDir);
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    final enVars = <String, String>{
      'HOME': workDir.path,
      'PS1': " \x1b[32m~ \x1b[0m\$ ",
      'PATH': '/bin:/usr/bin:/sbin:/usr/sbin'
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

  Future<void> listenServer() async {
    if (widget.server != null) {
      await for (HttpRequest request in widget.server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket websocket = await WebSocketTransformer.upgrade(request);
          terminal.write("CONNECTED TO TERMUX\r\n\n");
          websocket.listen((message) {
            terminal.write(message.toString().replaceAll("\n", "\r\n"));
            websocket.add('Echo: $message');
          }, onDone: () {
            terminal.write('\r\n\nDISCONNECTED FROM TERMUX');
          });
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('\r\nFailed to connect with Termux')
            ..close();
        }
      }
    }
  }

  Future<void> killService() async {
    await NativeChannel.killService();
  }

  @override
  void didChangeDependencies() {
    listenServer();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    terminalController.dispose();
    widget.server!.close();
    killService();
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
            );
          }),
    );
  }
}
