import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/languages.dart';
import '../bloc/ui_bloc.dart';
import '../utils/themes.dart';

Widget drawerButtons(
  VoidCallback onPressed,
  dynamic icon, {
  Color color = const Color(0xff6d6d6d),
  Color bgColor = Colors.transparent,
  EdgeInsets? padding,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: ![IconData, IconDataSolid].contains(icon.runtimeType)
                ? 2.5
                : icon.runtimeType == IconDataSolid
                ? 5
                : 4,
            vertical: ![IconData, IconDataSolid].contains(icon.runtimeType)
                ? 8
                : 5,
          ),
      child: IconButton(
        onPressed: onPressed,
        icon: ![IconData, IconDataSolid].contains(icon.runtimeType)
            ? icon
            : Icon(
                icon,
                color: color,
                size: icon.runtimeType == IconDataSolid ? 35 : 38,
              ),
      ),
    ),
  );
}

Widget fileTiles(
  VoidCallback onPressed,
  String text,
  dynamic icon,
  bool isDark, {
  double val = 0,
}) {
  return Padding(
    padding: const EdgeInsets.only(left: 15),
    child: ListTile(
      onTap: onPressed,
      title: Text(
        text,
        style: TextStyle(
          color: isDark
              ? const Color.fromARGB(255, 118, 180, 234)
              : const Color.fromARGB(255, 20, 107, 183),
          fontWeight: isDark ? FontWeight.w300 : FontWeight.w400,
        ),
      ),
      leading: Padding(
        child: icon,
        padding: EdgeInsets.only(left: val),
      ),
      iconColor: const Color.fromARGB(255, 29, 107, 176),
    ),
  );
}

Widget settingsDivider = Divider(
  thickness: 0.4,
  indent: 18,
  endIndent: 18,
  color: Colors.grey,
);

Widget settingsType(String type, bool isDark) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
  child: Text(
    type,
    style: TextStyle(color: Color(isDark ? 0xffacc3fc : 0xff181a26)),
  ),
);

dynamic settingsTile(
  VoidCallback? onPressed,
  String title,
  dynamic icon,
  bool isDark, {
  String? subTitle,
  Widget? trailing,
  bool isEnabled = true,
}) {
  return ListTile(
    enabled: isEnabled,
    minVerticalPadding: 13,
    dense: true,
    onTap: onPressed,
    leading: icon,
    trailing: trailing,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 17.5,
        fontWeight: isDark ? FontWeight.w400 : FontWeight.w500,
        color: isDark
            ? Colors.grey[400]
            : const Color.fromARGB(255, 93, 93, 93),
      ),
    ),
    subtitle: subTitle != null
        ? Text(
            subTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDark ? FontWeight.w400 : FontWeight.w500,
              color: isDark
                  ? Colors.grey[400]
                  : const Color.fromARGB(255, 93, 93, 93),
            ),
          )
        : null,
  );
}

Widget drawerTile(VoidCallback onPressed, String title, dynamic icon) {
  return ListTile(onTap: onPressed, title: Text(title), leading: icon);
}

