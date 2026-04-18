import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roxum/bloc/ui_bloc/ui_bloc.dart';
import 'package:roxum/utils/constants.dart';
import 'package:roxum/utils/functions.dart';
import 'package:roxum/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupTerminal extends StatefulWidget {
  final String projectDir;
  final List<String> args;
  final bool useScaffold;
  final bool showKeyboardMenu;
  final bool readOnly;

  const SetupTerminal({
    super.key,
    required this.projectDir,
    this.args = const [],
    this.useScaffold = true,
    this.showKeyboardMenu = true,
    this.readOnly = false,
  });

  @override
  State<SetupTerminal> createState() => _SetupTerminalState();
}

class EmbeddedTerminal extends StatelessWidget {
  final String projectDir;
  final List<String> args;
  final bool showKeyboardMenu;
  final bool readOnly;

  const EmbeddedTerminal({
    super.key,
    required this.projectDir,
    this.args = const [],
    this.showKeyboardMenu = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return SetupTerminal(
      projectDir: projectDir,
      args: args,
      useScaffold: false,
      showKeyboardMenu: showKeyboardMenu,
      readOnly: readOnly,
    );
  }
}

@immutable
class TerminalSessionMeta {
  final String id;
  final String title;
  final DateTime createdAt;
  final bool isRunning;

