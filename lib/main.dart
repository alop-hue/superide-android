import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xterm/xterm.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: SetupTerminal()),
      ),
    );
  }
}

class SetupTerminal extends StatefulWidget {
  const SetupTerminal({super.key});

  @override
  State<SetupTerminal> createState() => _SetupTerminalState();
}

class _SetupTerminalState extends State<SetupTerminal> {
  final terminal = Terminal();
  final terminalController = TerminalController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> setupTerminal() async {
    final appPath = await NativeLibraryLoader.loadLibrary("libbash.so");
    final workDir = Directory("/data/data/com.vsdroid/files/home");
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

  Future<bool> requestStorage() async {
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;
    final status = await Permission.manageExternalStorage.status;

    if (android.version.sdkInt < 33) {
      await Permission.storage.request();
    } else {
      PermissionStatus.granted;
    }
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    /* return FutureBuilder<void>(
      future: setupTerminal(),
      builder: (context, snapshot2) {
        if (snapshot2.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot2.hasError) {
          print(snapshot2.error);
        }
        return SizedBox(child: TerminalView(terminal));
      },
    ); */

    return FutureBuilder<bool>(
      future: requestStorage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print(snapshot.error);
          return const AlertDialog(
            title: Text("Error"),
            content: Text("An error occurred"),
            icon: Icon(Icons.error),
          );
        }
        return FutureBuilder<void>(
          future: setupTerminal(),
          builder: (context, snapshot2) {
            if (snapshot2.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot2.hasError) {
              print(snapshot2.error);
            }
            return SizedBox(
                child: TerminalView(
              terminal,
              controller: terminalController,
              autofocus: true,
              keyboardType: TextInputType.multiline,
            ));
          },
        );

        /* if (snapshot.hasData && snapshot.data == false) {
          return AlertDialog(
            backgroundColor: Colors.red[100],
            title: const Text("Permission required"),
            content: const Text("File Permission is required to execute code"),
            icon: const Icon(Icons.warning),
            iconColor: Colors.red,
          );
        }
        return const Center(child: CircularProgressIndicator()); */
      },
    );
  }
}
