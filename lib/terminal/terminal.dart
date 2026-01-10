import 'dart:convert';
import 'dart:io';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:vsdroid/utils/constants.dart';
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
  final terminal = Terminal(platform: TerminalTargetPlatform.android);
  final terminalController = TerminalController(selectionMode: SelectionMode.block);
  late Pty pty;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (!_isInitialized && mounted) {
      setupTerminal();
      _isInitialized = true;
    }
  }

  Future<void> setupTerminal() async {
    final sharedPath = await NativeChannel.getLibraryPath();
    final workDir = Directory(widget.projectDir);
    if(!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    
    final enVars = <String, String>{
      'HOME': homeDir,
      'PS1': " \x1b[32m\\w \x1b[0m\$ ",
      'PATH': '$binDir:$runtimesDir/node/bin:/bin:/usr/bin:/sbin:/usr/sbin',
      'PROMPT_DIRTRIM':'2',
      'VSDROID_SHARED_PATH': sharedPath,
      'LD_LIBRARY_PATH': '$sharedPath:$runtimesDir/ruby:$runtimesDir/mono:$libDir:$runtimesDir/clang',
      'LD_PRELOAD': '$sharedPath/libc++_shared.so', 
      'PREFIX': "/data/data/com.vsdroid",
      'JAVA_HOME': '$runtimesDir/java-21-openjdk',
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'TERMINFO': '$runtimesDir/mono/terminfo'
    };
    _startPty(
      "$sharedPath/libbash.so",
      enVars,
      args: widget.args
    );
  }

  void _startPty(String execPath, Map<String, String> enVars, {List<String> args = const []}) {
    pty = Pty.start(
      execPath,
      workingDirectory: widget.projectDir,
      environment: enVars,
      rows: terminal.viewHeight,
      columns: terminal.viewWidth,
      arguments: args,
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

    terminal.onResize = (w, h, pw, ph){
      pty.resize(h, w);
    };
  }

  void sendToPty(String sequence) {
    pty.write(const Utf8Encoder().convert(sequence));
  }

  @override
  void dispose() {
    terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: TerminalView(
              terminal,
              padding: EdgeInsets.zero,
              controller: terminalController,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              theme: terminalTheme,
            ),
          ),
          TerminalKeyboardMenu(
            onSendSequence: sendToPty,
            onModifierChanged: (ctrl, alt, shift, resetCallback) {
              
              terminal.onOutput = (data) {
                String sequence = '';
                
                if(ctrl){
                  
                  if(data.length == 1) {
                    int code = data.toUpperCase().codeUnitAt(0);
                    if(code >= 65 && code <= 90) { 
                      sequence = String.fromCharCode(code - 64); 
                    }
                  }
                } else if(alt) {
                  
                  sequence = '\x1b$data';
                } else if(shift) {
                  
                  sequence = data.toUpperCase();
                } else {
                  sequence = data;
                }
                
                if(sequence.isNotEmpty) {
                  pty.write(const Utf8Encoder().convert(sequence));
                }
                
                
                if(ctrl || alt || shift) {
                  resetCallback();
                  
                  terminal.onOutput = (data) {
                    pty.write(const Utf8Encoder().convert(data));
                  };
                }
              };
            },
          )
        ],
      ),
    );
  }
}

class TerminalKeyboardMenu extends StatefulWidget {
  final Function(String) onSendSequence;
  final Function(bool ctrl, bool alt, bool shift, VoidCallback resetCallback) onModifierChanged;
  
  const TerminalKeyboardMenu({
    super.key,
    required this.onSendSequence,
    required this.onModifierChanged,
  });

  @override
  State<TerminalKeyboardMenu> createState() => _TerminalKeyboardMenuState();
}

class _TerminalKeyboardMenuState extends State<TerminalKeyboardMenu> {
  bool isCtrlActive = false;
  bool isAltActive = false;
  bool isShiftActive = false;

  void _resetModifiers() {
    setState(() {
      isCtrlActive = false;
      isAltActive = false;
      isShiftActive = false;
    });
  }

  void _toggleCtrl() {
    setState(() {
      isCtrlActive = !isCtrlActive;
      if (isCtrlActive) {
        isAltActive = false;
        isShiftActive = false;
      }
    });
    widget.onModifierChanged(isCtrlActive, isAltActive, isShiftActive, _resetModifiers);
  }

  void _toggleAlt() {
    setState(() {
      isAltActive = !isAltActive;
      if (isAltActive) {
        isCtrlActive = false;
        isShiftActive = false;
      }
    });
    widget.onModifierChanged(isCtrlActive, isAltActive, isShiftActive, _resetModifiers);
  }

  void _toggleShift() {
    setState(() {
      isShiftActive = !isShiftActive;
      if (isShiftActive) {
        isCtrlActive = false;
        isAltActive = false;
      }
    });
    widget.onModifierChanged(isCtrlActive, isAltActive, isShiftActive, _resetModifiers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff181818),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _toggleCtrl,
                style: TextButton.styleFrom(
                  foregroundColor: isCtrlActive ? Colors.yellow : Colors.white,
                  backgroundColor: isCtrlActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                ), 
                child: Text("CTRL")
              ),
              TextButton(
                onPressed: _toggleAlt,
                style: TextButton.styleFrom(
                  foregroundColor: isAltActive ? Colors.yellow : Colors.white,
                  backgroundColor: isAltActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                ), 
                child: Text("ALT")
              ),
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b[H'), 
                style: TextButton.styleFrom(foregroundColor: Colors.white), 
                child: Text("HOME")
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[A'), 
                color: Colors.white,
                icon: Icon(Icons.arrow_upward)
              ),
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b[F'), 
                style: TextButton.styleFrom(foregroundColor: Colors.white), 
                child: Text("END")
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b'), 
                style: TextButton.styleFrom(foregroundColor: Colors.white), 
                child: Text("ESC")
              ),
              TextButton(
                onPressed: _toggleShift,
                style: TextButton.styleFrom(
                  foregroundColor: isShiftActive ? Colors.yellow : Colors.white,
                  backgroundColor: isShiftActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                ), 
                child: Text("SHIFT")
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[D'), 
                color: Colors.white, 
                icon: Icon(Icons.arrow_back)
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () => widget.onSendSequence('\x1b[B'), 
                  color: Colors.white, 
                  icon: Icon(Icons.arrow_downward)
                ),
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[C'), 
                color: Colors.white, 
                icon: Icon(Icons.arrow_forward)
              ),
            ],
          )
        ],
      ),
    );
  }
}