Widget projectTile(
  String projectName,
  String projectDetails,
  icon,
  Color cardBg,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
    child: Card(
      color: cardBg,
      child: ListTile(
        onTap: onTap,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        leading: icon,
        title: Text(projectName),
        subtitle: Text(
          projectDetails,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    ),
  );
}

Widget bottomTool(bool isDark, IconData iconData, VoidCallback onPressed) {
  return SizedBox(
    height: 37,
    width: 75,
    child: IconButton(
      highlightColor: Colors.lightBlue.withAlpha(160),
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      padding: EdgeInsets.zero,
      onPressed: () {
        try {
          onPressed.call();
        } catch (e) {
          /**/
        }
      },
      icon: Icon(
        iconData,
        color: !isDark
            ? const Color.fromARGB(255, 40, 40, 40)
            : const Color.fromARGB(255, 194, 194, 194),
      ),
    ),
  );
}

//-----------------------Editor---------------------------------------

class CodeEditor extends StatefulWidget {
  final File filePath;
  final CodeForgeController codeController;
  final UndoRedoController undoRedoController;
  final Language language;
  const CodeEditor({
    super.key,
    required this.codeController,
    required this.undoRedoController,
    required this.filePath,
    required this.language,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> with AutomaticKeepAliveClientMixin{
  double _initialFontSize = 10.0;
  double _currentScale = 1.0;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    final controller = widget.codeController;
    controller.addListener(() {
        BlocListener<GeneralBloc, GeneralState>(
          listener: (context, generalState) {
            if (generalState.generalSettings['autoSave'] ?? true) {
              _saveTimer?.cancel();
              _saveTimer = Timer(
                const Duration(milliseconds: 85),
                () {
                  controller.saveFile();     
                },
              );
            }
        }
      );
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final codeController = widget.codeController;
    return BlocBuilder<GeneralBloc, GeneralState>(
      builder: (context, generalState) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (details) {
                if (details.pointerCount == 2) {
                  _initialFontSize = themeState.fontSize;
                }
              },
              onScaleUpdate: (details) {
                if (details.pointerCount == 2) {
                  _currentScale = details.scale;
                  double newFontSize = _initialFontSize * _currentScale;
                  newFontSize = newFontSize.clamp(8.0, 48.0);
                  context.read<ThemeBloc>().add(
                    SetFontSize(fontSize: newFontSize),
                  );
                }
              },
              child: BlocBuilder<AIBloc, AIState>(
                builder: (context, aiState) {
                  return CodeForge(
                    language: widget.language.language,
                    filePath: widget.filePath.path,
                    aiCompletion: aiState.completionModel != null
                        ? AiCompletion(
                            completionType: aiState.showSuggestionOntap
                                ? CompletionType.manual
                                : CompletionType.mixed,
                            enableCompletion: aiState.isEnabled,
                            model: aiState.completionModel!,
                          )
                        : null,
                    enableGuideLines:
                        themeState.codeForgeConfig['indentLineStatus'],
                    selectionStyle: CodeSelectionStyle(
                      selectionColor: Colors.blueAccent.withAlpha(80),
                      cursorBubbleColor: Colors.blue,
                    ),
                    editorTheme:
                        highlightThemes[themeState.codeForgeConfig['theme']],
                    textStyle: TextStyle(
                      fontFamily: themeState.codeForgeConfig['fontFamily'],
                      fontSize: themeState.fontSize,
                    ),
                    controller: codeController,
                    /* editorField: EditorField(
                      enableInteractiveSelection: true,
                      onChanged: (p0) {
                        if (generalState.generalSettings['autoSave'] ?? true) {
                          _saveTimer?.cancel();
                          _saveTimer = Timer(
                            const Duration(milliseconds: 85),
                            () {
                              widget.filePath.writeAsStringSync(p0);
                            },
                          );
                        }
                      },
                    ), */
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}

//-----------------------Editor Page----------------------------------

class EditorArea extends StatefulWidget {
  final ActiveEditors editor;
  final  AppTheme appTheme;
  const EditorArea({
    super.key,
    required this.editor,
    required this.appTheme
  });

  @override
  State<EditorArea> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorArea> with AutomaticKeepAliveClientMixin{
  late final ActiveEditors editor;
  late final AppTheme appTheme;
  late final CodeForgeController controller;
  late final UndoRedoController undoRedoController;
  late final Language language;
  late final File filePath;
  late final String ext;

  @override void initState() {
    editor = widget.editor;
    appTheme = widget.appTheme;
    controller = editor.controller;
    undoRedoController = editor.undoRedoController;
    language = editor.languageDetails;
    filePath = editor.filePath;
    ext = path.extension(filePath.path);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
        final pageContent = Column(
          children: [
            Expanded(
              child: BlocListener<FindWordBloc, FindWordState>(
                listener: (context, wordState) {
                  if(wordState.isRegex){
                    controller.findRegex(RegExp(wordState.word), null);
                  } else {
                    controller.findWord(
                      wordState.word,
                      matchCase: wordState.matchCase,
                      matchWholeWord: wordState.matchWholeWord
                    );
                  }
                },
                child: CodeEditor(
                  language: language,
                  undoRedoController: undoRedoController,
                  codeController: controller,
                  filePath: editor.filePath,
                ),
              )
            ),
            Container(
              height: 78,
              color: appTheme.isDark ? const Color.fromARGB(255, 32, 32, 32) : const Color.fromARGB(255, 219, 218, 218),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        height: 37,
                        width: 75,
                        child: IconButton(
                          highlightColor: Colors.lightBlue.withAlpha(160),
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ))
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: (){
                
                          },
                          icon: SvgPicture.asset(
                            "assets/icons/tab.svg",
                            height: 25,
                            width: 25,
                            colorFilter: ColorFilter.mode(
                              appTheme.isDark ? 
                                const Color.fromARGB(255, 194, 194, 194) : 
                                const Color.fromARGB(255, 40, 40, 40),
                              BlendMode.srcIn
                            ),
                        ),
                      ),
                      ),
                      bottomTool(
                        undoRedoController.canUndo && appTheme.isDark,
                        Icons.undo,
                        (){
                          if(undoRedoController.canUndo){
                            undoRedoController.undo();
                          }
                        }
                      ),
                      bottomTool(
                        undoRedoController.canRedo && appTheme.isDark,
                        Icons.redo,
                        (){
                          if(undoRedoController.canRedo){
                            undoRedoController.redo();
                          }
                        }
                      ),
                      bottomTool(
                        appTheme.isDark,
                        Icons.arrow_upward,
                        controller.pressUpArrowKey,
                      ),
                      SizedBox(
                        height: 37,
                        width: 75,
                        child: IconButton(
                          highlightColor: Colors.lightBlue.withAlpha(160),
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ))
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: (){
                            final codeModel = context.read<AIBloc>().state.modelSelected['code'];
                            if(codeModel != null && codeModel.isNotEmpty && context.read<AIBloc>().state.isEnabled){
                              controller.manualAiCompletion?.call();
                            }
                            else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("No completion model found. Configure one in the settings"),
                                  duration: const Duration(seconds: 2),
                                )
                              );
                            }
                          },
                          icon: SvgPicture.asset(
                            "assets/icons/ai.svg",
                            height: 25,
                            width: 25,
                          )
                        )),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      bottomTool(
                        appTheme.isDark,
                        Icons.zoom_in,
                        (){
                          double currentFontSize = context.read<ThemeBloc>().state.fontSize;
                          context.read<ThemeBloc>().add(SetFontSize(fontSize:  currentFontSize * 1.15));
                        }
                      ),
                      bottomTool(
                        appTheme.isDark,
                        Icons.zoom_out,
                        (){
                          double currentFontSize = context.read<ThemeBloc>().state.fontSize;
                          context.read<ThemeBloc>().add(SetFontSize(fontSize:  currentFontSize * 0.9));
                        }
                      ),
                      bottomTool(
                        appTheme.isDark,
                        Icons.arrow_back,
                        controller.pressLetfArrowKey
                      ),
                      bottomTool(
                        appTheme.isDark,
                        Icons.arrow_downward,
                        controller.pressDownArrowKey,
                      ),
                      bottomTool(
                        appTheme.isDark,
                        Icons.arrow_forward,
                        controller.pressRightArrowKey,
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        );
        return pageContent;
  }
  
  @override
  bool get wantKeepAlive => true;
}

//-----------------------DirectoryTreeViewer--------------------------

class DirectoryTreeViewerCustom extends StatefulWidget {
  final String rootPath;
  final bool isUnfoldedFirst;
  final bool enableCreateFolderOption;
  final bool enableCreateFileOption;
  final bool enableDeleteFolderOption;
  final bool enableDeleteFileOption;
  final FolderStyle? folderStyle;
  final FileStyle? fileStyle;
  final EditingFieldStyle? editingFieldStyle;
  final void Function(File)? onFileTap;
  final List<Widget>? folderActions;
  final List<Widget>? fileActions;
  final Widget Function(String fileExtension)? fileIconBuilder;

  const DirectoryTreeViewerCustom({
    super.key,
    required this.rootPath,
    this.onFileTap,
    this.folderActions,
    this.fileActions,
    this.folderStyle,
    this.fileStyle,
    this.isUnfoldedFirst = true,
    this.editingFieldStyle,
    this.enableCreateFileOption = false,
    this.enableCreateFolderOption = false,
    this.enableDeleteFileOption = false,
    this.enableDeleteFolderOption = false,
    this.fileIconBuilder,
  });

  @override
  State<DirectoryTreeViewerCustom> createState() => _DirectoryTreeViewerState();
}

class _DirectoryTreeViewerState extends State<DirectoryTreeViewerCustom> {
  String? currentDir;
  String? newEntryPath;
  bool isFolderCreation = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isUnfolded(String dirPath) =>
      context.read<FolderBloc>().state.folderStates[dirPath] ?? false;
  void toggleFolder(String dirPath) =>
      context.read<FolderBloc>().toggleFolder(dirPath);

  void startCreating(String parentPath, bool isFolder) {
    setState(() {
      newEntryPath = parentPath;
      isFolderCreation = isFolder;
      _controller.clear();
    });
  }

  void stopCreating() {
    setState(() {
      newEntryPath = null;
    });
  }

  void createEntry(Directory parent) {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      final newPath = path.join(parent.path, value);
      if (isFolderCreation) {
        Directory(newPath).createSync();
      } else {
        File(newPath).createSync();
      }
    }
    stopCreating();
  }

  Widget _buildDirectoryTree(Directory directory) {
    final entries = directory.listSync();
    entries.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

    return Column(
      children: [
        InkWell(
          onTap: () {
            toggleFolder(directory.path);
            currentDir = directory.path;
          },
          child: Row(
            children: [
              isUnfolded(directory.path)
                  ? widget.folderStyle?.folderOpenedicon ??
                        FolderStyle().folderOpenedicon
                  : widget.folderStyle?.folderClosedicon ??
                        FolderStyle().folderClosedicon,
              const SizedBox(width: 8),
              Text(
                path.basename(directory.path),
                style:
                    widget.folderStyle?.folderNameStyle ??
                    FolderStyle().folderNameStyle,
              ),
              SizedBox(
                width: widget.folderStyle?.itemGap ?? FolderStyle().itemGap,
              ),
              if (widget.enableCreateFileOption &&
                  isUnfolded(directory.path) &&
                  currentDir == directory.path)
                IconButton(
                  onPressed: () => startCreating(directory.path, false),
                  icon:
                      widget.folderStyle?.iconForCreateFile ??
                      FolderStyle().iconForCreateFile,
                ),
              if (widget.enableCreateFolderOption &&
                  isUnfolded(directory.path) &&
                  currentDir == directory.path)
                IconButton(
                  onPressed: () => startCreating(directory.path, true),
                  icon:
                      widget.folderStyle?.iconForCreateFolder ??
                      FolderStyle().iconForCreateFolder,
                ),
              if (widget.enableDeleteFolderOption &&
                  isUnfolded(directory.path) &&
                  currentDir == directory.path)
                IconButton(
                  onPressed: () {
                    Directory(directory.path).delete(recursive: true);
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete),
                ),
              ...widget.folderActions ?? [],
            ],
          ),
        ),
        if (isUnfolded(directory.path))
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 7.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...entries.map(
                  (entry) => entry is Directory
                      ? _buildDirectoryTree(entry)
                      : _buildFileItem(entry as File),
                ),
                if (newEntryPath == directory.path)
                  _buildNewEntryField(directory),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNewEntryField(Directory parent) {
    return Row(
      children: [
        isFolderCreation
            ? widget.editingFieldStyle?.folderIcon ??
                  EditingFieldStyle().folderIcon
            : widget.editingFieldStyle?.fileIcon ??
                  EditingFieldStyle().fileIcon,
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: widget.editingFieldStyle?.textFieldHeight,
            width: widget.editingFieldStyle?.textFieldWidth,
            child: TextField(
              style: widget.editingFieldStyle?.textStyle,
              textAlignVertical: widget.editingFieldStyle?.verticalTextAlign,
              cursorRadius: widget.editingFieldStyle?.cursorRadius,
              cursorWidth: widget.editingFieldStyle?.cursorWidth ?? 2.0,
              cursorHeight: widget.editingFieldStyle?.cursorHeight,
              cursorColor: widget.editingFieldStyle?.cursorColor,
              autofocus: true,
              decoration:
                  widget.editingFieldStyle?.textfieldDecoration ??
                  EditingFieldStyle().textfieldDecoration,
              controller: _controller,
              onSubmitted: (_) => createEntry(parent),
            ),
          ),
        ),
        IconButton(
          icon:
              widget.editingFieldStyle?.doneIcon ??
              EditingFieldStyle().doneIcon,
          onPressed: () => createEntry(parent),
        ),
        IconButton(
          icon:
              widget.editingFieldStyle?.cancelIcon ??
              EditingFieldStyle().cancelIcon,
          onPressed: stopCreating,
        ),
      ],
    );
  }

  Widget _buildFileItem(File file) {
    return InkWell(
      onTap: () => widget.onFileTap?.call(file),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            widget.fileIconBuilder?.call(
                  path.extension(file.path).toLowerCase(),
                ) ??
                widget.fileStyle?.fileIcon ??
                FileStyle().fileIcon,
            const SizedBox(width: 8),
            Text(
              path.basename(file.path),
              style:
                  widget.fileStyle?.fileNameStyle ?? FileStyle().fileNameStyle,
            ),
            if (widget.enableDeleteFileOption)
              IconButton(
                onPressed: () {
                  file.deleteSync();
                  setState(() {});
                },
                icon:
                    widget.fileStyle?.iconForDeleteFile ??
                    FileStyle().iconForDeleteFile,
              ),
            ...widget.fileActions ?? [],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootDirectory = Directory(widget.rootPath);
    if (!rootDirectory.existsSync()) {
      return const Center(child: Text('Directory does not exist'));
    }
    return BlocBuilder<FolderBloc, FolderState>(
      builder: (context, state) {
        return _buildDirectoryTree(rootDirectory);
      },
    );
  }
}

//-----------------------SEARCH--------------------------

class FindWordWidget extends StatefulWidget {
  final AppTheme appTheme;
  final TextEditingController findWordController, replaceWordController;
  final ActiveEditorsState editorState;
  final TabController? tabController;
  const FindWordWidget({
    super.key,
    required this.appTheme,
    required this.findWordController,
    required this.editorState,
    required this.replaceWordController,
    required this.tabController
  });

  @override
  State<FindWordWidget> createState() => _FindWordWidgetState();
}

class _FindWordWidgetState extends State<FindWordWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 5),
        child: SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 17),
                child: Text(
                  "SEARCH",
                  style: TextStyle(
                    fontWeight: widget.appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                    color: widget.appTheme.selectScreenCardTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              BlocBuilder<FindWordBloc, FindWordState>(
                builder: (context, wordState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(wordState.matchCase ? Color(0xff0178b9).withAlpha(100) : Colors.transparent),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: wordState.matchCase ? widget.appTheme.selectScreenCardTextColor : Colors.transparent
                            ),
                            borderRadius: BorderRadiusGeometry.circular(5),
                          ))
                        ),
                        tooltip: "Match case",
                        onPressed: () {
                          context.read<FindWordBloc>().add(FindWord(
                            word: wordState.word,
                            matchCase: !wordState.matchCase,
                            matchWholeWord: wordState.matchWholeWord,
                            isRegex: wordState.isRegex,
                          ));
                        },
                        icon: Text('Aa', style: TextStyle(color: widget.appTheme.selectScreenCardTextColor))
                      ),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(wordState.matchWholeWord ? Color(0xff0178b9).withAlpha(100) : Colors.transparent),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: wordState.matchWholeWord ? widget.appTheme.selectScreenCardTextColor : Colors.transparent
                            ),
                            borderRadius: BorderRadiusGeometry.circular(5),
                          ))
                        ),
                        tooltip: "Match word",
                        onPressed: () {
                          context.read<FindWordBloc>().add(FindWord(
                            word: wordState.word,
                            matchCase: wordState.matchCase,
                            matchWholeWord: !wordState.matchWholeWord,
                            isRegex: wordState.isRegex,
                          ));
                        },
                        icon: Text(
                          'ab',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: widget.appTheme.selectScreenCardTextColor,
                            color: widget.appTheme.selectScreenCardTextColor
                          )
                        )
                      ),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(wordState.isRegex ? Color(0xff0178b9).withAlpha(100) : Colors.transparent),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: wordState.isRegex ? widget.appTheme.selectScreenCardTextColor : Colors.transparent
                            ),
                            borderRadius: BorderRadiusGeometry.circular(5),
                          ))
                        ),
                        tooltip: "Use Regular Expression",
                        onPressed: () {
                          context.read<FindWordBloc>().add(FindWord(
                            word: wordState.word,
                            matchCase: wordState.matchCase,
                            matchWholeWord: wordState.matchWholeWord,
                            isRegex: !wordState.isRegex
                          ));
                        },
                        icon: Text(
                          '.\u2731',
                          style: TextStyle(
                            fontSize: 16,
                            decorationColor: widget.appTheme.selectScreenCardTextColor,
                            color: widget.appTheme.selectScreenCardTextColor
                          )
                        )
                      )
                    ],
                  );
                },
              ),
              ListTile(
                title: SizedBox(
                  height: 47,
                  child: BlocListener<FindWordBloc, FindWordState>(
                    listener: (context, wordState) {
                      if (widget.findWordController.text != wordState.word) {
                        widget.findWordController.text = wordState.word;
                        widget.findWordController.selection = TextSelection.collapsed(offset: wordState.word.length);
                      }
                    },
                    child: TextField(
                      controller: widget.findWordController,
                      onChanged: (word) {
                        final String currWord = context.read<FindWordBloc>().state.word;
                        context.read<FindWordBloc>().add(
                          FindWord(
                            word: currWord.isEmpty ? word.trim() : word,
                            matchCase: context.read<FindWordBloc>().state.matchCase,
                            matchWholeWord: context.read<FindWordBloc>().state.matchWholeWord,
                            isRegex: context.read<FindWordBloc>().state.isRegex
                          )
                        );
                      },
                      cursorColor: Colors.grey,
                      style: TextStyle(color: widget.appTheme.selectScreenCardTextColor),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: widget.appTheme.selectScreenCardTextColor),
                        hintText: "Find word",
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0178b9)))
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              ListTile(
                trailing: InkWell(
                  onTap: () async {
                    if (widget.findWordController.text.isNotEmpty) {
                      final currentState = context.read<FindWordBloc>().state;
                      final activeEditor = widget.tabController != null
                          ? widget.editorState.activeEditors[widget.tabController!.index]
                          : widget.editorState.activeEditors.firstWhere((item) => item.isActive == true);
                      final data = await activeEditor.filePath.readAsString();
                      final newData = data.replaceAll(
                        currentState.word, widget.replaceWordController.text
                      );
                      await activeEditor.filePath.writeAsString(newData);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        //TODO: Implement efficient replace
                        // editorState.activeEditors.where((item)=> item.isActive == true).first.controller.text = newData;
                      });
                      if (context.mounted) {
                        //TODO: Remember user preference.
                        context.read<FindWordBloc>().add(
                          FindWord(
                            word: "",
                            matchCase: currentState.matchCase,
                            matchWholeWord: currentState.matchWholeWord,
                            isRegex: currentState.isRegex
                          )
                        );
                      }
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff0e639c),
                      borderRadius: BorderRadius.all(Radius.circular(25))
                    ),
                    height: 45,
                    width: 45,
                    child: const Icon(Icons.find_replace_sharp, color: Colors.white)),
                ),
                title: SizedBox(
                  height: 47,
                  child: TextField(
                    controller: widget.replaceWordController,
                    cursorColor: Colors.grey,
                    style: TextStyle(color: widget.appTheme.selectScreenCardTextColor),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: widget.appTheme.selectScreenCardTextColor),
                      hintText: "Replace",
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0178b9)))
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

