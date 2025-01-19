import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
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
    String info = "";
    if (widget.server != null) {
      await for (HttpRequest request in widget.server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket websocket = await WebSocketTransformer.upgrade(request);
          websocket.listen((message) {
            terminal.write(utf8.decode(message).toString().replaceAll("\n", "\r\n"));
          }, onDone: () {
            terminal.write('\r\n\nDISCONNECTED FROM TERMUX');
          });
          terminal.onOutput = (data) async{
            if(data.contains(utf8.decode([127]))){
              terminal.buffer.backspace();
              terminal.write("\x1B[1P");
              data = data.replaceAll(utf8.decode([127]), "");
              if(info.isNotEmpty){
                info = info.substring(0,info.length - 1);
              }
            }
            data = data.replaceAll("\r", "\r\n");
            info += data;
            terminal.write(data);
            if(data.contains("\r") || data.contains("\n")){
              await websocket.addStream(Stream<Uint8List>.value(const Utf8Encoder().convert(info)));
              info = "";
            }
          };
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('\r\nFailed to connect with Termux')
            ..close();
        }
      }
    }
  }


  @override
  void didChangeDependencies() {
    listenServer();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    terminalController.dispose();
    widget.server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        await widget.server?.close();
        await NativeChannel.closeTermux();
      },
      child: Scaffold(
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
              theme: const TerminalTheme(
                cursor: Colors.grey,
                selection: Color.fromARGB(134, 170, 191, 211),
                foreground: Colors.white,
                background: Color.fromARGB(255, 13, 44, 60),
                black: Color(0xff000000),
                white: Color(0xffffffff),
                red: Color(0xffff0000),
                green: Color(0xff00ff00),
                yellow: Color(0xffffff00),
                blue: Color(0xff0000ff),
                magenta: Color(0xffff00ff),
                cyan: Color(0xff00ffff),
                brightBlack: Color(0xff808080),
                brightRed: Color(0xffff5f5f),
                brightGreen: Color(0xff5fff5f),
                brightYellow: Color(0xffffff87),
                brightBlue: Color(0xff5f5fff),
                brightMagenta: Color(0xffff5fff),
                brightCyan: Color(0xff5fffff),
                brightWhite: Color(0xffffffff),
                searchHitBackground: Color(0xff444444),
                searchHitBackgroundCurrent: Color(0xff555555),
                searchHitForeground: Color(0xffffffff),
              ),

            );
          },
        ),
      ),
    );
  }
}