import 'dart:convert';
import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:vsdroid/bloc/repo_bloc/repo_bloc.dart';
import 'package:vsdroid/ui/mdview.dart';
import 'package:vsdroid/utils/constants.dart';
import 'webview.dart';
import '../bloc/ui_bloc/ui_bloc.dart';
import '../terminal/terminal.dart';
import '../utils/languages.dart';
import '../utils/functions.dart';
import '../utils/themes.dart';
import 'widgets.dart';

class EditorPage extends StatefulWidget {
  final Language? languageDetails;
  final String rootDir;
  final File? file;
  final bool isProject, isCloned;
  const EditorPage({
    super.key,
    required this.languageDetails,
    required this.rootDir,
    required this.isProject,
    this.file,
    this.isCloned = false,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final createFileKey = GlobalKey<FormState>();
  final trasnformationController = TransformationController();
  final Map<CodeForgeController, String> _savedSnapshotByController = {};
  final Map<CodeForgeController, VoidCallback> _editorListeners = {};
  final Set<CodeForgeController> _dirtyControllers = {};
  late final TextEditingController createFileController, findWordController;
  late final TextEditingController replaceWordController, apiUrlController;
  late final TabController apiTabController, paramTabController;
  late final ActiveEditorBloc _activeEditorBloc;
  late List<int> mruOrder;
  bool _allowImmediatePop = false;
  bool _didInitializeEditors = false;
  Map<String, String> params = {}, headers = {};
  TabController? tabController;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    final uiBloc = context.read<ConfigBloc>();
    _activeEditorBloc = ActiveEditorBloc(
      widget.rootDir,
      uiBloc.state.codeForgeConfig,
    );
    mruOrder = [0];
    createFileController = TextEditingController();
    findWordController = TextEditingController();
    replaceWordController = TextEditingController();
    apiUrlController = TextEditingController();
    trasnformationController.value = Matrix4.identity()
      ..scaleByVector3(Vector3(1.45, 1.45, 1.45));
    apiTabController = TabController(length: 3, vsync: this);
    paramTabController = TabController(length: 3, vsync: this);
    assert(
      !(widget.isProject && widget.languageDetails != null),
      "Cannot have both isProject and language details",
    );
    assert(
      !(!widget.isProject && widget.isCloned),
      "Cloned directory should be a project.",
    );
    _initializeCopilotForEditorIfEnabled();
  }

  Future<void> _initializeCopilotForEditorIfEnabled() async {
    final isCopilotEnabled = await isCopilotEnabledPref();
    if (!isCopilotEnabled || !mounted) {
      return;
    }

    if (!Directory('$extensionDir/copilot-language-server').existsSync()) {
      return;
    }

    final copilotBloc = context.read<CopilotBloc>();
    if (copilotBloc.state.isInitialized ||
        copilotBloc.state.status == CopilotStatus.initializing) {
      return;
    }

    copilotBloc.add(
      CopilotInitialize(configPath: filesDir, workspacePath: widget.rootDir),
    );
  }

  String _lspLanguageIdForPath(Language language, String filePath) {
    final ext = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    if (ext == 'tsx' || ext == 'jsx') {
      return ext;
    }
    return language.name;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final entry in _editorListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _editorListeners.clear();
    _savedSnapshotByController.clear();
    _dirtyControllers.clear();
    apiUrlController.dispose();
    apiTabController.dispose();
    paramTabController.dispose();
    findWordController.dispose();
    trasnformationController.dispose();
    tabController?.removeListener(_onTabChanged);
    tabController?.dispose();
    _activeEditorBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (!_activeEditorBloc.isClosed) {
          _activeEditorBloc.add(CloseActiveEditor());
        }
        break;
      case AppLifecycleState.resumed:
        break;
    }

    super.didChangeAppLifecycleState(state);
  }

