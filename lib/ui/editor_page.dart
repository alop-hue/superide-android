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
import 'webview.dart';
import '../bloc/ui_bloc/ui_bloc.dart';
import '../terminal/terminal.dart';
import '../utils/languages.dart';
import '../utils/functions.dart';
import '../utils/themes.dart';
import '../utils/widgets.dart';

class EditorPage extends StatefulWidget {
  final Language languageDetails;
  final String rootDir;
  final File? filePath;
  const EditorPage({super.key, required this.languageDetails, this.filePath, required this.rootDir});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with TickerProviderStateMixin {
  final createFileKey = GlobalKey<FormState>();
  final trasnformationController = TransformationController();
  late final TextEditingController createFileController, findWordController;
  late final TextEditingController replaceWordController, apiUrlController;
  late final TabController apiTabController, paramTabController;
  late List<int> mruOrder;
  Map<String,String> params = {}, headers = {};
  TabController? tabController;

  @override 
  void initState(){
    mruOrder = [0];
    createFileController = TextEditingController();
    findWordController = TextEditingController();
    replaceWordController = TextEditingController();
    apiUrlController = TextEditingController();
    trasnformationController.value = Matrix4.identity()..scaleByVector3(Vector3(1.45, 1.45, 1.45));
    apiTabController =  TabController(length: 3, vsync: this);
    paramTabController = TabController(length: 3, vsync: this);
    
    super.initState();
  }

  @override
  void dispose() {
    apiUrlController.dispose();
    apiTabController.dispose();
    paramTabController.dispose();
    findWordController.dispose();
    trasnformationController.dispose();
    tabController?.removeListener(_onTabChanged);
    tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int tabCount) {
    if (tabController == null || tabController!.length != tabCount) {
      tabController?.removeListener(_onTabChanged);
      tabController?.dispose();
      tabController = TabController(length: tabCount, vsync: this);
      tabController!.addListener(_onTabChanged);
    }
  }

  /// Callback when tab changes - apply workspace search highlighting to the new active tab
  void _onTabChanged() {
    if (tabController == null || !tabController!.indexIsChanging) return;
    
    // Get the workspace search state and apply to newly active editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyWorkspaceSearchToActiveEditor();
    });
  }

  /// Apply workspace search highlighting to the currently active editor
  void _applyWorkspaceSearchToActiveEditor() {
    if (!mounted) return;
    
    try {
      final searchState = context.read<WorkspaceSearchBloc>().state;
      final editorState = context.read<ActiveEditorsBloc>().state;
      
      if (searchState.query.isEmpty) return;
      if (editorState.activeEditors.isEmpty) return;
      
      final activeIndex = tabController?.index ?? 0;
      if (activeIndex < 0 || activeIndex >= editorState.activeEditors.length) return;
      
      final editor = editorState.activeEditors[activeIndex];
      _applySearchHighlighting(editor, searchState.query, searchState);
    } catch (_) {
      // Context might not have the bloc available yet
    }
  }

  /// Apply search highlighting to an editor without showing the find panel
  void _applySearchHighlighting(ActiveEditors editor, String query, WorkspaceSearchState searchState) {
    if (editor.findController == null) return;
    
    final findController = editor.findController!;
    
    // Set search options to match workspace search settings
    findController.caseSensitive = searchState.matchCase;
    findController.matchWholeWord = searchState.matchWholeWord;
    findController.isRegex = searchState.isRegex;
    
    // Apply highlighting without scrolling (just highlight the matches)
    findController.findInputController.text = query;
    findController.find(query, scrollToMatch: false);
  }

  /// Clear search highlighting from an editor
  void _clearSearchHighlighting(ActiveEditors editor) {
    if (editor.findController == null) return;
    editor.findController!.find('', scrollToMatch: false);
    editor.findController!.findInputController.clear();
  }

  /// Navigate to a specific match on or near the target line.
  /// Uses manual match calculation and navigation since find() positions
  /// based on cursor which may not update synchronously.
  void _goToMatchNearLine(ActiveEditors editor, int targetLine, String searchQuery) {
    if (editor.findController == null) return;
    
    final findController = editor.findController!;
    final codeController = editor.controller;
    final text = codeController.text;
    
    // First trigger find to populate matches
    findController.findInputController.text = searchQuery;
    findController.find(searchQuery);
    
    if (findController.matchCount == 0) return;
    
    // Calculate character offset for the start of target line
    final lines = text.split('\n');
    int targetCharOffset = 0;
    for (int i = 0; i < targetLine - 1 && i < lines.length; i++) {
      targetCharOffset += lines[i].length + 1; // +1 for newline
    }
    
    // Calculate end of target line
    int targetLineEnd = targetCharOffset;
    if (targetLine - 1 < lines.length) {
      targetLineEnd += lines[targetLine - 1].length;
    }
    
    // Find all occurrences of the search query in text
    final lowerText = findController.caseSensitive ? text : text.toLowerCase();
    final lowerQuery = findController.caseSensitive ? searchQuery : searchQuery.toLowerCase();
    
    final matchPositions = <int>[];
    int pos = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, pos);
      if (index == -1) break;
      matchPositions.add(index);
      pos = index + 1;
    }
    
    if (matchPositions.isEmpty) return;
    
    // Find which match index is on or closest to the target line
    int bestMatchIndex = 0;
    for (int i = 0; i < matchPositions.length; i++) {
      final matchStart = matchPositions[i];
      
      // Check if this match is on the target line
      if (matchStart >= targetCharOffset && matchStart <= targetLineEnd) {
        bestMatchIndex = i;
        break;
      }
    }
    
    // Navigate to the target match using next() from current position
    // findController.currentMatchIndex is where we are now (usually 0 after find())
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

  @override
  Widget build(BuildContext context) {
    final AppTheme appTheme = context.read<AppThemeBloc>().state.appTheme;
    final ConfigBloc uiBloc = BlocProvider.of<ConfigBloc>(context);
    return FutureBuilder(
      future: Future.wait([
        widget.filePath == null
        ? setTempFile(widget.languageDetails.extension[0])
        : Future.value(widget.filePath),
        (() async {
          final prefs = await SharedPreferences.getInstance();
          List<dynamic> storedData = jsonDecode(await getRecent());
          final File file = widget.filePath ?? await setTempFile(widget.languageDetails.extension[0]);
          final dataToInsert = {file.path: widget.rootDir};
          final Set<String> uniquePaths = {};
          storedData.insert(0, dataToInsert);
          final List<dynamic> uniqueData = [];
          for (final data in storedData) {
            final path = data.keys.toList()[0];
            if (!uniquePaths.contains(path)) {
              uniquePaths.add(path);
              uniqueData.add(data);
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
      uiBloc.state.codeForgeConfig['enableLSP'] && !(uiBloc.state.codeForgeConfig["LSPdisabledLangs"] as List<dynamic>).cast<String>().contains(widget.languageDetails.name.toLowerCase()) ? startLspServer(
        ext: widget.languageDetails.extension[0],
        executable: widget.languageDetails.lspExecutable,
        args: widget.languageDetails.args ?? [],
        workspacePath: widget.rootDir,
        langId: widget.languageDetails.name
      ) : Future.value(null)
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize editor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          );
        }
        
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
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
        
        final target = snapshot.data![0] as File?;
        final lspConfig = snapshot.data!.length > 2 ? snapshot.data![2] as LspConfig? : null;
        
        if (target == null || !target.existsSync()) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.red),
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
        
        final initialController = CodeForgeController(
          lspConfig: lspConfig
        );
        final isRepoThere = Directory(path.join(widget.rootDir, ".git")).existsSync();
        final initalUndoController = UndoRedoController();
        final initialFindController = FindController(initialController);
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => StackBloc()),
            BlocProvider(create: (_) => FindWordBloc()),
            BlocProvider(create: (_) => ApiBloc()),
            BlocProvider(create: (_) => FolderBloc()),
            BlocProvider(create: (_) => AIChatBloc()),
            BlocProvider(create: (_) => WorkspaceSearchBloc()),
            BlocProvider(create: (_) => RepoStatusBloc()..add(LoadRepoStatus(widget.rootDir))),
            BlocProvider(create: (_) => ActiveEditorsBloc(
              ActiveEditors(
                filePath: target,
                controller: initialController,
                languageDetails: widget.languageDetails,
                undoRedoController: initalUndoController,
                isActive: true,
                findController: initialFindController,
              )
            )),
          ],
          child: BlocListener<WorkspaceSearchBloc, WorkspaceSearchState>(
            listenWhen: (previous, current) => 
              previous.query != current.query ||
              previous.matchCase != current.matchCase ||
              previous.matchWholeWord != current.matchWholeWord ||
              previous.isRegex != current.isRegex,
            listener: (context, searchState) {
              // Apply workspace search highlighting to all open editors
              final editorState = context.read<ActiveEditorsBloc>().state;
              for (final editor in editorState.activeEditors) {
                if (searchState.query.isEmpty) {
                  _clearSearchHighlighting(editor);
                } else {
                  _applySearchHighlighting(editor, searchState.query, searchState);
                }
              }
            },
            child: BlocBuilder<ActiveEditorsBloc, ActiveEditorsState>(
              buildWhen: (previous, current) => previous.activeEditors.length != current.activeEditors.length,
              builder: (context, editorState) {
                _updateTabController(editorState.activeEditors.length);
                return Scaffold(
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
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 0)), 
                                  Icons.file_copy_outlined,
                                  color: state.stackIndex == 0 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 0 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                  ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 1)),
                                  Icons.search,
                                  color: state.stackIndex == 1 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 1 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 2)),
                                  FontAwesomeIcons.codeBranch,
                                  color: state.stackIndex == 2 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 2 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 3)),
                                  SvgPicture.asset(
                                    'assets/icons/rest-api-icon.svg',
                                    height: 34,
                                    width: 34,
                                    colorFilter: ColorFilter.mode(
                                      state.stackIndex == 3 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor, BlendMode.srcIn),
                                  ),
                                  bgColor: state.stackIndex == 3 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 4)),
                                  SvgPicture.asset(
                                    'assets/icons/ai.svg',
                                    height: 34,
                                    width: 34,
                                  ),
                                  bgColor: state.stackIndex == 4 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 5)
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 5)),
                                  Icons.settings,
                                  color: state.stackIndex == 5 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 5 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
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
                                    padding: const EdgeInsets.only(left: 20),
                                    child: ListView(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 15),
                                            child: Text(
                                              "EXPLORER",
                                              style: TextStyle(
                                                fontWeight: appTheme.isDark? FontWeight.w300 : FontWeight.w500,
                                                color: appTheme.selectScreenCardTextColor,
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
                                            textFieldWidth: MediaQuery.of(context).size.width,
                                            textStyle: const TextStyle(color: Colors.grey,),
                                            cursorColor: Colors.grey,
                                            cursorHeight: 19,
                                            verticalTextAlign: TextAlignVertical.top,
                                            textfieldDecoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 1.0),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(2)),
                                                borderSide: BorderSide(color: Colors.grey)
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(2)),
                                                borderSide: BorderSide(color: Colors.grey)
                                              ),
                                            ),
                                            folderIcon: const Icon(Icons.folder, color: Colors.grey,size: 20),
                                            fileIcon: const Icon(Icons.edit_document, color: Colors.grey,size: 20),
                                            doneIcon: const Icon(Icons.check, color: Colors.grey,size: 20),
                                            cancelIcon: const Icon(Icons.close, color: Colors.grey,size: 20),
                                          ),
                                          fileIconBuilder: (ext) {
                                            return SizedBox(
                                              height: 25,
                                              width: 25,
                                              child:languages.firstWhere(
                                                (lang)=>lang.extension.contains(ext.replaceFirst(".", "")),
                                                orElse: () => languages[0],
                                              ).icon??FileIcon(ext)
                                            );
                                          },
                                          folderStyle: FolderStyle(
                                            iconForCreateFolder: Icon(
                                              Icons.create_new_folder,
                                              color: appTheme.isDark? Colors.grey : const Color(0xff2b2b2b),
                                            ),
                                            iconForCreateFile: Icon(
                                              FontAwesomeIcons.fileCirclePlus,
                                              size: 20,
                                              color: appTheme.isDark? Colors.grey : const Color(0xff2b2b2b),
                                            ),
                                            rootFolderClosedIcon: const Icon(Icons.chevron_right_sharp,color: Colors.grey),
                                            rootFolderOpenedIcon: const Icon(Icons.keyboard_arrow_down_sharp,color: Colors.grey),
                                            folderClosedicon: SvgPicture.asset('assets/icons/folder.svg',height: 30,width: 30),
                                            folderOpenedicon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 30,width: 30),
                                            folderNameStyle: TextStyle(
                                              color: appTheme.selectScreenCardTextColor,
                                              fontSize: 20,
                                              fontWeight: appTheme.isDark ? FontWeight.w400 : FontWeight.w500,
                                            ),
                                          ),
                                          fileStyle: FileStyle(
                                            iconForDeleteFile: Icon(Icons.delete, size: 25, color: Colors.red[300]),
                                            fileNameStyle: TextStyle(
                                              color: appTheme.selectScreenCardTextColor,
                                              fontSize: 20,
                                              fontWeight: appTheme.isDark ? FontWeight.w400 : FontWeight.w500,
                                              height: 2,
                                            ),
                                          ),
                                          onFileTap: (f) async{
                                            final List<ActiveEditors> currentState = List.from(editorState.activeEditors);
                                            for(ActiveEditors item in currentState){
                                              item.isActive = false;
                                            }
                                            final lang = languages.firstWhere(
                                              (language) =>language.extension.contains(path.extension(f.path).replaceFirst(".", "")),
                                              orElse: () =>languages[0]
                                            );
                                            final lspConfig = uiBloc.state.codeForgeConfig['enableLSP'] && !(uiBloc.state.codeForgeConfig["LSPdisabledLangs"] as List<dynamic>).cast<String>().contains(lang.name.toLowerCase()) ? await startLspServer(
                                              ext: lang.extension[0],
                                              executable: lang.lspExecutable,
                                              args: lang.args ?? [],
                                              workspacePath: f.parent.path,
                                              langId: lang.name
                                            ) : null;
                                            final newController = CodeForgeController(
                                              lspConfig: lspConfig
                                            );
                                            currentState.add(
                                              ActiveEditors(
                                                controller: newController,
                                                undoRedoController: UndoRedoController(),
                                                filePath: f,
                                                isActive: true,
                                                languageDetails: lang,
                                                findController: FindController(newController),
                                              )
                                            );
                                            mruOrder.insert(0, currentState.length - 1);
                                            if(context.mounted) {
                                              context.read<ActiveEditorsBloc>().add(ActiveEditorsEvent(currentState));
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                final newIndex = currentState.indexWhere((item) => item.isActive == true);
                                                if (tabController != null && tabController!.length > newIndex && newIndex >= 0) {
                                                  tabController!.animateTo(newIndex);
                                                }
                                                // Apply workspace search highlighting to the new editor
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
                                  replaceWordController: replaceWordController,
                                  tabController: tabController,
                                  workspacePath: widget.rootDir,
                                  onFileOpen: (file, lineNumber, searchQuery) async {
                                    final List<ActiveEditors> currentState = List.from(editorState.activeEditors);
                                    
                                    // Check if file is already open
                                    final existingIndex = currentState.indexWhere(
                                      (editor) => editor.filePath.path == file.path,
                                    );
                                    
                                    if (existingIndex >= 0) {
                                      // File already open, switch to it
                                      for (int i = 0; i < currentState.length; i++) {
                                        currentState[i].isActive = i == existingIndex;
                                      }
                                      context.read<ActiveEditorsBloc>().add(ActiveEditorsEvent(currentState));
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (tabController != null && existingIndex < tabController!.length) {
                                          tabController!.animateTo(existingIndex);
                                        }
                                        // Trigger find with the search query
                                        final editor = currentState[existingIndex];
                                        if (editor.findController != null && searchQuery.isNotEmpty) {
                                          _goToMatchNearLine(editor, lineNumber, searchQuery);
                                        }
                                      });
                                    } else {
                                      // Open new file
                                      for (ActiveEditors item in currentState) {
                                        item.isActive = false;
                                      }
                                      final lang = languages.firstWhere(
                                        (language) => language.extension.contains(path.extension(file.path).replaceFirst(".", "")),
                                        orElse: () => languages[0]
                                      );
                                      final newLspConfig = uiBloc.state.codeForgeConfig['enableLSP'] && !(uiBloc.state.codeForgeConfig["LSPdisabledLangs"] as List<dynamic>).cast<String>().contains(lang.name.toLowerCase()) 
                                        ? await startLspServer(
                                            ext: lang.extension[0],
                                            executable: lang.lspExecutable,
                                            args: lang.args ?? [],
                                            workspacePath: file.parent.path,
                                            langId: lang.name
                                          ) 
                                        : null;
                                      final newController = CodeForgeController(
                                        lspConfig: newLspConfig
                                      );
                                      final newFindController = FindController(newController);
                                      currentState.add(
                                        ActiveEditors(
                                          controller: newController,
                                          undoRedoController: UndoRedoController(),
                                          filePath: file,
                                          isActive: true,
                                          languageDetails: lang,
                                          findController: newFindController,
                                        )
                                      );
                                      mruOrder.insert(0, currentState.length - 1);
                                      if (context.mounted) {
                                        context.read<ActiveEditorsBloc>().add(ActiveEditorsEvent(currentState));
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          final newIndex = currentState.indexWhere((item) => item.isActive == true);
                                          if (tabController != null && tabController!.length > newIndex && newIndex >= 0) {
                                            tabController!.animateTo(newIndex);
                                          }
                                          // Trigger find with the search query after file loads
                                          if (searchQuery.isNotEmpty) {
                                            // Small delay to ensure the editor is fully loaded
                                            Future.delayed(const Duration(milliseconds: 100), () {
                                              _goToMatchNearLine(currentState.last, lineNumber, searchQuery);
                                            });
                                          }
                                        });
                                      }
                                    }
                                  },
                                ),
                                SourceControl(appTheme: appTheme, workSpace: widget.rootDir, isRepoThere: isRepoThere),
                                APITesting(
                                  params: params,
                                  headers: headers,
                                  apiUrlController: apiUrlController,
                                  appTheme: appTheme,
                                  paramTabController: paramTabController,
                                  apiTabController: apiTabController
                                ),
                                AIChat(filePath: editorState.activeEditors.isNotEmpty
                                  ? editorState.activeEditors[(tabController != null ? tabController!.index : editorState.activeEditors.indexWhere((item) => item.isActive == true))].filePath.path
                                  : ''),
                                SettingsTab(appTheme: appTheme, uiBloc: uiBloc)
                              ],
                            )
                          )
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
                              ? path.basename(editorState.activeEditors[0].filePath.path)
                              : '',
                            style: TextStyle(color: appTheme.selectScreenCardTextColor)
                          )
                        : AnimatedBuilder(
                            animation: tabController!,
                            builder: (context, _) {
                              int idx = tabController!.index;
                              if (idx < 0 || idx >= editorState.activeEditors.length) idx = 0;
                              final fileName = editorState.activeEditors.isNotEmpty
                                ? path.basename(editorState.activeEditors[idx].filePath.path)
                                : '';
                              return Text(fileName, style: TextStyle(color: appTheme.selectScreenCardTextColor));
                            },
                          )
                    ),
                  bottom: TabBar(
                    labelPadding: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    indicator: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xff157dcc),
                          width: 2
                        ),
                        left: BorderSide(
                          color: appTheme.isDark? Colors.grey : Colors.blueGrey[600]!,
                          width: 0.2
                        ),
                        right: BorderSide(
                          color: appTheme.isDark? Colors.grey : Colors.blueGrey[600]!,
                          width: 0.2
                        ),
                      )
                    ),
                    labelColor: appTheme.selectScreenCardTextColor,
                    unselectedLabelColor: appTheme.isDark ? null : Colors.grey[400],
                    dividerColor: Colors.transparent,
                    controller: tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    onTap: (value) {
                      mruOrder.remove(value);
                      mruOrder.insert(0, value);
                      if (tabController != null && tabController!.index != value) {
                        tabController!.animateTo(value);
                      }
                    },
                    tabs: List.generate(editorState.activeEditors.length, (index){
                      return Tab(
                        height: 32,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                path.basename(editorState.activeEditors[index].filePath.path),
                                softWrap: false,
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final List<ActiveEditors> currentState = List.from(editorState.activeEditors);
                                if(currentState.length <= 1){
                                  Navigator.of(context).pop();
                                  return;
                                }
                                final wasActive = currentState[index].isActive;
                                currentState.removeAt(index);
                                mruOrder.remove(index);
                                mruOrder = mruOrder.map((i) => i > index ? i - 1 : i).toList();
                                if (currentState.isNotEmpty && wasActive) {
                                  int newActive = mruOrder.isNotEmpty ? mruOrder[0] : 0;
                                  for (int i = 0; i < currentState.length; i++) {
                                    currentState[i].isActive = i == newActive;
                                  }
                                }
                                context.read<ActiveEditorsBloc>().add(ActiveEditorsEvent(currentState));
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final newIndex = currentState.indexWhere((item) => item.isActive == true);
                                  if (tabController != null && newIndex >= 0 && newIndex < tabController!.length) {
                                    tabController!.animateTo(newIndex);
                                  }
                                });
                              }, 
                              icon: Icon(Icons.close, size: 20)
                            )
                          ]
                        ),
                      );
                    })
                  ),
                  actions: [
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: TextButton(onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                icon: const Icon(FontAwesomeIcons.fileCirclePlus),
                                iconColor: Colors.grey,
                                backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                title: const Text("Create a new file",
                                    style: TextStyle(color: Colors.grey)),
                                content: Form(
                                  key: createFileKey,
                                  child: TextFormField(
                                    style: const TextStyle(color: Colors.grey),
                                    cursorColor: Colors.grey,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter a valid filename";
                                      }
                                      return null;
                                    },
                                    controller: createFileController,
                                    decoration: const InputDecoration(
                                        hintStyle: TextStyle(color: Colors.grey),
                                        hintText: " filename.ext",
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:BorderRadius.all(Radius.circular(25)),
                                          borderSide:BorderSide(color: Color(0xff5090c8))),
                                        border: OutlineInputBorder(
                                          borderRadius:BorderRadius.all(Radius.circular(25)))),
                                      ),
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          createFileKey.currentState!.validate();
                                          if (createFileController.text.isNotEmpty) {
                                            final file = await createFile(
                                              createFileController.text, 
                                              widget.rootDir,
                                              context
                                            ); 
                                            if (context.mounted && file != null) {
                                              /* Navigator.of(context).push(MaterialPageRoute(
                                                builder: (context) => EditorPage(
                                                  rootDir: widget.rootDir ?? file.parent.path,
                                                  filePath: file,
                                                  languageDetails: languages
                                                  .firstWhere((language) => 
                                                    language.extension == path.extension(file.path).replaceFirst(".", ""))
                                                  )
                                                )
                                              ); */
                                            }
                                          }
                                        },
                                        child: const Text("OK")
                                      )
                                    ],
                                  ));
                                  }, child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: Icon(
                                          FontAwesomeIcons.fileCirclePlus,
                                          color: appTheme.selectScreenCardTextColor,
                                          size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Text("New",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                    ],
                                  ))),
                              PopupMenuItem(
                                child: TextButton(onPressed: () async{
                                  if (context.mounted) {
                                    final file = await pickFile();
                                    if (file != null) {
                                    } else {
                                      if(context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Failed to open file",
                                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
                                            backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                            icon: const Icon(Icons.error_outline),
                                            iconColor: Colors.red[600],
                                            actionsAlignment: MainAxisAlignment.center,
                                              actions: [
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text("OK"))
                                                  ],
                                              ));
                                            }
                                          }
                                        }
                                        if(context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                        }, child: Row(
                                          children: [
                                            Icon(FontAwesomeIcons.fileImport,color: appTheme.selectScreenCardTextColor,size: 20),
                                            const SizedBox(width: 10),
                                            Text("Open",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                          ],
                                        ),
                                      ),
                              ),
                                PopupMenuItem(
                                  child: TextButton(onPressed: () async{
                                    if(context.mounted && editorState.activeEditors.isNotEmpty){
                                      final activeEditorForSave = tabController != null && tabController!.index < editorState.activeEditors.length
                                          ? editorState.activeEditors[tabController!.index]
                                          : editorState.activeEditors.firstWhere((item) => item.isActive == true, orElse: () => editorState.activeEditors.first);
                                      final savedPlace = await selectDir(
                                        dialogeTitle: "Save file as...",
                                        initialDirectory: widget.rootDir,
                                        bytes: activeEditorForSave.filePath.readAsBytesSync()
                                      );
                                      if((savedPlace == null || savedPlace.isEmpty) && context.mounted){
                                        showDialog(context: context, builder: (context)=> AlertDialog(
                                          title: const Text("Failed to save file",
                                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
                                          backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                          icon: const Icon(Icons.error_outline),
                                          iconColor: Colors.red[600],
                                          actionsAlignment: MainAxisAlignment.center,
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              child: const Text("OK"))
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  }, child: Row(
                                    children: [
                                      const SizedBox(width: 5.5),
                                      Icon(FontAwesomeIcons.filePen, color: appTheme.selectScreenCardTextColor,size: 20),
                                      const SizedBox(width: 7),
                                      Text("SaveAs",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                    ],
                                  ),
                                )
                              ),
                              PopupMenuItem(
                                  child: TextButton(onPressed: () {
                                    showDialog(context: context, builder: (context)=>AlertDialog(
                                      title:  Text("Are you sure ?",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                                      content: const Text("       The code will be cleared",style: TextStyle(color: Colors.grey)),
                                      backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                      icon: const Icon(Icons.error_outline,size: 35),
                                      iconColor: Colors.red[600],
                                      actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStatePropertyAll(Colors.red[600])
                                            ),
                                            onPressed: (){
                                              Navigator.of(context).pop();
                                            }, child: const Text("Cancel",style: TextStyle(color: Colors.white))),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (editorState.activeEditors.isEmpty) return;
                                              final activeEditorForClear = tabController != null && tabController!.index < editorState.activeEditors.length
                                                  ? editorState.activeEditors[tabController!.index]
                                                  : editorState.activeEditors.firstWhere((item) => item.isActive == true, orElse: () => editorState.activeEditors.first);
                                              activeEditorForClear.filePath.writeAsString('');
                                              Navigator.of(context).pop();
                                              try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.rootDir)); } catch (_) {}
                                            },
                                            child: const Text("OK"))
                                        ],
                                    ));
                                  }, child: Row(
                                    children: [
                                      Icon(Icons.clear_sharp,color: appTheme.selectScreenCardTextColor,size: 25),
                                      const SizedBox(width: 7),
                                      Text("Clear",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                    ],
                                  ),
                                ),
                              )
                            ]),
                      IconButton(
                        onPressed: () async {
                          if (editorState.activeEditors.isEmpty) return;
                          final Directory tempDir = Directory('/data/data/com.vsdroid/temps');
                            if(!tempDir.existsSync()){
                              tempDir.createSync(recursive: true);
                            }
                            final activeEditorForRun = tabController != null && tabController!.index < editorState.activeEditors.length
                              ? editorState.activeEditors[tabController!.index]
                              : editorState.activeEditors.firstWhere((item) => item.isActive == true, orElse: () => editorState.activeEditors.first);
                            final File filePath = activeEditorForRun.filePath;
                          final String extention = path.extension(filePath.path);
                          switch (extention) {
                            case '.html':
                              if (context.mounted) {
                                Navigator.of(context).push(PageRouteBuilder(
                                  pageBuilder: (context, animation, scondaryAnimation) => WebViewScreen(htmlFile: filePath),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SizeTransition(sizeFactor: animation, child: child);
                                  },
                                ));
                              }
                              break;
                            case '.c':
                              final String compileCommand = "clang -fPIC -shared ${filePath.path} -o  ${tempDir.path}/libtemp.so";
                              final String runCommand = 'clangloader ${tempDir.path}/libtemp.so';
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.cpp':
                            case '.c++':
                            case '.cc':
                              final String compileCommand = "clang++ -fPIC -shared ${filePath.path} -o  ${tempDir.path}/libtemp.so";
                              final String runCommand = 'clangloader ${tempDir.path}/libtemp.so';
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.java':
                              final String compileCommand = "javac ${filePath.path} -d ${tempDir.path}";
                              final String runCommand = "cd ${tempDir.path} && java ${path.basenameWithoutExtension(filePath.path)}";
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.kt':
                            case '.kts':
                              final String compileCommand = 'kotlinc ${filePath.path} -d ${tempDir.path}';
                              final String runCommand = "cd ${tempDir.path} && java ${path.basenameWithoutExtension(filePath.path)}";
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.ts':
                              final String compileCommand = "tsc ${filePath.path} --outDir ${tempDir.path}";
                              final String runCommand = "node ${tempDir.path}/${path.basenameWithoutExtension(filePath.path)}.js";
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.md':
                              Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (context, animation, scondaryAnimation) =>MdView(
                                  data: filePath.readAsStringSync(),
                                  appTheme: appTheme,
                                  theme: context.read<ConfigBloc>().state,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SizeTransition(sizeFactor: animation, child: child);
                                },
                              ));
                              break;
                            default:
                              final lang = languages.firstWhere(
                                (language) => language.extension.contains(path.extension(filePath.path).replaceFirst(".", "")),
                                orElse: () => languages[0],
                              );
                              final String command = lang.command ?? '';
                              Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (context, animation, scondaryAnimation) =>
                                  SetupTerminal(
                                    projectDir: widget.rootDir,
                                    args: ["-c", "$command ${filePath.path}"]
                                  ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SizeTransition(sizeFactor: animation, child: child);
                                },
                              )
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow)),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (context, animation, scondaryAnimation) =>
                                SetupTerminal(
                                  projectDir: widget.rootDir,
                                ),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SizeTransition(sizeFactor: animation, child: child);
                              },
                            )
                          );
                          /* Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SetupTerminal(
                              projectDir: editorState.activeEditors.isNotEmpty
                                ? editorState.activeEditors[(tabController != null ? tabController!.index : editorState.activeEditors.indexWhere((item) => item.isActive == true))].filePath.parent.path
                                : widget.rootDir
                            ))); */
                        },
                        icon: const Icon(Icons.terminal))
                  ],
                ),
                body: TabBarView(
                  controller: tabController,
                  children: editorState.activeEditors.map((editor)=> EditorArea(
                    key: ValueKey(editor.filePath.path),
                    editor: editor,
                    appTheme: appTheme
                  )).toList()
                )
              );
            },
          ),
          ),
        );
      },
    );
  }
}