//-----------------------AIChat--------------------------

class AIChat extends StatefulWidget {
  final String filePath;
  const AIChat({required this.filePath, super.key});

  @override
  State<AIChat> createState() => _AIChatState();
}

class _AIChatState extends State<AIChat> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _sendPrompt(Models chatModel, List<AIConversation> currentList) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final aiChatBloc = context.read<AIChatBloc>();

    final newList = currentList
        .map((c) => AIConversation(c.userRequest, c.modelResponse))
        .toList();
    newList.add(AIConversation(prompt, null));
    aiChatBloc.add(AIChatEvent(newList));

    final int index = newList.length - 1;
    _promptController.clear();

    final url = Uri.parse(chatModel.url);
    final client = http.Client();
    final request = http.Request('POST', url);
    request.headers.addAll(chatModel.headers);
    request.body = jsonEncode(
      (() {
        switch (chatModel) {
          case Gemini():
            return {
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
              "generationConfig": {
                "stopSequences": ["Title"],
                "temperature": 1.0,
                "maxOutputTokens": 800,
                "topP": 0.8,
                "topK": 10,
              },
            };
          case OpenAI():
            return {"model": chatModel.model, "input": prompt};
          case Claude():
            return {
              "model": chatModel.model,
              "max_tokens": 1024,
              "messages": [
                {"role": "user", "content": prompt},
              ],
            };
          case Grok():
          case DeepSeek():
          case Gorq():
          case TogetherAi():
          case Sonar():
          case OpenRouter():
          case FireWorks():
            return {
              "model": chatModel.model,
              "messages": [
                {"role": "user", "content": prompt},
              ],
            };
          case CustomModel():
            ;
        }
      })(),
    );

    try {
      //TODO: Convert to Stream
      //TODO: Preserver model memory/history
      StringBuffer responseBuffer = StringBuffer();
      final streamedResponse = await client.send(request);
      streamedResponse.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              responseBuffer.write(chunk);
              /* String parsed;
        try {
          print(chunk);
          parsed = chatModel.responseParser(jsonDecode(chunk));
          print("\n****************\n");
          print(parsed);
        } catch (e) {
          print(chunk);
          print(e);
          parsed = chatModel.responseParser(jsonDecode(chunk));
        }

        final updated = aiChatBloc.state.aiConversation
            .map((c) => AIConversation(c.userRequest, c.modelResponse))
            .toList();

        if (index < updated.length) {
          updated[index] = updated[index].copyWith(modelResponse: parsed);
          aiChatBloc.add(AIChatEvent(updated));
        }
      }, onError: (err) {
        final updated = aiChatBloc.state.aiConversation
            .map((c) => AIConversation(c.userRequest, c.modelResponse))
            .toList();
        if (index < updated.length) {
          updated[index] =
              updated[index].copyWith(modelResponse: 'Error: ${err.toString()}');
          aiChatBloc.add(AIChatEvent(updated));
        } */
            },
            onDone: () {
              try {
                final json = jsonDecode(responseBuffer.toString());
                final parsed = chatModel.responseParser(json);
                final updated = aiChatBloc.state.aiConversation
                    .map((c) => AIConversation(c.userRequest, c.modelResponse))
                    .toList();

                if (index < updated.length) {
                  updated[index] = updated[index].copyWith(
                    modelResponse: parsed,
                  );
                  aiChatBloc.add(AIChatEvent(updated));
                }
              } catch (e) {
                //
              }
              client.close();
            },
          );
    } catch (e) {
      final updated = aiChatBloc.state.aiConversation
          .map((c) => AIConversation(c.userRequest, c.modelResponse))
          .toList();
      if (index < updated.length) {
        updated[index] = updated[index].copyWith(
          modelResponse: 'Failed to send request: ${e.toString()}',
        );
        aiChatBloc.add(AIChatEvent(updated));
      }
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeBloc, AppThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<AIBloc, AIState>(
          builder: (context, aiState) {
            final Models? chatModel = aiState.chatModel;
            if (aiState.config.isEmpty ||
                aiState.modelSelected.isEmpty ||
                aiState.modelSelected['chat'] == null ||
                aiState.config[aiState.modelSelected['chat']] == null) {
              return Center(
                child: Text(
                  "Chat Model is not configured. Go to the settings and create one.",
                  style: TextStyle(
                    color: themeState.appTheme.selectScreenCardTextColor,
                    fontSize: 22,
                  ),
                ),
              );
            }
            return BlocBuilder<AIChatBloc, AIChatState>(
              builder: (context, aiChatState) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                            top: 10,
                            left: 10,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "AI CHAT",
                              style: TextStyle(
                                fontWeight: themeState.appTheme.isDark
                                    ? FontWeight.w300
                                    : FontWeight.w500,
                                color: themeState
                                    .appTheme
                                    .selectScreenCardTextColor,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.attach_file,
                                color: themeState
                                    .appTheme
                                    .selectScreenCardTextColor
                                    .withAlpha(200),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.history,
                                color: themeState
                                    .appTheme
                                    .selectScreenCardTextColor
                                    .withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _promptController,
                          cursorColor:
                              themeState.appTheme.selectScreenCardTextColor,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color:
                                themeState.appTheme.selectScreenCardTextColor,
                          ),
                          maxLines: null,
                          decoration: InputDecoration(
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xff0178b9)),
                            ),
                            suffix: IconButton(
                              onPressed: () async {
                                final List<AIConversation> currentAIChatState =
                                    List.from(aiChatState.aiConversation);
                                _sendPrompt(chatModel!, currentAIChatState);
                                _promptController.clear();
                              },
                              icon: Icon(
                                Icons.send,
                                color: themeState
                                    .appTheme
                                    .selectScreenCardTextColor,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            labelText: 'Ask AI',
                            labelStyle: TextStyle(
                              color: themeState
                                  .appTheme
                                  .selectScreenCardTextColor
                                  .withAlpha(150),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 2.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: languages.singleWhere((item) => item.extension.contains(path.extension(widget.filePath).substring(1))).icon,
                              ),
                              SizedBox(width: 3),
                              Text(
                                path.basename(widget.filePath),
                                style: TextStyle(
                                  color: themeState
                                      .appTheme
                                      .selectScreenCardTextColor
                                      .withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: aiChatState.aiConversation.length,
                            itemBuilder: (context, index) {
                              final isDark = themeState.appTheme.isDark;
                              final config = isDark
                                  ? MarkdownConfig(
                                      configs: [
                                        PConfig(
                                          textStyle: TextStyle(
                                            color: themeState
                                                .appTheme
                                                .selectScreenCardTextColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : MarkdownConfig.defaultConfig;
                              final conv = aiChatState.aiConversation[index];
                              final hasResponse =
                                  conv.modelResponse != null &&
                                  conv.modelResponse!.isNotEmpty;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6.5,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 5,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withAlpha(
                                              200,
                                            ),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.zero,
                                              bottomLeft: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            aiChatState
                                                .aiConversation[index]
                                                .userRequest,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: hasResponse
                                          ? MarkdownBlock(
                                              data: aiChatState
                                                  .aiConversation[index]
                                                  .modelResponse!,
                                              config: config,
                                            )
                                          : const LinearProgressIndicator(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
