import 'dart:convert';
import 'dart:io';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:vsdroid/utils/constants.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  
  
  OverlayEntry? _selectionToolbarOverlay;
  bool _hasSelection = false;
  
  
  final ValueNotifier<List<String>?> _suggestionsNotifier = ValueNotifier(null);
  final ScrollController _suggestionScrollController = ScrollController();
  int _selectedSuggestionIndex = 0;
  String _currentInput = '';
  List<String> _pathBinaries = [];
  
  @override
  void initState() {
    super.initState();
    if (!_isInitialized && mounted) {
      setupTerminal();
      _isInitialized = true;
    }
    
    terminalController.addListener(_onSelectionChanged);
    
    _loadPathBinaries();
  }

  void _onSelectionChanged() {
    final hasSelection = terminalController.selection != null;
    if (hasSelection != _hasSelection) {
      _hasSelection = hasSelection;
      if (hasSelection) {
        _showSelectionToolbar();
      } else {
        _hideSelectionToolbar();
      }
    }
  }
  
  Future<void> _loadPathBinaries() async {
    final pathDirs = [
      binDir,
      '$runtimesDir/node/bin',
      '/bin',
      '/usr/bin',
      '/sbin',
      '/usr/sbin',
    ];
    
    final binaries = <String>{};
    for (final dirPath in pathDirs) {
      try {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            if (entity is File) {
              final name = entity.path.split('/').last;
              binaries.add(name);
            }
          }
        }
      } catch (_) {}
    }
    _pathBinaries = binaries.toList()..sort();
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
      'LD_LIBRARY_PATH': '$sharedPath:$runtimesDir/ruby:$libDir:$runtimesDir/clang',
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
      terminal.write("\r\n\n[Program finished with exit code $code]");
    });

    terminal.onOutput = (data) {
      pty.write(const Utf8Encoder().convert(data));
      
      _handleInputForAutocomplete(data);
    };

    terminal.onResize = (w, h, pw, ph){
      pty.resize(h, w);
    };
  }
  
  void _handleInputForAutocomplete(String data) {
    if (data == '\r' || data == '\n') {
      _suggestionsNotifier.value = null;
      _currentInput = '';
      return;
    }
    
    if (data == '\x7f' || data == '\b') {
      if (_currentInput.isNotEmpty) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      }
    } else if (data == '\t') {
      
      final suggestions = _suggestionsNotifier.value;
      if (suggestions != null && suggestions.isNotEmpty) {
        _acceptSuggestion(suggestions[_selectedSuggestionIndex]);
      }
      return;
    } else if (data == ' ' || data.contains('\x1b')) {
      _suggestionsNotifier.value = null;
      _currentInput = '';
      return;
    } else if (data.length == 1 && data.codeUnitAt(0) >= 32) {
      _currentInput += data;
    } else {
      return;
    }
    
    _updateSuggestions();
  }
  
  Future<void> _updateSuggestions() async {
    if (_currentInput.isEmpty) {
      _suggestionsNotifier.value = null;
      return;
    }
    
    final query = _currentInput.toLowerCase();
    List<String> matches = [];
    
    if (_currentInput.startsWith('./') || 
        _currentInput.startsWith('/') || 
        _currentInput.startsWith('~/') ||
        _currentInput.contains('/')) {
      matches = await _getPathSuggestions(_currentInput);
    } else {
      
      matches = _pathBinaries
          .where((bin) => bin.toLowerCase().startsWith(query))
          .take(10)
          .toList();
    }
    
    if (matches.isEmpty) {
      _suggestionsNotifier.value = null;
    } else {
      _selectedSuggestionIndex = 0;
      _suggestionsNotifier.value = matches;
    }
  }
  
  Future<List<String>> _getPathSuggestions(String input) async {
    try {
      String searchPath;
      String prefix = '';
      
      if (input.startsWith('~/')) {
        searchPath = homeDir + input.substring(1);
        prefix = '~/';
      } else if (input.startsWith('./')) {
        searchPath = '${widget.projectDir}/${input.substring(2)}';
        prefix = './';
      } else if (input.startsWith('/')) {
        searchPath = input;
        prefix = '';
      } else {
        
        searchPath = '${widget.projectDir}/$input';
        prefix = '';
      }
      
      final lastSlash = searchPath.lastIndexOf('/');
      final dirPath = lastSlash >= 0 ? searchPath.substring(0, lastSlash + 1) : searchPath;
      final partial = lastSlash >= 0 ? searchPath.substring(lastSlash + 1).toLowerCase() : '';
      
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];
      
      final suggestions = <String>[];
      await for (final entity in dir.list()) {
        final name = entity.path.split('/').last;
        if (partial.isEmpty || name.toLowerCase().startsWith(partial)) {
          final isDir = entity is Directory;
          final displayPath = prefix.isEmpty 
              ? entity.path 
              : prefix + entity.path.substring(
                  input.startsWith('~/') ? homeDir.length : 
                  input.startsWith('./') ? widget.projectDir.length + 1 : 0
                );
          suggestions.add(isDir ? '$displayPath/' : displayPath);
        }
      }
      
      suggestions.sort();
      return suggestions.take(10).toList();
    } catch (_) {
      return [];
    }
  }
  
  void _acceptSuggestion(String suggestion) {
    
    final toSend = suggestion.substring(_currentInput.length);
    pty.write(const Utf8Encoder().convert(toSend));
    _currentInput = suggestion;
    _suggestionsNotifier.value = null;
  }
  
  void _showSelectionToolbar() {
    _hideSelectionToolbar();
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    
    _selectionToolbarOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xff2d2d2d),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xff454545)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolbarButton(
                      icon: Icons.copy,
                      label: 'Copy',
                      onTap: () {
                        final selectedText = terminalController.selection != null
                            ? terminal.buffer.getText(terminalController.selection!)
                            : '';
                        if (selectedText.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: selectedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                        terminalController.clearSelection();
                      },
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xff454545),
                    ),
                    _toolbarButton(
                      icon: Icons.paste,
                      label: 'Paste',
                      onTap: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          pty.write(const Utf8Encoder().convert(data!.text!));
                        }
                        terminalController.clearSelection();
                      },
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xff454545),
                    ),
                    _toolbarButton(
                      icon: Icons.search,
                      label: 'Search',
                      onTap: () {
                        final selectedText = terminalController.selection != null
                            ? terminal.buffer.getText(terminalController.selection!)
                            : '';
                        if (selectedText.isNotEmpty) {
                          pty.write(const Utf8Encoder().convert('grep -r "${selectedText.replaceAll('"', '\\"')}" .'));
                        }
                        terminalController.clearSelection();
                      },
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xff454545),
                    ),
                    _toolbarButton(
                      icon: Icons.close,
                      label: '',
                      onTap: () {
                        terminalController.clearSelection();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    overlay.insert(_selectionToolbarOverlay!);
  }
  
  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 8 : 12,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _hideSelectionToolbar() {
    _selectionToolbarOverlay?.remove();
    _selectionToolbarOverlay = null;
  }

  void sendToPty(String sequence) {
    pty.write(const Utf8Encoder().convert(sequence));
  }
  
  void _setTerminalOutputWithAutocomplete({
    bool ctrl = false, 
    bool alt = false, 
    bool shift = false,
    VoidCallback? resetCallback,
  }) {
    terminal.onOutput = (data) {
      String sequence = '';
      
      if (ctrl) {
        if (data.length == 1) {
          int code = data.toUpperCase().codeUnitAt(0);
          if (code >= 65 && code <= 90) { 
            sequence = String.fromCharCode(code - 64); 
          }
        }
      } else if (alt) {
        sequence = '\x1b$data';
      } else if (shift) {
        sequence = data.toUpperCase();
      } else {
        sequence = data;
      }
      
      if (sequence.isNotEmpty) {
        pty.write(const Utf8Encoder().convert(sequence));
        _handleInputForAutocomplete(sequence);
      }
      
      if ((ctrl || alt || shift) && resetCallback != null) {
        resetCallback();
        _setTerminalOutputWithAutocomplete();
      }
    };
  }

  @override
  void dispose() {
    _hideSelectionToolbar();
    _suggestionsNotifier.dispose();
    _suggestionScrollController.dispose();
    terminalController.removeListener(_onSelectionChanged);
    terminalController.dispose();
    super.dispose();
  }

  Widget _buildSuggestionBox() {
    return ValueListenableBuilder<List<String>?>(
      valueListenable: _suggestionsNotifier,
      builder: (context, suggestions, _) {
        if (suggestions == null || suggestions.isEmpty) {
          _selectedSuggestionIndex = 0;
          return const SizedBox.shrink();
        }
        
        final screenWidth = MediaQuery.of(context).size.width;
        const itemHeight = 40.0;
        final maxHeight = (suggestions.length * itemHeight).clamp(0.0, 300.0);
        
        return Positioned(
          left: 8,
          right: 8,
          bottom: 100,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xff252526),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                maxWidth: screenWidth - 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff3c3c3c), width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RawScrollbar(
                  thumbVisibility: true,
                  thumbColor: Colors.white.withValues(alpha: 0.3),
                  controller: _suggestionScrollController,
                  child: ListView.builder(
                    controller: _suggestionScrollController,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemExtent: itemHeight,
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      final isSelected = index == _selectedSuggestionIndex;
                      final isDirectory = suggestion.endsWith('/');
                      final isPath = suggestion.contains('/');
                      
                      return InkWell(
                        onTap: () => _acceptSuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: isSelected ? const Color(0xff094771) : Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isDirectory 
                                      ? Colors.amber.withValues(alpha: 0.15)
                                      : isPath 
                                          ? Colors.blue.withValues(alpha: 0.15)
                                          : Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  isDirectory 
                                      ? Icons.folder_rounded
                                      : isPath 
                                          ? Icons.insert_drive_file_rounded
                                          : Icons.terminal_rounded,
                                  size: 16,
                                  color: isDirectory 
                                      ? Colors.amber 
                                      : isPath 
                                          ? Colors.blue.shade300 
                                          : Colors.green.shade300,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isPath)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'cmd',
                                    style: TextStyle(
                                      color: Colors.green.shade300,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (isDirectory)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'dir',
                                    style: TextStyle(
                                      color: Colors.amber.shade300,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (isPath && !isDirectory)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'file',
                                    style: TextStyle(
                                      color: Colors.blue.shade300,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
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
                  _setTerminalOutputWithAutocomplete(
                    ctrl: ctrl,
                    alt: alt,
                    shift: shift,
                    resetCallback: resetCallback,
                  );
                },
              )
            ],
          ),
          _buildSuggestionBox(),
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
      color: const Color(0xff181818),
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
                child: const Text("CTRL")
              ),
              TextButton(
                onPressed: _toggleAlt,
                style: TextButton.styleFrom(
                  foregroundColor: isAltActive ? Colors.yellow : Colors.white,
                  backgroundColor: isAltActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                ), 
                child: const Text("ALT")
              ),
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b[H'), 
                style: TextButton.styleFrom(foregroundColor: Colors.white), 
                child: const Text("HOME")
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[A'), 
                color: Colors.white,
                icon: const Icon(Icons.arrow_upward)
              ),
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b[F'), 
                style: TextButton.styleFrom(foregroundColor: Colors.white), 
                child: const Text("END")
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b'), 
                style: TextButton.styleFrom(foregroundColor: Colors.white), 
                child: const Text("ESC")
              ),
              TextButton(
                onPressed: _toggleShift,
                style: TextButton.styleFrom(
                  foregroundColor: isShiftActive ? Colors.yellow : Colors.white,
                  backgroundColor: isShiftActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                ), 
                child: const Text("SHIFT")
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[D'), 
                color: Colors.white, 
                icon: const Icon(Icons.arrow_back)
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () => widget.onSendSequence('\x1b[B'), 
                  color: Colors.white, 
                  icon: const Icon(Icons.arrow_downward)
                ),
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[C'), 
                color: Colors.white, 
                icon: const Icon(Icons.arrow_forward)
              ),
            ],
          )
        ],
      ),
    );
  }
}