  void _updateTabController(int tabCount) {
    if (tabController == null || tabController!.length != tabCount) {
      tabController?.removeListener(_onTabChanged);
      tabController?.dispose();
      tabController = TabController(length: tabCount, vsync: this);
      tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (tabController == null || !tabController!.indexIsChanging) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyWorkspaceSearchToActiveEditor();
    });
  }

  void _applyWorkspaceSearchToActiveEditor() {
    if (!mounted) return;

    try {
      final searchState = context.read<WorkspaceSearchBloc>().state;
      final editorState = context.read<ActiveEditorBloc>().state;

      if (searchState.query.isEmpty) return;
      if (editorState.activeEditors.isEmpty) return;

      final activeIndex = tabController?.index ?? 0;
      if (activeIndex < 0 || activeIndex >= editorState.activeEditors.length) {
        return;
      }

      final editor = editorState.activeEditors[activeIndex];
      _applySearchHighlighting(editor, searchState.query, searchState);
    } catch (_) {}
  }

  void _applySearchHighlighting(
    ActiveEditor editor,
    String query,
    WorkspaceSearchState searchState,
  ) {
    if (editor.findController == null) return;

    final findController = editor.findController!;

    findController.caseSensitive = searchState.matchCase;
    findController.matchWholeWord = searchState.matchWholeWord;
    findController.isRegex = searchState.isRegex;

    findController.findInputController.text = query;
    findController.find(query, scrollToMatch: false);
  }

  void _clearSearchHighlighting(ActiveEditor editor) {
    if (editor.findController == null) return;
    editor.findController!.find('', scrollToMatch: false);
    editor.findController!.findInputController.clear();
  }

  Future<void> _applyPendingAgenticDiffForFile(
    CodeForgeController controller,
    String filePath,
  ) async {
    try {
      final canonicalPath = File(filePath).absolute.path;
      final pending = await PendingEditFile.getForFile(canonicalPath);
      if (!mounted) return;

      if (pending == null || pending.editHunks.isEmpty) {
        return;
      }

      pending.applyDecorations(controller);
    } catch (_) {
      // Pending diff lookup must never block normal file opening.
    }
  }

  void _goToMatchNearLine(
    ActiveEditor editor,
    int targetLine,
    String searchQuery,
  ) {
    if (editor.findController == null) return;

    final findController = editor.findController!;
    final codeController = editor.controller;
    final text = codeController.text;

    findController.findInputController.text = searchQuery;
    findController.find(searchQuery);

    if (findController.matchCount == 0) return;

    final lines = text.split('\n');
    int targetCharOffset = 0;
    for (int i = 0; i < targetLine - 1 && i < lines.length; i++) {
      targetCharOffset += lines[i].length + 1;
    }

    int targetLineEnd = targetCharOffset;
    if (targetLine - 1 < lines.length) {
      targetLineEnd += lines[targetLine - 1].length;
    }

    final lowerText = findController.caseSensitive ? text : text.toLowerCase();
    final lowerQuery = findController.caseSensitive
        ? searchQuery
        : searchQuery.toLowerCase();

    final matchPositions = <int>[];
    int pos = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, pos);
      if (index == -1) break;
      matchPositions.add(index);
      pos = index + 1;
    }

    if (matchPositions.isEmpty) return;

    int bestMatchIndex = 0;
    for (int i = 0; i < matchPositions.length; i++) {
      final matchStart = matchPositions[i];

      if (matchStart >= targetCharOffset && matchStart <= targetLineEnd) {
        bestMatchIndex = i;
        break;
      }
    }

    final currentIdx = findController.currentMatchIndex;
    final diff = bestMatchIndex - currentIdx;

    if (diff > 0) {
      for (int i = 0; i < diff; i++) {
        findController.next();
      }
    } else if (diff < 0) {
      for (int i = 0; i < -diff; i++) {
        findController.previous();
      }
    }
  }

  LspClientCapabilities? _getLspCapabilities(
    Map<String, dynamic> config,
    String langKey,
  ) {
    final Map<String, dynamic> featureToggle = Map<String, dynamic>.from(
      config["LSPFeatureToggle"] ?? {},
    );
    final List<String> disabledFeatures = List<String>.from(
      featureToggle[langKey] ?? [],
    );

    if (disabledFeatures.isEmpty) {
      return null;
    }

    return LspClientCapabilities(
      semanticHighlighting: !disabledFeatures.contains('semanticHighlighting'),
      codeCompletion: !disabledFeatures.contains('codeCompletion'),
      hoverInfo: !disabledFeatures.contains('hoverInfo'),
      codeAction: !disabledFeatures.contains('codeAction'),
      signatureHelp: !disabledFeatures.contains('signatureHelp'),
      documentColor: !disabledFeatures.contains('documentColor'),
      documentHighlight: !disabledFeatures.contains('documentHighlight'),
      codeFolding: !disabledFeatures.contains('codeFolding'),
      inlayHint: !disabledFeatures.contains('inlayHint'),
      goToDefinition: !disabledFeatures.contains('goToDefinition'),
      rename: !disabledFeatures.contains('rename'),
    );
  }

  bool _isTrackableEditor(ActiveEditor editor) {
    if (editor.customTitle?.contains('(Working Tree)') == true) {
      return false;
    }
    return !editor.controller.readOnly;
  }

  bool _isEditorDirty(ActiveEditor editor) {
    final autoSaveEnabled =
        context.read<GeneralBloc>().state.generalSettings['autoSave'] ?? true;
    if (autoSaveEnabled) return false;
    return _dirtyControllers.contains(editor.controller);
  }

  String _displayFileName(ActiveEditor editor) {
    final baseName = editor.customTitle ?? path.basename(editor.file.path);
    return _isEditorDirty(editor) ? '$baseName*' : baseName;
  }

  bool _hasUnsavedEditors(List<ActiveEditor> editors) {
    for (final editor in editors) {
      if (_isEditorDirty(editor)) return true;
    }
    return false;
  }

  void _attachDirtyListener(ActiveEditor editor) {
    final controller = editor.controller;
    if (_editorListeners.containsKey(controller) ||
        !_isTrackableEditor(editor)) {
      return;
    }

    String initialSnapshot = controller.text;
    try {
      if (editor.file.existsSync()) {
        initialSnapshot = editor.file.readAsStringSync();
      }
    } catch (_) {
      initialSnapshot = controller.text;
    }
    _savedSnapshotByController[controller] = initialSnapshot;

    void listener() {
      final savedSnapshot = _savedSnapshotByController[controller] ?? '';
      final isDirty = controller.text != savedSnapshot;
      final hasChanged = isDirty
          ? _dirtyControllers.add(controller)
          : _dirtyControllers.remove(controller);

      if (hasChanged && mounted) {
        setState(() {});
      }
    }

    controller.addListener(listener);
    _editorListeners[controller] = listener;
  }

  void _syncDirtyTracking(List<ActiveEditor> editors) {
    final currentControllers = editors.map((e) => e.controller).toSet();

    final removedControllers = _editorListeners.keys
        .where((controller) => !currentControllers.contains(controller))
        .toList();

    for (final controller in removedControllers) {
      final listener = _editorListeners.remove(controller);
      if (listener != null) {
        controller.removeListener(listener);
      }
      _dirtyControllers.remove(controller);
      _savedSnapshotByController.remove(controller);
    }

    for (final editor in editors) {
      _attachDirtyListener(editor);
    }
  }

  Future<void> _saveEditor(
    BuildContext actionContext,
    ActiveEditor editor,
  ) async {
    if (!_isTrackableEditor(editor)) return;

    try {
      editor.controller.saveFile();
      _savedSnapshotByController[editor.controller] = editor.controller.text;
      _dirtyControllers.remove(editor.controller);
      if (mounted) {
        try {
          actionContext.read<RepoStatusBloc>().add(
            LoadRepoStatus(widget.rootDir),
          );
        } catch (_) {}
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _saveActiveEditor(
    BuildContext actionContext,
    List<ActiveEditor> editors,
  ) async {
    if (editors.isEmpty) return;

    final activeIndex =
        tabController != null && tabController!.index < editors.length
        ? tabController!.index
        : editors.indexWhere((item) => item.isActive);
    final safeIndex = activeIndex < 0 ? 0 : activeIndex;
    await _saveEditor(actionContext, editors[safeIndex]);
  }

  Future<bool> _handleExitWithUnsavedPrompt(
    BuildContext actionContext,
    List<ActiveEditor> editors,
  ) async {
    final unsavedEditors = editors.where(_isEditorDirty).toList();
    if (unsavedEditors.isEmpty) {
      return true;
    }
    final appTheme = actionContext.read<AppThemeBloc>().state.appTheme;

    final action = await showDialog<String>(
      context: actionContext,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appTheme.isDark
              ? const Color(0xff2b2b2b)
              : const Color.fromARGB(255, 240, 240, 240),
          icon: const Icon(Icons.warning_amber_rounded, size: 34),
          iconColor: Colors.orange[700],
          title: Text(
            'Unsaved Changes',
            style: TextStyle(
              color: appTheme.selectScreenCardTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            unsavedEditors.length == 1
                ? 'Save changes to ${path.basename(unsavedEditors.first.file.path)} before exiting?'
                : 'Save changes to ${unsavedEditors.length} files before exiting?',
            style: TextStyle(color: Colors.grey[appTheme.isDark ? 400 : 700]),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: appTheme.editorPageToolColor,
              ),
              onPressed: () => Navigator.of(dialogContext).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
              onPressed: () => Navigator.of(dialogContext).pop('discard'),
              child: const Text("Don't Save"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.editorPageToolSelectedBgColor,
                foregroundColor: appTheme.editorPageToolSelectedColor,
              ),
              onPressed: () => Navigator.of(dialogContext).pop('save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (action == 'cancel' || action == null) {
      return false;
    }

    if (action == 'save' && context.mounted) {
      for (final editor in unsavedEditors) {
        await _saveEditor(actionContext, editor);
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AppTheme appTheme = context.read<AppThemeBloc>().state.appTheme;
    final ConfigBloc uiBloc = BlocProvider.of<ConfigBloc>(context);
    final autoSaveEnabled =
        context.watch<GeneralBloc>().state.generalSettings['autoSave'] ?? true;
    return FutureBuilder(
      future: Future.wait([
        widget.file == null && !widget.isProject
            ? setTempFile(widget.languageDetails!.extension[0])
            : Future.value(widget.file),
        (() async {
          final prefs = await SharedPreferences.getInstance();
          List<dynamic> storedData = jsonDecode(await getRecent());
          final Map<String, dynamic> dataToInsert;
          if (widget.isProject) {
            dataToInsert = {
              'type': 'project',
              'path': widget.rootDir,
              'rootDir': widget.rootDir,
            };
          } else {
            final File file =
                widget.file ??
                await setTempFile(widget.languageDetails!.extension[0]);
            dataToInsert = {
              'type': 'file',
              'path': file.path,
              'rootDir': widget.rootDir,
            };
          }
          final Set<String> uniquePaths = {};
          storedData.insert(0, dataToInsert);
          final List<dynamic> uniqueData = [];
          Map<String, dynamic>? normalizeRecentEntry(dynamic rawEntry) {
            if (rawEntry is Map &&
                rawEntry['type'] is String &&
                rawEntry['path'] is String) {
              return {
                'type': rawEntry['type'],
                'path': rawEntry['path'],
                'rootDir': rawEntry['rootDir'] ?? rawEntry['path'],
              };
            }

            if (rawEntry is Map && rawEntry.length == 1) {
              final dynamic key = rawEntry.keys.first;
              if (key is String) {
                return {'type': 'file', 'path': key, 'rootDir': rawEntry[key]};
              }
            }

            return null;
          }

          for (final data in storedData) {
            final normalized = normalizeRecentEntry(data);
            if (normalized == null) {
              continue;
            }

            final uniqueKey = '${normalized['type']}:${normalized['path']}';
            if (!uniquePaths.contains(uniqueKey)) {
              uniquePaths.add(uniqueKey);
              uniqueData.add(normalized);
            }
          }
          if (uniqueData.length > 3) {
            uniqueData.removeRange(3, uniqueData.length);
          }
          if (context.mounted) {
            context.read<RecentBloc>().add(RecentEvent(recent: uniqueData));
          }
          prefs.setString('recent', jsonEncode(uniqueData));
        })(),
        uiBloc.state.codeForgeConfig['enableLSP'] && !widget.isProject
            ? (() async {
                final initialPath =
                    widget.file?.path ??
                    '${widget.rootDir}/temp.${widget.languageDetails!.extension[0]}';
                final languageId = _lspLanguageIdForPath(
                  widget.languageDetails!,
                  initialPath,
                );
                return _activeEditorBloc.getOrStartSharedLspConfig(
                  languageId: languageId,
                  ext: widget.languageDetails!.extension[0],
                  executable: widget.languageDetails!.lspExecutable,
                  args: widget.languageDetails!.args ?? [],
                  capabilities: _getLspCapabilities(
                    uiBloc.state.codeForgeConfig,
                    widget.languageDetails!.name.toLowerCase(),
                  ),
                );
              })()
            : Future.value(null),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError && !widget.isProject) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(title: const Text('Error')),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to initialize editor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if ((!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) &&
            !widget.isProject) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No data received',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final target = !widget.isProject ? snapshot.data![0] as File? : null;
        final lspConfig = !widget.isProject
            ? snapshot.data!.length > 2
                  ? snapshot.data![2] as LspConfig?
                  : null
            : null;

        if ((target == null || !target.existsSync()) && !widget.isProject) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to create or access file',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    target?.path ?? 'Unknown path',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final isRepoThere = Directory(
          path.join(widget.rootDir, ".git"),
        ).existsSync();

        if (!_didInitializeEditors) {
          _didInitializeEditors = true;
          if (widget.isProject) {
            _activeEditorBloc.add(OpenRecentActiveEditor());
          } else {
            final initialController = CodeForgeController(lspConfig: lspConfig);
            _applyPendingAgenticDiffForFile(initialController, target!.path);
            final initialUndoController = UndoRedoController();
            final initialFindController = FindController(initialController);
            _activeEditorBloc.add(
              ActiveEditorEvent([
                ActiveEditor(
                  file: target,
                  controller: initialController,
                  languageDetails: widget.languageDetails!,
                  undoRedoController: initialUndoController,
                  isActive: true,
                  findController: initialFindController,
                  hscroll: ScrollController(),
                  vscroll: ScrollController(),
                ),
              ]),
            );
          }
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _activeEditorBloc),
            BlocProvider(create: (_) => StackBloc()),
            BlocProvider(create: (_) => FindWordBloc()),
            BlocProvider(create: (_) => ApiBloc()),
            BlocProvider(create: (_) => FolderBloc()),
            BlocProvider(create: (_) => AIChatBloc()),
            BlocProvider(create: (_) => AIChatUIBloc()),
            BlocProvider(create: (_) => WorkspaceSearchBloc()),
            BlocProvider(
              create: (_) =>
                  RepoStatusBloc()..add(LoadRepoStatus(widget.rootDir)),
            ),
          ],
          child: BlocListener<WorkspaceSearchBloc, WorkspaceSearchState>(
            listenWhen: (previous, current) =>
                previous.query != current.query ||
                previous.matchCase != current.matchCase ||
                previous.matchWholeWord != current.matchWholeWord ||
                previous.isRegex != current.isRegex,
            listener: (context, searchState) {
              final editorState = context.read<ActiveEditorBloc>().state;
              for (final editor in editorState.activeEditors) {
                if (searchState.query.isEmpty) {
                  _clearSearchHighlighting(editor);
                } else {
                  _applySearchHighlighting(
                    editor,
                    searchState.query,
                    searchState,
                  );
                }
              }
            },
            child: BlocBuilder<ActiveEditorBloc, ActiveEditorState>(
              buildWhen: (previous, current) =>
                  previous.activeEditors.length != current.activeEditors.length,
              builder: (context, editorState) {
                _syncDirtyTracking(editorState.activeEditors);
                final hasDirtyFiles = _hasUnsavedEditors(
                  editorState.activeEditors,
                );
                _updateTabController(editorState.activeEditors.length);
                final activeIndex = editorState.activeEditors.indexWhere(
                  (e) => e.isActive,
                );
                if (activeIndex >= 0 &&
                    tabController != null &&
                    tabController!.index != activeIndex) {
                  tabController!.index = activeIndex;
                  mruOrder.remove(activeIndex);
                  mruOrder.insert(0, activeIndex);
                }
                return PopScope(
                  canPop:
                      _allowImmediatePop ||
                      !_hasUnsavedEditors(editorState.activeEditors),
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) {
                      context.read<ActiveEditorBloc>().add(CloseActiveEditor());
                      return;
                    }

                    final shouldExit = await _handleExitWithUnsavedPrompt(
                      context,
                      editorState.activeEditors,
                    );
                    if (!shouldExit || !context.mounted) {
                      return;
                    }

                    _allowImmediatePop = true;
                    context.read<ActiveEditorBloc>().add(CloseActiveEditor());
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Scaffold(
                    resizeToAvoidBottomInset: true,
                    drawer: BlocBuilder<StackBloc, StackState>(
                      buildWhen: (previous, current) => current != previous,
                      builder: (context, state) {
                        return Drawer(
                          width: 350,
                          backgroundColor: appTheme.editorPageDrawerBg,
                          child: Row(
                            children: [
                              Container(
                                color: appTheme.editorPageToolbarBg,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 25),
                                    drawerButtons(
                                      () => context.read<StackBloc>().add(
                                        StackIndexChange(stackValue: 0),
                                      ),
                                      Icons.file_copy_outlined,
                                      color: state.stackIndex == 0
                                          ? appTheme.editorPageToolSelectedColor
                                          : appTheme.editorPageToolColor,
                                      bgColor: state.stackIndex == 0
                                          ? appTheme
                                                .editorPageToolSelectedBgColor
                                          : Colors.transparent,
                                    ),
                                    drawerButtons(
                                      () => context.read<StackBloc>().add(
                                        StackIndexChange(stackValue: 1),
                                      ),
                                      Icons.search,
                                      color: state.stackIndex == 1
                                          ? appTheme.editorPageToolSelectedColor
                                          : appTheme.editorPageToolColor,
                                      bgColor: state.stackIndex == 1
                                          ? appTheme
                                                .editorPageToolSelectedBgColor
                                          : Colors.transparent,
                                    ),
                                    drawerButtons(
                                      () => context.read<StackBloc>().add(
                                        StackIndexChange(stackValue: 2),
                                      ),
                                      FontAwesomeIcons.codeBranch,
                                      color: state.stackIndex == 2
                                          ? appTheme.editorPageToolSelectedColor
                                          : appTheme.editorPageToolColor,
                                      bgColor: state.stackIndex == 2
                                          ? appTheme
                                                .editorPageToolSelectedBgColor
                                          : Colors.transparent,
                                    ),
                                    drawerButtons(
                                      () => context.read<StackBloc>().add(
                                        StackIndexChange(stackValue: 3),
                                      ),
                                      SvgPicture.asset(
                                        'assets/icons/rest-api-icon.svg',
                                        height: 34,
                                        width: 34,
                                        colorFilter: ColorFilter.mode(
                                          state.stackIndex == 3
                                              ? appTheme
                                                    .editorPageToolSelectedColor
                                              : appTheme.editorPageToolColor,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      bgColor: state.stackIndex == 3
                                          ? appTheme
                                                .editorPageToolSelectedBgColor
                                          : Colors.transparent,
                                    ),
                                    drawerButtons(
                                      () => context.read<StackBloc>().add(
                                        StackIndexChange(stackValue: 4),
                                      ),
                                      SvgPicture.asset(
                                        'assets/icons/ai.svg',
                                        height: 34,
                                        width: 34,
                                      ),
                                      bgColor: state.stackIndex == 4
                                          ? appTheme
                                                .editorPageToolSelectedBgColor
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5,
                                        vertical: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: IndexedStack(
                                  index: state.stackIndex,
                                  children: [
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 20,
                                        ),
                                        child: ListView(
                                          children: [
                                            if (editorState
                                                .activeEditors
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'OPEN EDITORS',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            appTheme.isDark
                                                            ? FontWeight.w300
                                                            : FontWeight.w500,
                                                        color: appTheme
                                                            .selectScreenCardTextColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    ...List.generate(
                                                      editorState
                                                          .activeEditors
                                                          .length,
                                                      (index) {
                                                        final editor = editorState
                                                            .activeEditors[index];
                                                        return InkWell(
                                                          onTap: () {
                                                            final List<
                                                              ActiveEditor
                                                            >
                                                            currentState =
                                                                List.from(
                                                                  editorState
                                                                      .activeEditors,
                                                                );
                                                            for (
                                                              int i = 0;
                                                              i <
                                                                  currentState
                                                                      .length;
                                                              i++
                                                            ) {
                                                              currentState[i]
                                                                      .isActive =
                                                                  i == index;
                                                            }
                                                            context
                                                                .read<
                                                                  ActiveEditorBloc
                                                                >()
                                                                .add(
                                                                  ActiveEditorEvent(
                                                                    currentState,
                                                                  ),
                                                                );
                                                            if (tabController !=
                                                                    null &&
                                                                tabController!
                                                                        .length >
                                                                    index) {
                                                              tabController!
                                                                  .animateTo(
                                                                    index,
                                                                  );
                                                            }
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 2,
                                                                ),
                                                            child: Text(
                                                              _displayFileName(
                                                                editor,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                color: appTheme
                                                                    .selectScreenCardTextColor,
                                                                fontWeight:
                                                                    editor
                                                                        .isActive
                                                                    ? FontWeight
                                                                          .w600
                                                                    : FontWeight
                                                                          .w400,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 14),
                                                  ],
                                                ),
                                              ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 15,
                                                ),
                                                child: Text(
                                                  "EXPLORER",
                                                  style: TextStyle(
                                                    fontWeight: appTheme.isDark
                                                        ? FontWeight.w300
                                                        : FontWeight.w500,
                                                    color: appTheme
                                                        .selectScreenCardTextColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DirectoryTreeViewerCustom(
                                              appTheme: appTheme,
                                              isUnfoldedFirst: false,
                                              rootPath: widget.rootDir,
                                              enableCreateFileOption: true,
                                              enableDeleteFileOption: true,
                                              enableDeleteFolderOption: true,
                                              enableCreateFolderOption: true,
                                              enableRenameFileOption: true,
                                              enableRenameFolderOption: true,
                                              enableGitFeatures: true,
                                              editingFieldStyle: EditingFieldStyle(
                                                textFieldWidth: MediaQuery.of(
                                                  context,
                                                ).size.width,
                                                textStyle: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                                cursorColor: Colors.grey,
                                                cursorHeight: 19,
                                                verticalTextAlign:
                                                    TextAlignVertical.top,
                                                textfieldDecoration:
                                                    const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.fromLTRB(
                                                            12.0,
                                                            8.0,
                                                            12.0,
                                                            1.0,
                                                          ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                  Radius.circular(
                                                                    2,
                                                                  ),
                                                                ),
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                2,
                                                              ),
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                folderIcon: const Icon(
                                                  Icons.folder,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                fileIcon: const Icon(
                                                  Icons.edit_document,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                doneIcon: const Icon(
                                                  Icons.check,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                                cancelIcon: const Icon(
                                                  Icons.close,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
                                              ),
                                              fileIconBuilder: (ext) {
                                                return SizedBox(
                                                  height: 25,
                                                  width: 25,
                                                  child:languages.firstWhere(
                                                    (lang) => lang.extension.contains(ext.replaceFirst(".", "")),
                                                    orElse: () => languages[0]).icon ?? FileIcon(ext),
                                                );
                                              },
                                              folderStyle: FolderStyle(
                                                iconForCreateFolder: Icon(
                                                  Icons.create_new_folder,
                                                  color: appTheme.isDark
                                                    ? Colors.grey
                                                    : const Color(0xff2b2b2b),
                                                ),
                                                iconForCreateFile: Icon(
                                                  FontAwesomeIcons.fileCirclePlus,
                                                  size: 20,
                                                  color: appTheme.isDark
                                                    ? Colors.grey
                                                    : const Color(0xff2b2b2b),
                                                ),
                                                rootFolderClosedIcon:
                                                    const Icon(
                                                      Icons.chevron_right_sharp,
                                                      color: Colors.grey,
                                                    ),
                                                rootFolderOpenedIcon: const Icon(
                                                  Icons.keyboard_arrow_down_sharp,
                                                  color: Colors.grey,
                                                ),
                                                folderClosedicon:SvgPicture.asset(
                                                    'assets/icons/folder.svg',
                                                    height: 30,
                                                    width: 30,
                                                  ),
                                                folderOpenedicon: SvgPicture.asset(
                                                  'assets/icons/open-file-folder.svg',
                                                  height: 30,
                                                  width: 30,
                                                ),
                                                folderNameStyle: TextStyle(
                                                  color: appTheme.selectScreenCardTextColor,
                                                  fontSize: 20,
                                                  fontWeight: appTheme.isDark
                                                    ? FontWeight.w400
                                                    : FontWeight.w500,
                                                ),
                                              ),
                                              fileStyle: FileStyle(
                                                iconForDeleteFile: Icon(
                                                  Icons.delete,
                                                  size: 25,
                                                  color: Colors.red[300],
                                                ),
                                                fileNameStyle: TextStyle(
                                                  color: appTheme.selectScreenCardTextColor,
                                                  fontSize: 20,
                                                  fontWeight: appTheme.isDark
                                                    ? FontWeight.w400
                                                    : FontWeight.w500,
                                                  height: 2,
                                                ),
                                              ),
                                              onFileTap: (f) async {
                                                final List<ActiveEditor>
                                                currentState = List.from(
                                                  editorState.activeEditors,
                                                );
                                                final canonicalPath =
                                                    File(f.path).absolute.path;
                                                final existingIndex =
                                                    currentState.indexWhere(
                                                      (editor) =>File(editor.file.path).absolute.path ==canonicalPath);

                                                if (existingIndex >= 0) {
                                                  for (int i = 0; i < currentState.length; i++) {
                                                    currentState[i].isActive = i == existingIndex;
                                                  }
                                                  if (context.mounted) {
                                                    context.read<ActiveEditorBloc>().add(ActiveEditorEvent(currentState),);
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (tabController != null && existingIndex < tabController!.length) {
                                                        tabController!.animateTo(existingIndex);
                                                      }
                                                    });
                                                  }
                                                  return;
                                                }

                                                for (ActiveEditor item
                                                    in currentState) {
                                                  item.isActive = false;
                                                }
                                                final lang = languages.firstWhere((language) => language.extension.contains(
                                                  path.extension(f.path,).replaceFirst(".","")),
                                                  orElse: () => languages[0]);
                                                final bloc = context
                                                    .read<ActiveEditorBloc>();
                                                final languageId =
                                                    _lspLanguageIdForPath(
                                                      lang,
                                                      f.path,
                                                    );
                                                LspConfig? lspConfig;
                                                if (uiBloc.state.codeForgeConfig['enableLSP']) {
                                                  lspConfig = await bloc.getOrStartSharedLspConfig(
                                                    languageId: languageId,
                                                    ext: lang.extension[0],
                                                    executable: lang.lspExecutable,
                                                    args: lang.args ?? [],
                                                    capabilities: _getLspCapabilities(
                                                      uiBloc.state.codeForgeConfig,
                                                      lang.name.toLowerCase(),
                                                    ),
                                                  );
                                                }
                                                final newController = CodeForgeController(lspConfig: lspConfig);
                                                _applyPendingAgenticDiffForFile(newController, f.path);
                                                final newHscroll = ScrollController();
                                                final newVscroll = ScrollController();
                                                currentState.add(
                                                  ActiveEditor(
                                                    controller: newController,
                                                    undoRedoController: UndoRedoController(),
                                                    file: f,
                                                    isActive: true,
                                                    languageDetails: lang,
                                                    findController: FindController(newController,),
                                                    hscroll: newHscroll,
                                                    vscroll: newVscroll,
                                                  ),
                                                );
                                                mruOrder.insert(0, currentState.length - 1);
                                                if (context.mounted) {
                                                  context.read<ActiveEditorBloc>().add(ActiveEditorEvent(currentState),);
                                                  WidgetsBinding.instance .addPostFrameCallback((_) {
                                                    final newIndex = currentState.indexWhere((item) => item.isActive ==true);
                                                    if (tabController != null && tabController! .length > newIndex && newIndex >= 0) {
                                                      tabController!.animateTo(newIndex,);
                                                    }
                                                    _applyWorkspaceSearchToActiveEditor();
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    FindWordWidget(
                                      appTheme: appTheme,
                                      findWordController: findWordController,
                                      editorState: editorState,
                                      replaceWordController:
                                          replaceWordController,
                                      tabController: tabController,
                                      workspacePath: widget.rootDir,
                                      onFileOpen: (file, lineNumber, searchQuery) async {
                                        final List<ActiveEditor> currentState =
                                            List.from(
                                              editorState.activeEditors,
                                            );
                                        final canonicalPath = File(file.path).absolute.path;
                                        final existingIndex = currentState.indexWhere(
                                          (editor) => File(editor.file.path).absolute.path == canonicalPath,
                                        );

                                        if (existingIndex >= 0) {
                                          for (int i = 0; i < currentState.length; i++) {
                                            currentState[i].isActive = i == existingIndex;
                                          }
                                          context.read<ActiveEditorBloc>().add(
                                            ActiveEditorEvent(currentState),
                                          );
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (tabController != null && existingIndex < tabController!.length) {
                                              tabController!.animateTo(existingIndex);
                                            }
                                            final editor = currentState[existingIndex];
                                            if (editor.findController != null && searchQuery.isNotEmpty) {
                                              _goToMatchNearLine(
                                                editor,
                                                lineNumber,
                                                searchQuery,
                                              );
                                            }
                                          });
                                        } else {
                                          for (ActiveEditor item
                                              in currentState) {
                                            item.isActive = false;
                                          }
                                          final lang = languages.firstWhere(
                                            (language) =>
                                                language.extension.contains(
                                                  path
                                                      .extension(file.path)
                                                      .replaceFirst(".", ""),
                                                ),
                                            orElse: () => languages[0],
                                          );
                                          final bloc = context
                                              .read<ActiveEditorBloc>();
                                          final languageId =
                                              _lspLanguageIdForPath(
                                                lang,
                                                file.path,
                                              );
                                          LspConfig? newLspConfig;
                                          if (uiBloc.state.codeForgeConfig['enableLSP']) {
                                            newLspConfig = await bloc.getOrStartSharedLspConfig(
                                              languageId: languageId,
                                              ext: lang.extension[0],
                                              executable: lang.lspExecutable,
                                              args: lang.args ?? [],
                                              capabilities:_getLspCapabilities(
                                                uiBloc.state.codeForgeConfig,
                                                lang.name.toLowerCase(),
                                              ),
                                            );
                                          }
                                          final newController =
                                              CodeForgeController(
                                                lspConfig: newLspConfig,
                                              );
                                          _applyPendingAgenticDiffForFile(
                                            newController,
                                            file.path,
                                          );
                                          final newFindController =
                                              FindController(newController);
                                          final newHscroll = ScrollController();
                                          final newVscroll = ScrollController();
                                          currentState.add(
                                            ActiveEditor(
                                              controller: newController,
                                              undoRedoController:
                                                  UndoRedoController(),
                                              file: file,
                                              isActive: true,
                                              languageDetails: lang,
                                              findController: newFindController,
                                              hscroll: newHscroll,
                                              vscroll: newVscroll,
                                            ),
                                          );
                                          mruOrder.insert(
                                            0,
                                            currentState.length - 1,
                                          );
                                          if (context.mounted) {
                                            context
                                                .read<ActiveEditorBloc>()
                                                .add(
                                                  ActiveEditorEvent(
                                                    currentState,
                                                  ),
                                                );
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              final newIndex = currentState.indexWhere(
                                                (item) => item.isActive == true);
                                              if (tabController != null && tabController!.length > newIndex && newIndex >= 0) {
                                                tabController!.animateTo(
                                                  newIndex,
                                                );
                                              }
                                              if (searchQuery.isNotEmpty) {
                                                Future.delayed(
                                                  const Duration(
                                                    milliseconds: 100,
                                                  ),
                                                  () {
                                                    _goToMatchNearLine(
                                                      currentState.last,
                                                      lineNumber,
                                                      searchQuery,
                                                    );
                                                  },
                                                );
                                              }
                                            });
                                          }
                                        }
                                      },
                                    ),
                                    SourceControl(
                                      appTheme: appTheme,
                                      workSpace: widget.rootDir,
                                      isRepoThere: isRepoThere,
                                      activeEditorsBloc:
                                          BlocProvider.of<ActiveEditorBloc>(
                                            context,
                                            listen: false,
                                          ),
                                      onOpenDiffView:(fileName, workspacePath, bloc) async {
                                            try {
                                              final diffResult = await getGitDiff(fileName, workspacePath);
                                              final file = File(path.join(workspacePath,fileName),
                                              );
                                              if (!await file.exists()) return;

                                              final lang = languages.firstWhere(
                                                (language) =>
                                                  language.extension.contains(
                                                    path.extension(file.path).replaceFirst(".", ""),
                                                  ),
                                                orElse: () => languages[0],
                                              );

                                              final tempFile = File(
                                                "$tempDir/(Working Tree)${path.basename(fileName)}",
                                              );
                                              if (!(await tempFile.exists())) {
                                                await tempFile.create(
                                                  recursive: true,
                                                );
                                              }
                                              await tempFile.writeAsString(
                                                diffResult.diffText,
                                              );

                                              final currentState =
                                                  List<ActiveEditor>.from(
                                                    editorState.activeEditors,
                                                  );
                                              final canonicalDiffPath =
                                                  tempFile.absolute.path;
                                              final existingIndex = currentState
                                                  .indexWhere(
                                                    (editor) =>
                                                        File(editor.file.path)
                                                            .absolute
                                                            .path ==
                                                        canonicalDiffPath,
                                                  );

                                              if (existingIndex >= 0) {
                                                for (
                                                  int i = 0;
                                                  i < currentState.length;
                                                  i++
                                                ) {
                                                  currentState[i].isActive =
                                                      i == existingIndex;
                                                }

                                                final existingEditor =
                                                    currentState[existingIndex];
                                                existingEditor.controller.readOnly =
                                                    true;
                                                existingEditor
                                                    .controller
                                                    .setGitDiffDecorations(
                                                      addedRanges:
                                                          diffResult.addedRanges,
                                                      removedRanges: diffResult
                                                          .removedRanges,
                                                      addedColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            0,
                                                            255,
                                                            8,
                                                          ),
                                                      removedColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            255,
                                                            0,
                                                            0,
                                                          ),
                                                      modifiedColor:
                                                          const Color(0xFF2196F3),
                                                    );
                                                existingEditor.controller.text =
                                                    diffResult.diffText;

                                                if (context.mounted) {
                                                  bloc.add(
                                                    ActiveEditorEvent(
                                                      currentState,
                                                    ),
                                                  );
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback((_) {
                                                        if (tabController !=
                                                                null &&
                                                            existingIndex >=
                                                                0 &&
                                                            existingIndex <
                                                                tabController!
                                                                    .length) {
                                                          tabController!
                                                              .animateTo(
                                                                existingIndex,
                                                              );
                                                        }
                                                        existingEditor
                                                            .controller
                                                            .notifyListeners();
                                                      });
                                                }
                                                return;
                                              }

                                              final newController =
                                                  CodeForgeController();
                                              newController.readOnly = true;

                                              newController
                                                  .setGitDiffDecorations(
                                                    addedRanges:
                                                        diffResult.addedRanges,
                                                    removedRanges: diffResult
                                                        .removedRanges,
                                                    addedColor:
                                                        const Color.fromARGB(
                                                          255,
                                                          0,
                                                          255,
                                                          8,
                                                        ),
                                                    removedColor:
                                                        const Color.fromARGB(
                                                          255,
                                                          255,
                                                          0,
                                                          0,
                                                        ),
                                                    modifiedColor: const Color(
                                                      0xFF2196F3,
                                                    ),
                                                  );

                                              final newEditor = ActiveEditor(
                                                controller: newController,
                                                undoRedoController:
                                                    UndoRedoController(),
                                                file: tempFile,
                                                isActive: true,
                                                languageDetails: lang,
                                                findController: FindController(
                                                  newController,
                                                ),
                                                customTitle:
                                                    '${path.basename(fileName)}(Working Tree)',
                                                hscroll: ScrollController(),
                                                vscroll: ScrollController(),
                                              );

                                              for (final editor
                                                  in currentState) {
                                                editor.isActive = false;
                                              }
                                              currentState.add(newEditor);

                                              if (context.mounted) {
                                                mruOrder.insert(
                                                  0,
                                                  currentState.length - 1,
                                                );
                                                bloc.add(
                                                  ActiveEditorEvent(
                                                    currentState,
                                                  ),
                                                );
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      newEditor.controller
                                                          .notifyListeners();
                                                      final newIndex =
                                                          currentState.length -
                                                          1;
                                                      if (tabController !=
                                                              null &&
                                                          newIndex >= 0) {
                                                        tabController!
                                                            .animateTo(
                                                              newIndex,
                                                            );
                                                      }
                                                    });
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to open diff view: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    ),
                                    APITesting(
                                      params: params,
                                      headers: headers,
                                      apiUrlController: apiUrlController,
                                      appTheme: appTheme,
                                      paramTabController: paramTabController,
                                      apiTabController: apiTabController,
                                    ),
                                    AIChat(
                                      filePath:
                                          editorState.activeEditors.isNotEmpty
                                          ? editorState
                                                .activeEditors[(tabController !=
                                                        null
                                                    ? tabController!.index
                                                    : editorState.activeEditors
                                                          .indexWhere(
                                                            (item) =>
                                                                item.isActive ==
                                                                true,
                                                          ))]
                                                .file
                                                .path
                                          : '',
                                      workspacePath: widget.rootDir,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    appBar: AppBar(
                      title: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: tabController == null
                            ? Text(
                                editorState.activeEditors.isNotEmpty
                                    ? _displayFileName(
                                        editorState.activeEditors[0],
                                      )
                                    : '',
                                style: TextStyle(
                                  color: appTheme.selectScreenCardTextColor,
                                ),
                              )
                            : AnimatedBuilder(
                                animation: tabController!,
                                builder: (context, _) {
                                  int idx = tabController!.index;
                                  if (idx < 0 || idx >= editorState.activeEditors.length) {
                                    idx = 0;
                                  }
                                  final fileName =
                                      editorState.activeEditors.isNotEmpty
                                      ? _displayFileName(
                                          editorState.activeEditors[idx],
                                        )
                                      : '';
                                  return Text(
                                    fileName,
                                    style: TextStyle(
                                      color: appTheme.selectScreenCardTextColor,
                                    ),
                                  );
                                },
                              ),
                      ),
                      bottom: editorState.activeEditors.isNotEmpty
                          ? TabBar(
                              labelPadding: EdgeInsets.zero,
                              padding: EdgeInsets.zero,
                              indicator: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Color(0xff157dcc),
                                    width: 2,
                                  ),
                                  left: BorderSide(
                                    color: appTheme.isDark
                                        ? Colors.grey
                                        : Colors.blueGrey[600]!,
                                    width: 0.2,
                                  ),
                                  right: BorderSide(
                                    color: appTheme.isDark
                                        ? Colors.grey
                                        : Colors.blueGrey[600]!,
                                    width: 0.2,
                                  ),
                                ),
                              ),
                              labelColor: appTheme.selectScreenCardTextColor,
                              unselectedLabelColor: appTheme.isDark
                                  ? null
                                  : Colors.grey[400],
                              dividerColor: Colors.transparent,
                              controller: tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              onTap: (value) {
                                mruOrder.remove(value);
                                mruOrder.insert(0, value);
                                if (tabController != null &&
                                    tabController!.index != value) {
                                  tabController!.animateTo(value);
                                }
                              },
                              tabs: List.generate(
                                editorState.activeEditors.length,
                                (index) {
                                  return Tab(
                                    height: 32,
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Text(
                                            _displayFileName(
                                              editorState.activeEditors[index],
                                            ),
                                            softWrap: false,
                                            maxLines: 1,
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () async {
                                            final List<ActiveEditor>
                                            currentState = List.from(
                                              editorState.activeEditors,
                                            );
                                            if (currentState.length <= 1) {
                                              context.read<ActiveEditorBloc>().add(ActiveEditorEvent([]));
                                              context.read<ActiveEditorBloc>().add(CloseActiveEditor());
                                              return;
                                            }

                                            try {
                                              await currentState[index].dispose();
                                            } catch (e) {
                                              debugPrint('Error disposing editor: $e');
                                            }

                                            if (currentState[index].customTitle?.contains("(Working Tree)",) == true) {
                                              try {
                                                await currentState[index].file.delete();
                                              } catch (e) {
                                                debugPrint(e.toString());
                                              }
                                            }

                                            final wasActive = currentState[index].isActive;
                                            currentState.removeAt(index);
                                            mruOrder.remove(index);
                                            mruOrder = mruOrder
                                                .map(
                                                  (i) => i > index ? i - 1 : i,
                                                )
                                                .toList();
                                            if (currentState.isNotEmpty &&
                                                wasActive) {
                                              int newActive =
                                                  mruOrder.isNotEmpty
                                                  ? mruOrder[0]
                                                  : 0;
                                              for (
                                                int i = 0;
                                                i < currentState.length;
                                                i++
                                              ) {
                                                currentState[i].isActive =
                                                    i == newActive;
                                              }
                                            }
                                            if (context.mounted) {
                                              context.read<ActiveEditorBloc>().add(ActiveEditorEvent(currentState));
                                            }

                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              final newIndex = currentState.indexWhere(
                                                (item) => item.isActive == true);
                                              if (tabController != null && newIndex >= 0 && newIndex < tabController!.length) {
                                                tabController!.animateTo(newIndex,);
                                              }
                                            });
                                          },
                                          icon: Icon(Icons.close, size: 20),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : null,
                      actions: [
                        if (!autoSaveEnabled)
                          OutlinedButton.icon(
                            onPressed: hasDirtyFiles
                                ? () => _saveActiveEditor(
                                    context,
                                    editorState.activeEditors,
                                  )
                                : null,
                            icon: Icon(
                              Icons.save_outlined,
                              size: 17,
                              color: hasDirtyFiles
                                  ? appTheme.editorPageToolSelectedColor
                                  : appTheme.editorPageToolColor.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            label: Text(
                              'Save',
                              style: TextStyle(
                                color: hasDirtyFiles
                                    ? appTheme.editorPageToolSelectedColor
                                    : appTheme.editorPageToolColor.withValues(
                                        alpha: 0.6,
                                      ),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: hasDirtyFiles
                                  ? appTheme.editorPageToolSelectedBgColor
                                        .withValues(alpha: 0.35)
                                  : appTheme.editorPageDrawerBg,
                              side: BorderSide(
                                color: hasDirtyFiles
                                    ? appTheme.editorPageToolColor.withValues(
                                        alpha: 0.45,
                                      )
                                    : appTheme.editorPageToolColor.withValues(
                                        alpha: 0.25,
                                      ),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () async {
                            if (editorState.activeEditors.isEmpty) return;
                            final temp = Directory(tempDir);
                            if (!temp.existsSync()) {
                              temp.createSync(recursive: true);
                            }
                            final activeEditorForRun =
                                tabController != null &&
                                    tabController!.index <
                                        editorState.activeEditors.length
                                ? editorState.activeEditors[tabController!
                                      .index]
                                : editorState.activeEditors.firstWhere(
                                    (item) => item.isActive == true,
                                    orElse: () =>
                                        editorState.activeEditors.first,
                                  );
                            final File filePath = activeEditorForRun.file;
                            final viteTs = File(
                              path.join(widget.rootDir, 'vite.config.ts'),
                            );
                            final viteJs = File(
                              path.join(widget.rootDir, 'vite.config.js'),
                            );
                            final nextTs = File(
                              path.join(widget.rootDir, 'next.config.ts'),
                            );
                            final nextJs = File(
                              path.join(widget.rootDir, 'next.config.js'),
                            );

                            final packageJson = File(
                              path.join(widget.rootDir, 'package.json'),
                            );

                            final hasVite =
                                await viteTs.exists() || await viteJs.exists();
                            final hasNext =
                                await nextTs.exists() || await nextJs.exists();
                            final hasPkg = await packageJson.exists();

                            if (hasVite && hasPkg && context.mounted) {
                              runCode(
                                context,
                                "node node_modules/vite/bin/vite.js",
                                widget.rootDir,
                              );
                              return;
                            }

                            if (hasNext && hasPkg && context.mounted) {
                              runCode(
                                context,
                                "npm install --ignore-scripts && npm uninstall lightningcss && node node_modules/next/dist/bin/next dev --webpack",
                                widget.rootDir,
                              );
                              return;
                            }

                            final String extention = path.extension(
                              filePath.path,
                            );
                            if (!context.mounted) return;
                            switch (extention) {
                              case '.html':
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            scondaryAnimation,
                                          ) =>
                                              WebViewScreen(htmlFile: filePath),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return SizeTransition(
                                              sizeFactor: animation,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                }
                                break;
                              case '.c':
                                final String compileCommand =
                                    "clang -fPIC -shared ${filePath.path} -o  ${temp.path}/libtemp.so";
                                final String runCommand =
                                    'clangloader ${temp.path}/libtemp.so';
                                runCode(
                                  context,
                                  "$compileCommand && $runCommand",
                                  widget.rootDir,
                                );
                                break;
                              case '.cpp':
                              case '.c++':
                              case '.cc':
                                final String compileCommand =
                                    "clang++ -fPIC -shared ${filePath.path} -o  ${temp.path}/libtemp.so";
                                final String runCommand =
                                    'clangloader ${temp.path}/libtemp.so';
                                runCode(
                                  context,
                                  "$compileCommand && $runCommand",
                                  widget.rootDir,
                                );
                                break;
                              case '.java':
                                final String compileCommand = "javac ${filePath.path} -d ${temp.path}";
                                final String runCommand = "cd ${temp.path} && java ${path.basenameWithoutExtension(filePath.path)}";
                                runCode( context, "$compileCommand && $runCommand", widget.rootDir);
                                break;
                              case '.kt':
                              case '.kts':
                                final String compileCommand = 'echo Compiling... && kotlinc ${filePath.path} -include-runtime -d ${temp.path}/temp.jar';
                                final String runCommand = 'java -jar ${temp.path}/temp.jar';
                                runCode(context, "$compileCommand && $runCommand", widget.rootDir);
                                break;
                              case '.ts':
                                final String compileCommand = "tsc ${filePath.path} --outDir ${temp.path}";
                                final String runCommand = "node ${temp.path}/${path.basenameWithoutExtension(filePath.path)}.js";
                                runCode(context, "$compileCommand && $runCommand", widget.rootDir);
                                break;
                              case '.md':
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder:(context, animation, scondaryAnimation) => MdView(
                                      data: filePath.readAsStringSync(),
                                      appTheme: appTheme,
                                      theme: context.read<ConfigBloc>().state,
                                    ),
                                    transitionsBuilder:(context, animation, secondaryAnimation, child) {
                                      return SizeTransition(
                                        sizeFactor: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                                break;
                              default:
                                final lang = languages.firstWhere(
                                  (language) => language.extension.contains(
                                    path
                                        .extension(filePath.path)
                                        .replaceFirst(".", ""),
                                  ),
                                  orElse: () => languages[0],
                                );
                                final String command = lang.command ?? '';
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder:(context, animation, scondaryAnimation) => SetupTerminal(
                                      projectDir: widget.rootDir,
                                      args: [
                                        "-c",
                                        "$command ${filePath.path}",
                                      ],
                                    ),
                                    transitionsBuilder:(context, animation, secondaryAnimation, child,) {
                                      return SizeTransition(
                                        sizeFactor: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, scondaryAnimation) =>
                                        SetupTerminal(
                                          projectDir: widget.rootDir,
                                        ),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return SizeTransition(
                                        sizeFactor: animation,
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          },
                          icon: const Icon(Icons.terminal),
                        ),
                      ],
                    ),
                    body: editorState.activeEditors.isNotEmpty
                        ? TabBarView(
                            controller: tabController,
                            children: editorState.activeEditors
                                .map(
                                  (editor) => EditorArea(
                                    key: ValueKey(editor.file.path),
                                    editor: editor,
                                    appTheme: appTheme,
                                    workspacePath: widget.rootDir,
                                    tabController: tabController,
                                  ),
                                )
                                .toList(),
                          )
                        : SingleChildScrollView(
                            child: Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    "Open a file to Edit",
                                    style: TextStyle(
                                      color: appTheme.selectScreenCardTextColor,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: Column(
                                      children: [
                                        Text(
                                          isRepoThere
                                            ? "Version control (.git) found \u2713"
                                            : "No version control (.git) found on this folder/project",
                                          style: TextStyle(
                                            color: Colors.grey[appTheme.isDark ? 500 : 600],
                                          ),
                                        ),
                                        if (!widget.isCloned)
                                          Card(
                                            child: Wrap(
                                              children: [
                                                Padding(
                                                  padding:
                                                    const EdgeInsets.only(left: 15,top: 8, bottom: 8),
                                                  child: Text(
                                                    "Note: This is a clone of the selected folder in VSDroid's private directory. Modifications here will not affect the original folder.",
                                                    style: TextStyle(
                                                      color: Colors.grey[appTheme.isDark ? 500 : 600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