  const TerminalSessionMeta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.isRunning,
  });

  TerminalSessionMeta copyWith({String? title, bool? isRunning}) {
    return TerminalSessionMeta(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

@immutable
abstract class TerminalSessionEvent {}

class CreateTerminalSession extends TerminalSessionEvent {
  final String id;
  final String title;
  final bool makeActive;
  final bool isRunning;

  CreateTerminalSession({
    required this.id,
    required this.title,
    required this.makeActive,
    required this.isRunning,
  });
}

class SetActiveTerminalSession extends TerminalSessionEvent {
  final String id;
  SetActiveTerminalSession(this.id);
}

class DeleteTerminalSession extends TerminalSessionEvent {
  final String id;
  DeleteTerminalSession(this.id);
}

class UpdateTerminalSessionStatus extends TerminalSessionEvent {
  final String id;
  final bool isRunning;

  UpdateTerminalSessionStatus({required this.id, required this.isRunning});
}

@immutable
class TerminalSessionState {
  final List<TerminalSessionMeta> sessions;
  final String? activeSessionId;

  const TerminalSessionState({
    required this.sessions,
    required this.activeSessionId,
  });

  TerminalSessionState copyWith({
    List<TerminalSessionMeta>? sessions,
    String? activeSessionId,
    bool clearActive = false,
  }) {
    return TerminalSessionState(
      sessions: sessions ?? this.sessions,
      activeSessionId: clearActive
          ? null
          : activeSessionId ?? this.activeSessionId,
    );
  }
}

class TerminalSessionBloc
    extends Bloc<TerminalSessionEvent, TerminalSessionState> {
  TerminalSessionBloc()
    : super(const TerminalSessionState(sessions: [], activeSessionId: null)) {
    on<CreateTerminalSession>((event, emit) {
      final newSession = TerminalSessionMeta(
        id: event.id,
        title: event.title,
        createdAt: DateTime.now(),
        isRunning: event.isRunning,
      );
      final sessions = [newSession, ...state.sessions];
      emit(
        state.copyWith(
          sessions: sessions,
          activeSessionId: event.makeActive ? event.id : state.activeSessionId,
        ),
      );
    });

    on<SetActiveTerminalSession>((event, emit) {
      emit(state.copyWith(activeSessionId: event.id));
    });

    on<DeleteTerminalSession>((event, emit) {
      final sessions = state.sessions
          .where((session) => session.id != event.id)
          .toList();
      if (sessions.isEmpty) {
        emit(state.copyWith(sessions: sessions, clearActive: true));
        return;
      }
      final activeId = state.activeSessionId == event.id
          ? sessions.first.id
          : state.activeSessionId;
      emit(state.copyWith(sessions: sessions, activeSessionId: activeId));
    });

    on<UpdateTerminalSessionStatus>((event, emit) {
      final sessions = state.sessions.map((session) {
        if (session.id == event.id) {
          return session.copyWith(isRunning: event.isRunning);
        }
        return session;
      }).toList();
      emit(state.copyWith(sessions: sessions));
    });
  }
}

class _TerminalRuntime {
  final String sessionId;
  final String title;
  final GhosttyTerminalController controller;

  String currentInput = '';
  VoidCallback? runningListener;
  bool lastKnownRunning = false;

  _TerminalRuntime({
    required this.sessionId,
    required this.title,
    required this.controller,
  });

  bool get isRunning => controller.isRunning;

  Future<void> stopProcess() async {
    try {
      await controller.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stopProcess();
    if (runningListener != null) {
      controller.removeListener(runningListener!);
    }
    controller.dispose();
  }
}

class _SetupTerminalState extends State<SetupTerminal> {
  static const Duration _selectionActivationDelay = Duration(milliseconds: 240);

  late final TerminalSessionBloc _sessionBloc;
  final Map<String, _TerminalRuntime> _sessionRuntimes = {};
  String _sharedPath = '';
  final FocusNode _softKeyboardFocusNode = FocusNode();
  final TextEditingController _softKeyboardTextController =
      TextEditingController();
  String _lastSoftInputValue = '';
  bool _isResettingSoftInput = false;

  final ValueNotifier<List<String>?> _suggestionsNotifier = ValueNotifier(null);
  final ScrollController _suggestionScrollController = ScrollController();
  int _selectedSuggestionIndex = 0;
  List<String> _pathBinaries = [];
  Timer? _selectionActivationTimer;
  GhosttyTerminalSelection? _pendingTerminalSelection;
  String _pendingTerminalSelectionText = '';
  bool _isSelectionActive = false;
  GhosttyTerminalSelection? _terminalSelection;
  String _terminalSelectionText = '';

  @override
  void initState() {
    super.initState();
    _sessionBloc = TerminalSessionBloc();
    _bootstrapTerminalPage();
    _loadPathBinaries();
  }

  Future<void> _bootstrapTerminalPage() async {
    _sharedPath = await NativeChannel.getLibraryPath();
    final workDir = Directory(widget.projectDir);
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    await _ensureShellDefaults();
    if (!mounted) return;
    await _createSession(
      args: widget.args,
      makeActive: true,
      title: 'Session 1',
    );
  }

  Future<void> _ensureShellDefaults() async {
    const markerStart = '# >>> roxum-shell-defaults >>>';
    const shellDefaults = '''# >>> roxum-shell-defaults >>>
if command -v dircolors >/dev/null 2>&1; then
  eval "\$(dircolors -b)"
fi
alias ls='ls --color=auto'
alias ll='ls --color=auto -la'
alias la='ls --color=auto -A'
# <<< roxum-shell-defaults <<<
''';

    try {
      final rcFile = File('$homeDir/.bashrc');
      if (!await rcFile.exists()) {
        await rcFile.create(recursive: true);
        await rcFile.writeAsString(shellDefaults);
        return;
      }

      final current = await rcFile.readAsString();
      if (current.contains(markerStart)) {
        return;
      }

      final needsNewline = current.isNotEmpty && !current.endsWith('\n');
      final next = '${needsNewline ? '\n' : ''}\n$shellDefaults';
      await rcFile.writeAsString(next, mode: FileMode.append);
    } catch (_) {
    }
  }

  _TerminalRuntime? _activeRuntime() {
    final activeId = _sessionBloc.state.activeSessionId;
    if (activeId == null) return null;
    return _sessionRuntimes[activeId];
  }

  String _nextSessionTitle() {
    final count = _sessionRuntimes.length + 1;
    return 'Session $count';
  }

  Future<void> _createSession({
    List<String> args = const [],
    bool makeActive = true,
    String? title,
    bool showFeedback = false,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final sessionTitle = title ?? _nextSessionTitle();
    final runtime = _TerminalRuntime(
      sessionId: id,
      title: sessionTitle,
      controller: GhosttyTerminalController(
        maxLines: 4000,
        maxScrollback: 12000,
        preferPty: true,
      ),
    );
    runtime.runningListener = () {
      final running = runtime.controller.isRunning;
      if (runtime.lastKnownRunning == running) {
        return;
      }
      runtime.lastKnownRunning = running;
      if (!_sessionRuntimes.containsKey(id)) {
        return;
      }
      _sessionBloc.add(
        UpdateTerminalSessionStatus(id: id, isRunning: running),
      );
    };
    runtime.controller.addListener(runtime.runningListener!);
    _sessionRuntimes[id] = runtime;

    _sessionBloc.add(
      CreateTerminalSession(
        id: id,
        title: sessionTitle,
        makeActive: makeActive,
        isRunning: false,
      ),
    );

    await _startPty(runtime, args: args);

    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New session created: $sessionTitle'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restartSession(String sessionId) async {
    final runtime = _sessionRuntimes[sessionId];
    if (runtime == null) return;
    await runtime.stopProcess();
    runtime.currentInput = '';
    if (_sessionBloc.state.activeSessionId == sessionId) {
      _suggestionsNotifier.value = null;
    }
    await _startPty(runtime);
  }

  Future<void> _terminateSession(String sessionId) async {
    final runtime = _sessionRuntimes[sessionId];
    if (runtime == null || !runtime.isRunning) return;
    await runtime.stopProcess();
    _sessionBloc.add(
      UpdateTerminalSessionStatus(id: sessionId, isRunning: false),
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    if (!_sessionRuntimes.containsKey(sessionId)) return;

    final isLastSession = _sessionRuntimes.length == 1;

    if (isLastSession) {
      final runtime = _sessionRuntimes.remove(sessionId);
      await runtime?.dispose();
      _sessionBloc.add(DeleteTerminalSession(sessionId));
      _suggestionsNotifier.value = null;

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      return;
    }

    final runtime = _sessionRuntimes.remove(sessionId);
    await runtime?.dispose();
    _sessionBloc.add(DeleteTerminalSession(sessionId));

    if (_sessionBloc.state.activeSessionId == sessionId) {
      _suggestionsNotifier.value = null;
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

  Future<void> _startPty(
    _TerminalRuntime runtime, {
    List<String> args = const [],
  }) async {
    if (_sharedPath.isEmpty) {
      _sharedPath = await NativeChannel.getLibraryPath();
    }

    final enVars = <String, String>{
      'HOME': homeDir,
      'PWD': widget.projectDir,
      'PS1': r' \[\e[32m\]\w \[\e[0m\]\$ ',
      'PATH': '$binDir:$runtimesDir/node/bin:/bin:/usr/bin:/sbin:/usr/sbin',
      'PROMPT_DIRTRIM': '2',
      'ROXUM_SHARED_PATH': _sharedPath,
      'LD_LIBRARY_PATH': '$_sharedPath:$runtimesDir/ruby:$libDir:$runtimesDir/clang',
      'LD_PRELOAD': '$_sharedPath/libc++_shared.so',
      'PREFIX': '/data/data/com.roxum',
      'JAVA_HOME': '$runtimesDir/java-21-openjdk',
      'GIT_EXEC_PATH': '$binDir/git-core',
      'GIT_SSL_CAINFO': '$certDir/cacert.pem',
      'TERMINFO': '$runtimesDir/mono/terminfo',
    };

    final launchArgs = _resolveLaunchArgs(args);

    final launch = GhosttyTerminalShellLaunch(
      label: runtime.title,
      shell: '$_sharedPath/libbash.so',
      arguments: launchArgs,
      environment: enVars,
    );

    await runtime.controller.startLaunch(launch);
    runtime.lastKnownRunning = runtime.controller.isRunning;
    _sessionBloc.add(
      UpdateTerminalSessionStatus(
        id: runtime.sessionId,
        isRunning: runtime.lastKnownRunning,
      ),
    );

    if (widget.readOnly) {
      _suggestionsNotifier.value = null;
    }
  }

  String _shellSingleQuote(String input) {
    if (input.isEmpty) {
      return "''";
    }
    return "'${input.replaceAll("'", "'\\''")}'";
  }

  List<String> _resolveLaunchArgs(List<String> args) {
    final workspace = _shellSingleQuote(widget.projectDir);
    const startupPs1 = r"' \[\e[32m\]\w \[\e[0m\]\$ '";

    if (args.isEmpty) {
      return [
        '-c',
        'cd $workspace && export PS1=$startupPs1 && exec "\$0" -i',
      ];
    }

    final first = args.first;
    if ((first == '-c' || first == '-lc') && args.length >= 2) {
      final command = args[1];
      return [first, 'cd $workspace && $command'];
    }

    return args;
  }

  void _handleInputForAutocomplete(_TerminalRuntime runtime, String data) {
    if (data == '\r' || data == '\n') {
      _suggestionsNotifier.value = null;
      runtime.currentInput = '';
      return;
    }

    if (data == '\x7f' || data == '\b') {
      if (runtime.currentInput.isNotEmpty) {
        runtime.currentInput = runtime.currentInput.substring(
          0,
          runtime.currentInput.length - 1,
        );
      }
    } else if (data == '\t') {
      final suggestions = _suggestionsNotifier.value;
      if (suggestions != null && suggestions.isNotEmpty) {
        _acceptSuggestion(runtime, suggestions[_selectedSuggestionIndex]);
      }
      return;
    } else if (data == ' ' || data.contains('\x1b')) {
      _suggestionsNotifier.value = null;
      runtime.currentInput = '';
      return;
    } else if (data.length == 1 && data.codeUnitAt(0) >= 32) {
      runtime.currentInput += data;
    } else {
      return;
    }

    _updateSuggestions(runtime);
  }

  Future<void> _updateSuggestions(_TerminalRuntime runtime) async {
    if (runtime.currentInput.isEmpty) {
      _suggestionsNotifier.value = null;
      return;
    }

    final query = runtime.currentInput.toLowerCase();
    List<String> matches = [];

    if (runtime.currentInput.startsWith('./') ||
        runtime.currentInput.startsWith('/') ||
        runtime.currentInput.startsWith('~/') ||
        runtime.currentInput.contains('/')) {
      matches = await _getPathSuggestions(runtime.currentInput);
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
      final dirPath = lastSlash >= 0
          ? searchPath.substring(0, lastSlash + 1)
          : searchPath;
      final partial = lastSlash >= 0
          ? searchPath.substring(lastSlash + 1).toLowerCase()
          : '';

      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];

      final suggestions = <String>[];
      await for (final entity in dir.list()) {
        final name = entity.path.split('/').last;
        if (partial.isEmpty || name.toLowerCase().startsWith(partial)) {
          final isDir = entity is Directory;
          final displayPath = prefix.isEmpty
              ? entity.path
              : prefix +
                    entity.path.substring(
                      input.startsWith('~/')
                          ? homeDir.length
                          : input.startsWith('./')
                          ? widget.projectDir.length + 1
                          : 0,
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

  void _acceptSuggestion(_TerminalRuntime runtime, String suggestion) {
    if (!runtime.controller.isRunning) return;
    final toSend = suggestion.substring(runtime.currentInput.length);
    runtime.controller.write(toSend);
    runtime.currentInput = suggestion;
    _suggestionsNotifier.value = null;
  }

  void sendToPty(String sequence) {
    final runtime = _activeRuntime();
    if (runtime == null || widget.readOnly) {
      return;
    }
    final isSent = runtime.controller.write(sequence);
    if (isSent) {
      _handleInputForAutocomplete(runtime, sequence);
    }
  }

  void _setTerminalOutputWithAutocomplete({
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    VoidCallback? resetCallback,
  }) {}

  void _onTerminalSelectionChanged(GhosttyTerminalSelection? selection) {
    if (!mounted) return;

    _selectionActivationTimer?.cancel();
    if (selection == null) {
      setState(() {
        _isSelectionActive = false;
        _pendingTerminalSelection = null;
        _pendingTerminalSelectionText = '';
        _terminalSelection = null;
        _terminalSelectionText = '';
      });
      return;
    }

    _pendingTerminalSelection = selection;
    _selectionActivationTimer = Timer(_selectionActivationDelay, () {
      if (!mounted || _pendingTerminalSelection == null) {
        return;
      }
      setState(() {
        _isSelectionActive = true;
        _terminalSelection = _pendingTerminalSelection;
        _terminalSelectionText = _pendingTerminalSelectionText;
      });
    });
  }

  void _onTerminalSelectionContentChanged(
    GhosttyTerminalSelectionContent<GhosttyTerminalSelection>? content,
  ) {
    if (!mounted) return;
    _pendingTerminalSelectionText = content?.text ?? '';

    if (!_isSelectionActive) {
      return;
    }

    setState(() {
      _terminalSelectionText = _pendingTerminalSelectionText;
    });
  }

  Future<void> _copyTerminalSelection() async {
    final text = _terminalSelectionText;
    if (text.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteToTerminal() async {
    if (widget.readOnly) {
      return;
    }
    final runtime = _activeRuntime();
    if (runtime == null) {
      return;
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }

    final sent = runtime.controller.write(text);
    if (sent) {
      _handleInputForAutocomplete(runtime, text);
      _focusSoftKeyboard();
    }
  }

  Future<void> _copyAllTerminalText() async {
    final runtime = _activeRuntime();
    if (runtime == null) {
      return;
    }

    final selection = runtime.controller.snapshot.selectAllSelection();
    if (selection == null) {
      return;
    }

    final allText = runtime.controller.snapshot.textForSelection(selection);
    if (allText.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: allText));
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Copied full terminal output'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTerminalSelectionToolbar(AppTheme appTheme) {
    if (!_isSelectionActive || _terminalSelection == null) {
      return const SizedBox.shrink();
    }

    final hasSelectionText = _terminalSelectionText.trim().isNotEmpty;
    final chipBg = appTheme.isDark
        ? const Color(0xFF2A3038)
        : const Color(0xFFF6F8FB);
    final borderColor = appTheme.isDark
        ? const Color(0xFF4B5461)
        : const Color(0xFFD7DEE8);
    final iconColor = appTheme.isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Positioned(
      top: 10,
      left: 8,
      right: 8,
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(22),
          color: chipBg,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: IconTheme(
              data: IconThemeData(color: iconColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Copy',
                    visualDensity: VisualDensity.compact,
                    onPressed: hasSelectionText
                        ? () => _copyTerminalSelection()
                        : null,
                    icon: const Icon(Icons.copy_rounded, size: 19),
                  ),
                  IconButton(
                    tooltip: 'Paste',
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        widget.readOnly ? null : () => _pasteToTerminal(),
                    icon: const Icon(Icons.paste_rounded, size: 19),
                  ),
                  IconButton(
                    tooltip: 'Copy all',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyAllTerminalText(),
                    icon: const Icon(Icons.copy_all_rounded, size: 19),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalViewport(
    _TerminalRuntime runtime,
    TerminalThemePreset terminalTheme,
    double terminalFontSize,
    AppTheme appTheme,
  ) {
    final selectionColor = _isSelectionActive
        ? terminalTheme.selectionColor
        : Colors.transparent;

    return Stack(
      children: [
        Positioned.fill(
          child: GhosttyTerminalView(
            controller: runtime.controller,
            autofocus: !widget.readOnly,
            focusOnInteraction: !widget.readOnly,
            mobileDragScrollEnabled: true,
            onTapTerminal: _focusSoftKeyboard,
            showHeader: false,
            backgroundColor: terminalTheme.backgroundColor,
            foregroundColor: terminalTheme.foregroundColor,
            cursorColor: terminalTheme.cursorColor,
            selectionColor: selectionColor,
            hyperlinkColor: terminalTheme.hyperlinkColor,
            palette: terminalTheme.palette,
            padding: EdgeInsets.zero,
            showVerticalScrollbar: true,
            scrollbarThickness: 6,
            scrollbarMinThumbExtent: 36,
            scrollbarThumbColor: appTheme.isDark
              ? const Color(0x99BFC5CE)
              : const Color(0x99707A86),
            scrollbarTrackColor: appTheme.isDark
              ? const Color(0x33343E4A)
              : const Color(0x1F5C6773),
            fontSize: terminalFontSize,
            lineHeight: 1.25,
            fontFamily: 'jetBrainsMono',
            onSelectionChanged: _onTerminalSelectionChanged,
            onSelectionContentChanged: _onTerminalSelectionContentChanged,
            onCopySelection: (text) async {
              if (text.trim().isEmpty) {
                return;
              }
              await Clipboard.setData(ClipboardData(text: text));
              if (!mounted) {
                return;
              }
              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger == null) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onPasteRequest: widget.readOnly
                ? () async => null
                : () async {
                    final data = await Clipboard.getData(
                      Clipboard.kTextPlain,
                    );
                    return data?.text;
                  },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            // Ghostty paints a hardcoded focused border. Masking 1px edges
            // keeps focus behavior while hiding that border.
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: terminalTheme.backgroundColor,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _focusSoftKeyboard() {
    if (widget.readOnly || !mounted) {
      return;
    }
    if (!_softKeyboardFocusNode.hasFocus) {
      _softKeyboardFocusNode.requestFocus();
    }
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  void _resetSoftInputField() {
    _isResettingSoftInput = true;
    _softKeyboardTextController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _lastSoftInputValue = '';
    _isResettingSoftInput = false;
  }

  void _handleSoftKeyboardChanged(String value) {
    if (_isResettingSoftInput || widget.readOnly) {
      return;
    }
    final runtime = _activeRuntime();
    if (runtime == null || !runtime.controller.isRunning) {
      _lastSoftInputValue = value;
      return;
    }

    if (value.isEmpty && _lastSoftInputValue.isNotEmpty) {
      final sent = runtime.controller.write('\x7f');
      if (sent) {
        _handleInputForAutocomplete(runtime, '\x7f');
      }
      _lastSoftInputValue = value;
      return;
    }

    if (value.startsWith(_lastSoftInputValue)) {
      final delta = value.substring(_lastSoftInputValue.length);
      if (delta.isNotEmpty) {
        final sent = runtime.controller.write(delta);
        if (sent) {
          _handleInputForAutocomplete(runtime, delta);
        }
      }
      _lastSoftInputValue = value;
    } else {
      if (value.isNotEmpty) {
        final sent = runtime.controller.write(value);
        if (sent) {
          _handleInputForAutocomplete(runtime, value);
        }
      }
      _lastSoftInputValue = value;
    }

    if (value.length > 24 || value.contains('\n')) {
      _resetSoftInputField();
    }
  }

  Widget _buildSoftKeyboardBridge() {
    if (widget.readOnly) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      bottom: 0,
      width: 1,
      height: 1,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: TextField(
            controller: _softKeyboardTextController,
            focusNode: _softKeyboardFocusNode,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            autofocus: false,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: _handleSoftKeyboardChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _selectionActivationTimer?.cancel();
    _suggestionsNotifier.dispose();
    _suggestionScrollController.dispose();
    _softKeyboardTextController.dispose();
    _softKeyboardFocusNode.dispose();
    for (final runtime in _sessionRuntimes.values) {
      runtime.dispose();
    }
    _sessionRuntimes.clear();
    _sessionBloc.close();
    super.dispose();
  }

  Widget _buildSuggestionBox() {
    if (widget.readOnly) {
      return const SizedBox.shrink();
    }

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
                      final activeRuntime = _activeRuntime();

                      return InkWell(
                        onTap: activeRuntime == null
                            ? null
                            : () =>
                                  _acceptSuggestion(activeRuntime, suggestion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: isSelected
                              ? const Color(0xff094771)
                              : Colors.transparent,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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

  Widget _buildSessionDrawer(TerminalSessionState state, AppTheme appTheme) {
    return Drawer(
      backgroundColor: appTheme.selectScreenDrawerBg,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: appTheme.editorPageDrawerBg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Terminal Sessions',
                  style: TextStyle(
                    color: appTheme.selectScreenCardTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.sessions.length} active tabs',
                  style: TextStyle(
                    color: appTheme.editorPageToolColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                final session = state.sessions[index];
                final isActive = session.id == state.activeSessionId;

                return ListTile(
                  leading: Icon(
                    session.isRunning ? Icons.terminal : Icons.pause_circle,
                    color: session.isRunning
                        ? appTheme.editorPageToolSelectedColor
                        : appTheme.editorPageToolColor,
                  ),
                  title: Text(
                    session.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: appTheme.selectScreenCardTextColor),
                  ),
                  subtitle: Text(
                    session.isRunning ? 'Running' : 'Stopped',
                    style: TextStyle(color: appTheme.editorPageToolColor),
                  ),
                  selected: isActive,
                  selectedTileColor: appTheme.editorPageToolSelectedBgColor,
                  onTap: () {
                    _sessionBloc.add(SetActiveTerminalSession(session.id));
                    Navigator.of(context).pop();
                  },
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Restart session',
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _restartSession(session.id),
                        icon: Icon(
                          Icons.refresh,
                          size: 18,
                          color: appTheme.editorPageToolColor,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Stop session',
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: session.isRunning
                            ? () => _terminateSession(session.id)
                            : null,
                        icon: Icon(
                          Icons.stop_circle_outlined,
                          size: 18,
                          color: session.isRunning
                              ? appTheme.editorPageToolColor
                              : appTheme.editorPageToolColor.withValues(
                                  alpha: 0.45,
                                ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete session',
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteSession(session.id),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: appTheme.editorPageToolColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _sessionBloc,
      child: BlocListener<TerminalSessionBloc, TerminalSessionState>(
        listenWhen: (previous, current) =>
            previous.activeSessionId != current.activeSessionId,
        listener: (context, state) {
          _suggestionsNotifier.value = null;
          _resetSoftInputField();
          if (mounted) {
            setState(() {
              _terminalSelection = null;
              _terminalSelectionText = '';
            });
          }
        },
        child: BlocBuilder<TerminalSessionBloc, TerminalSessionState>(
          builder: (context, state) {
            final activeRuntime = _activeRuntime();
            final appTheme = context.watch<AppThemeBloc>().state.appTheme;
            final configState = context.watch<ConfigBloc>().state;
            final terminalTheme = terminalThemePresetFromConfig(
              configState.codeForgeConfig['terminalTheme'],
            );
            final terminalFontSizeRaw =
              (configState.codeForgeConfig['terminalFontSize'] as num?)
                ?.toDouble() ??
              defaultTerminalFontSize;
            final terminalFontSize =
              terminalFontSizeRaw.clamp(10.0, 30.0).toDouble();
            final terminalContent = activeRuntime == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: _buildTerminalViewport(
                              activeRuntime,
                              terminalTheme,
                              terminalFontSize,
                                appTheme,
                            ),
                          ),
                          if (widget.showKeyboardMenu)
                            TerminalKeyboardMenu(
                              onSendSequence: sendToPty,
                              onModifierChanged:
                                  (ctrl, alt, shift, resetCallback) {
                                    _setTerminalOutputWithAutocomplete(
                                      ctrl: ctrl,
                                      alt: alt,
                                      shift: shift,
                                      resetCallback: resetCallback,
                                    );
                                  },
                            ),
                        ],
                      ),
                      _buildSuggestionBox(),
                      _buildTerminalSelectionToolbar(appTheme),
                      _buildSoftKeyboardBridge(),
                    ],
                  );

            if (!widget.useScaffold) {
              return terminalContent;
            }

            return Scaffold(
              appBar: AppBar(
                leading: Builder(
                  builder: (context) {
                    final sessionCount = state.sessions.length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'Open sessions drawer',
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                        if (sessionCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: appTheme.editorPageToolSelectedBgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                sessionCount > 99 ? '99+' : '$sessionCount',
                                style: TextStyle(
                                  color: appTheme.editorPageToolSelectedColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                title: Text(activeRuntime?.title ?? 'Terminal'),
                actions: [
                  IconButton(
                    tooltip: 'Zoom out',
                    onPressed: () => _updateTerminalZoom(0.9),
                    icon: const Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    tooltip: 'Zoom in',
                    onPressed: () => _updateTerminalZoom(1.1),
                    icon: const Icon(Icons.zoom_in),
                  ),
                  IconButton(
                    tooltip: 'New session',
                    onPressed: () =>
                        _createSession(makeActive: true, showFeedback: true),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              drawer: _buildSessionDrawer(state, appTheme),
              body: terminalContent,
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateTerminalZoom(double factor) async {
    final configBloc = context.read<ConfigBloc>();
    final currentState = Map<String, dynamic>.from(
      configBloc.state.codeForgeConfig,
    );
    final currentSize = (currentState['terminalFontSize'] as num?)
            ?.toDouble() ??
        defaultTerminalFontSize;
    final nextSize = (currentSize * factor).clamp(10.0, 30.0).toDouble();
    currentState['terminalFontSize'] = nextSize;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codeForgeConfig', jsonEncode(currentState));
    if (!mounted) {
      return;
    }
    configBloc.add(ChangeConfigEvent(currentState));
  }
}

class TerminalKeyboardMenu extends StatefulWidget {
  final Function(String) onSendSequence;
  final Function(bool ctrl, bool alt, bool shift, VoidCallback resetCallback)
  onModifierChanged;

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
    widget.onModifierChanged(
      isCtrlActive,
      isAltActive,
      isShiftActive,
      _resetModifiers,
    );
  }

  void _toggleAlt() {
    setState(() {
      isAltActive = !isAltActive;
      if (isAltActive) {
        isCtrlActive = false;
        isShiftActive = false;
      }
    });
    widget.onModifierChanged(
      isCtrlActive,
      isAltActive,
      isShiftActive,
      _resetModifiers,
    );
  }

  void _toggleShift() {
    setState(() {
      isShiftActive = !isShiftActive;
      if (isShiftActive) {
        isCtrlActive = false;
        isAltActive = false;
      }
    });
    widget.onModifierChanged(
      isCtrlActive,
      isAltActive,
      isShiftActive,
      _resetModifiers,
    );
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
                  backgroundColor: isCtrlActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: const Text("CTRL"),
              ),
              TextButton(
                onPressed: _toggleAlt,
                style: TextButton.styleFrom(
                  foregroundColor: isAltActive ? Colors.yellow : Colors.white,
                  backgroundColor: isAltActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: const Text("ALT"),
              ),
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b[H'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text("HOME"),
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[A'),
                color: Colors.white,
                icon: const Icon(Icons.arrow_upward),
              ),
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b[F'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text("END"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => widget.onSendSequence('\x1b'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text("ESC"),
              ),
              TextButton(
                onPressed: _toggleShift,
                style: TextButton.styleFrom(
                  foregroundColor: isShiftActive ? Colors.yellow : Colors.white,
                  backgroundColor: isShiftActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: const Text("SHIFT"),
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[D'),
                color: Colors.white,
                icon: const Icon(Icons.arrow_back),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () => widget.onSendSequence('\x1b[B'),
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_downward),
                ),
              ),
              IconButton(
                onPressed: () => widget.onSendSequence('\x1b[C'),
                color: Colors.white,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
