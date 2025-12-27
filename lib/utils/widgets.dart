import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:code_forge/code_forge.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_json/flutter_json.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
     final generalState = context.read<GeneralBloc>().state;
    controller.addListener(() {
      if (generalState.generalSettings['autoSave'] ?? true) {
        _saveTimer?.cancel();
        _saveTimer = Timer(
          const Duration(milliseconds: 85),
          () {
            controller.saveFile();     
          },
        );
      }
        
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
  final bool enableRenameFolderOption;
  final bool enableRenameFileOption;
  final FolderStyle? folderStyle;
  final FileStyle? fileStyle;
  final EditingFieldStyle? editingFieldStyle;
  final void Function(File)? onFileTap;
  final List<Widget>? folderActions;
  final List<Widget>? fileActions;
  final Widget Function(String fileExtension)? fileIconBuilder;
  final AppTheme appTheme;

  const DirectoryTreeViewerCustom({
    super.key,
    required this.rootPath,
    required this.appTheme,
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
    this.enableRenameFolderOption = false,
    this.enableRenameFileOption = false,
    this.fileIconBuilder,
  });

  @override
  State<DirectoryTreeViewerCustom> createState() => _DirectoryTreeViewerState();
}

class _DirectoryTreeViewerState extends State<DirectoryTreeViewerCustom> {
  String? newEntryPath;
  String? renamingPath;
  bool isFolderCreation = false;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _renameController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _renameController.dispose();
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
      renamingPath = null;
    });
  }

  void stopCreating() {
    setState(() {
      newEntryPath = null;
    });
  }

  void startRenaming(String entityPath) {
    setState(() {
      renamingPath = entityPath;
      _renameController.text = path.basename(entityPath);
      newEntryPath = null;
    });
  }

  void stopRenaming() {
    setState(() {
      renamingPath = null;
      _renameController.clear();
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

  void renameEntry(String oldPath, bool isFolder) {
    final value = _renameController.text.trim();
    if (value.isNotEmpty && value != path.basename(oldPath)) {
      final parentDir = path.dirname(oldPath);
      final newPath = path.join(parentDir, value);
      try {
        if (isFolder) {
          Directory(oldPath).renameSync(newPath);
        } else {
          File(oldPath).renameSync(newPath);
        }
      } catch (e) {
        // Handle rename error if needed
        print('Error renaming: $e');
      }
    }
    stopRenaming();
  }

  void _showFolderContextMenu(BuildContext context, Directory directory, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        if (widget.enableCreateFileOption)
          PopupMenuItem(
            child: Row(
              children: [
                widget.folderStyle?.iconForCreateFile ?? FolderStyle().iconForCreateFile,
                const SizedBox(width: 15),
                Text(
                  'New File',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => startCreating(directory.path, false),
            ),
          ),
        if (widget.enableCreateFolderOption)
          PopupMenuItem(
            child: Row(
              children: [
                widget.folderStyle?.iconForCreateFolder ?? FolderStyle().iconForCreateFolder,
                const SizedBox(width: 11),
                Text(
                  'New Folder',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => startCreating(directory.path, true),
            ),
          ),
        if (widget.enableRenameFolderOption)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.edit, size: 25, color: widget.appTheme.selectScreenCardTextColor),
                const SizedBox(width: 8),
                Text(
                  'Rename Folder',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => startRenaming(directory.path),
            ),
          ),
        if (widget.enableDeleteFolderOption)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.delete, size: 25, color: Colors.red[300]),
                const SizedBox(width: 8),
                Text(
                  'Delete Folder',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () {
                Directory(directory.path).delete(recursive: true);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  void _showFileContextMenu(BuildContext context, File file, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        if (widget.enableRenameFileOption)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.edit, size: 25, color: widget.appTheme.selectScreenCardTextColor),
                const SizedBox(width: 8),
                Text(
                  'Rename File',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => startRenaming(file.path),
            ),
          ),
        if (widget.enableDeleteFileOption)
          PopupMenuItem(
            child: Row(
              children: [
                widget.fileStyle?.iconForDeleteFile ?? FileStyle().iconForDeleteFile,
                const SizedBox(width: 8),
                Text(
                  'Delete File',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () {
                file.deleteSync();
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDirectoryTree(Directory directory) {
    final entries = directory.listSync();
    entries.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

    // Check if this folder is being renamed
    if (renamingPath == directory.path) {
      return _buildRenameField(directory.path, true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => toggleFolder(directory.path),
          onLongPressStart: (details) => _showFolderContextMenu(
            context,
            directory,
            details.globalPosition,
          ),
          child: Row(
            children: [
              isUnfolded(directory.path)
                  ? widget.folderStyle?.folderOpenedicon ?? FolderStyle().folderOpenedicon
                  : widget.folderStyle?.folderClosedicon ?? FolderStyle().folderClosedicon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path.basename(directory.path),
                  style: widget.folderStyle?.folderNameStyle ?? FolderStyle().folderNameStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (widget.folderActions != null) ...widget.folderActions!,
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
            ? widget.editingFieldStyle?.folderIcon ?? EditingFieldStyle().folderIcon
            : widget.editingFieldStyle?.fileIcon ?? EditingFieldStyle().fileIcon,
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: widget.editingFieldStyle?.textFieldHeight,
            child: TextField(
              style: widget.editingFieldStyle?.textStyle,
              textAlignVertical: widget.editingFieldStyle?.verticalTextAlign,
              cursorRadius: widget.editingFieldStyle?.cursorRadius,
              cursorWidth: widget.editingFieldStyle?.cursorWidth ?? 2.0,
              cursorHeight: widget.editingFieldStyle?.cursorHeight,
              cursorColor: widget.editingFieldStyle?.cursorColor,
              autofocus: true,
              decoration: widget.editingFieldStyle?.textfieldDecoration ?? EditingFieldStyle().textfieldDecoration,
              controller: _controller,
              onSubmitted: (_) => createEntry(parent),
            ),
          ),
        ),
        IconButton(
          icon: widget.editingFieldStyle?.doneIcon ?? EditingFieldStyle().doneIcon,
          onPressed: () => createEntry(parent),
        ),
        IconButton(
          icon: widget.editingFieldStyle?.cancelIcon ?? EditingFieldStyle().cancelIcon,
          onPressed: stopCreating,
        ),
      ],
    );
  }

  Widget _buildRenameField(String entityPath, bool isFolder) {
    return Row(
      children: [
        isFolder
            ? widget.editingFieldStyle?.folderIcon ?? EditingFieldStyle().folderIcon
            : widget.editingFieldStyle?.fileIcon ?? EditingFieldStyle().fileIcon,
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: widget.editingFieldStyle?.textFieldHeight,
            child: TextField(
              style: widget.editingFieldStyle?.textStyle,
              textAlignVertical: widget.editingFieldStyle?.verticalTextAlign,
              cursorRadius: widget.editingFieldStyle?.cursorRadius,
              cursorWidth: widget.editingFieldStyle?.cursorWidth ?? 2.0,
              cursorHeight: widget.editingFieldStyle?.cursorHeight,
              cursorColor: widget.editingFieldStyle?.cursorColor,
              autofocus: true,
              decoration: (widget.editingFieldStyle?.textfieldDecoration ?? EditingFieldStyle().textfieldDecoration).copyWith(
                hintText: path.basename(entityPath),
              ),
              controller: _renameController,
              onSubmitted: (_) => renameEntry(entityPath, isFolder),
            ),
          ),
        ),
        IconButton(
          icon: widget.editingFieldStyle?.doneIcon ?? EditingFieldStyle().doneIcon,
          onPressed: () => renameEntry(entityPath, isFolder),
        ),
        IconButton(
          icon: widget.editingFieldStyle?.cancelIcon ?? EditingFieldStyle().cancelIcon,
          onPressed: stopRenaming,
        ),
      ],
    );
  }

  Widget _buildFileItem(File file) {
    // Check if this file is being renamed
    if (renamingPath == file.path) {
      return _buildRenameField(file.path, false);
    }

    return GestureDetector(
      onTap: () => widget.onFileTap?.call(file),
      onLongPressStart: (details) => _showFileContextMenu(
        context,
        file,
        details.globalPosition,
      ),
      child: Row(
        children: [
          widget.fileIconBuilder?.call(
                path.extension(file.path).toLowerCase(),
              ) ??
              widget.fileStyle?.fileIcon ??
              FileStyle().fileIcon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path.basename(file.path),
              style: widget.fileStyle?.fileNameStyle ?? FileStyle().fileNameStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (widget.fileActions != null) ...widget.fileActions!,
        ],
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
        return SingleChildScrollView(
          child: _buildDirectoryTree(rootDirectory),
        );
      },
    );
  }
}

//-----------------------SEARCH--------------------------

class FindWordWidget extends StatelessWidget {
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
                    fontWeight: appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                    color: appTheme.selectScreenCardTextColor,
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
                              color: wordState.matchCase ? appTheme.selectScreenCardTextColor : Colors.transparent
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
                        icon: Text('Aa', style: TextStyle(color: appTheme.selectScreenCardTextColor))
                      ),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(wordState.matchWholeWord ? Color(0xff0178b9).withAlpha(100) : Colors.transparent),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: wordState.matchWholeWord ? appTheme.selectScreenCardTextColor : Colors.transparent
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
                            decorationColor: appTheme.selectScreenCardTextColor,
                            color: appTheme.selectScreenCardTextColor
                          )
                        )
                      ),
                      IconButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(wordState.isRegex ? Color(0xff0178b9).withAlpha(100) : Colors.transparent),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.5,
                              color: wordState.isRegex ? appTheme.selectScreenCardTextColor : Colors.transparent
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
                          '\u2022\u2731',
                          style: TextStyle(
                            fontSize: 16,
                            decorationColor: appTheme.selectScreenCardTextColor,
                            color: appTheme.selectScreenCardTextColor
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
                      if (findWordController.text != wordState.word) {
                        findWordController.text = wordState.word;
                        findWordController.selection = TextSelection.collapsed(offset: wordState.word.length);
                      }
                    },
                    child: TextField(
                      controller: findWordController,
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
                      style: TextStyle(color: appTheme.selectScreenCardTextColor),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: appTheme.selectScreenCardTextColor),
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
                    if (findWordController.text.isNotEmpty) {
                      final currentState = context.read<FindWordBloc>().state;
                      final activeEditor = tabController != null
                          ? editorState.activeEditors[tabController!.index]
                          : editorState.activeEditors.firstWhere((item) => item.isActive == true);
                      final data = await activeEditor.filePath.readAsString();
                      final newData = data.replaceAll(
                        currentState.word, replaceWordController.text
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
                    controller: replaceWordController,
                    cursorColor: Colors.grey,
                    style: TextStyle(color: appTheme.selectScreenCardTextColor),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: appTheme.selectScreenCardTextColor),
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

//-----------------------Source Control------------------

class SourceControl extends StatelessWidget {
  final AppTheme appTheme;
  final String workSpace;
  final bool isRepoThere;
  const SourceControl({
    super.key,
    required this.appTheme,
    required this.workSpace,
    required this.isRepoThere
  });

  @override
  Widget build(BuildContext context) {
    bool isTemp = workSpace == "/storage/emulated/0/VSdroid/Temps";
    final List<Widget> noRepoFound = [
            Text(
              "The folder currently open\ndosen't hava a Git repository.\nYou can initialize a repository\nwhich will enable source control\nfeatures powered by Git.",
              textAlign: TextAlign.start,
              style: TextStyle(color: appTheme.isDark ?Colors.grey[400] : appTheme.selectScreenCardTextColor),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (){
                initRepo(workSpace);
              },
              style:  ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))
                  )),
                backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                foregroundColor: WidgetStatePropertyAll(Colors.white),
                textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
              ),
              child: const Text("Initialize Repository")),
            const SizedBox(height: 13.5),
            Text(
              "You can directly publish this\nfolder to a GitHub repository.\nOnce published, you'll have\naccess to source control featured\npowered by Git and GitHub",
              textAlign: TextAlign.start,
              style: TextStyle(color: appTheme.isDark ?Colors.grey[400] : appTheme.selectScreenCardTextColor),
            ),
            const SizedBox(height: 13.5),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: (){},
                style: const ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    )),
                  backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
                ),
                child:  const Row(
                  children: [
                    Icon(FontAwesomeIcons.github,color: Colors.white),
                    SizedBox(width: 8),
                    Text("Publish to Github"),
                  ],
                )),
            )];
    return !isTemp ? Padding(
      padding: const EdgeInsets.only(top: 25,left: 10),
      child: SizedBox(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topLeft,
              child: Text("SOURCE CONTROL",
                style: TextStyle(
                  fontWeight: appTheme.isDark? FontWeight.w300 : FontWeight.w500,
                  color: appTheme.selectScreenCardTextColor,
                ),
              )
            ),
            const SizedBox(height: 13.5),
            if(!isRepoThere) ...noRepoFound,
            if(isRepoThere) ...[
              SizedBox(
                height: 50,
                width: 250,
                child: TextField(
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.grey),
                  cursorColor: Colors.grey,
                  onChanged: (val){
                    context.read<ApiBloc>().add(GetUrl(url: val));
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: (){},
                      icon: SvgPicture.asset(
                        'assets/icons/ai.svg',
                        height: 20,
                        width: 20,
                      ),
                    ), 
                    hintText: "Commit message",
                    hintStyle: TextStyle(
                      color: appTheme.selectScreenCardTextColor.withAlpha(120)
                    ),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e639c))
                    )
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 250,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: const ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.only(
                                topRight: Radius.zero,
                                bottomRight: Radius.zero,
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              )
                            )),
                          backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                          textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))),
                        onPressed: (){},
                        child: Text("\u2713 Commit")
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          border: BorderDirectional(start: BorderSide(color: Colors.white, width: 0.5)),
                          color: Color(0xff0e639c),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6)
                          ),
                        ),
                        child: DropdownMenu(
                          trailingIcon: Icon(
                            FontAwesomeIcons.caretDown,
                            color: appTheme.selectScreenCardTextColor,
                            size: 14,
                          ),
                          selectedTrailingIcon: Icon(
                            FontAwesomeIcons.caretUp,
                            color: appTheme.selectScreenCardTextColor,
                            size: 14,
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            constraints: BoxConstraints.tight(const 
                            Size.fromHeight(40)),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6)
                              ),
                            ),
                          ),
                          menuStyle: MenuStyle(
                            backgroundColor: WidgetStatePropertyAll(appTheme.cardTheme.color),
                          ),
                          dropdownMenuEntries: [
                            DropdownMenuEntry(
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll(appTheme.selectScreenCardTextColor)
                              ),
                              value: "Commit and Push", label: "Commit and Push"
                            ),
                            DropdownMenuEntry(
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll(appTheme.selectScreenCardTextColor)
                              ),
                              value: "Commit and Sync", label: "Commit and Sync",
                            )
                        ]),
                      ),
                    )
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    ) : Center(
          child: Text(
            "Cannot initalize a git repository in the temp directory.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appTheme.selectScreenCardTextColor
            ),
          )
        );
  }
}

//-----------------------API Testing---------------------

class APITesting extends StatelessWidget {
  final Map<String, String> params, headers;
  final TextEditingController apiUrlController;
  final AppTheme appTheme;
  final TabController paramTabController, apiTabController;
  const APITesting({
    super.key,
    required this.params,
    required this.headers,
    required this.apiUrlController,
    required this.appTheme,
    required this.paramTabController,
    required this.apiTabController
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28,horizontal: 15),
      child: BlocBuilder<ApiBloc, ApiState>(
        builder: (context, webState) {
          Map<TextEditingController,TextEditingController> paramControllers = {
            for (int _ in Iterable.generate(webState.params.length + 1)) 
              TextEditingController() : TextEditingController()
          };
          Map<TextEditingController,TextEditingController> headerControllers = {
            for (int _ in Iterable.generate(webState.headers.length + 1)) 
              TextEditingController() : TextEditingController()
          };
          if(webState.params.isNotEmpty){
            for(int index = 0; index < webState.params.length; index++){
              paramControllers.keys.toList()[index].text = webState.params.keys.toList()[index];
              paramControllers.values.toList()[index].text = webState.params.values.toList()[index];
              params[webState.params.keys.toList()[index]] = webState.params.values.toList()[index];
            }
          }
          if(webState.headers.isNotEmpty){
            for(int index = 0; index < webState.headers.length; index++){
              headerControllers.keys.toList()[index].text = webState.headers.keys.toList()[index];
              headerControllers.values.toList()[index].text = webState.headers.values.toList()[index];
              headers[webState.headers.keys.toList()[index]] = webState.headers.values.toList()[index];
            }
          }
          apiUrlController.text = webState.url ?? "Enter URL";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Text(
                "API TESTING",
                style: TextStyle(
                  color: appTheme.selectScreenCardTextColor,
                  fontWeight: appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                )
              ),
              const SizedBox(height: 15),
              DropdownButtonHideUnderline(
                child: DropdownButton(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  value: webState.method,
                  dropdownColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 241, 241, 241),
                  items: [  
                    DropdownMenuItem(
                      value: "POST",
                      child: Text(
                        "POST",
                        style: TextStyle(
                          color: const Color(0xffe0790b),
                          fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "GET",
                      child: Text(
                        "GET",
                        style: TextStyle(
                          color: const Color(0xff26cda3),
                          fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "PUT",
                      child: Text(
                        "PUT",
                        style: TextStyle(
                          color: const Color(0xff097bed),
                          fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "DELETE",
                      child: Text(
                        "DELETE",
                        style: TextStyle(
                          color: const Color(0xfff22814),
                          fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) async{
                    context.read<ApiBloc>().add(ApiEvent(method: value!));
                  }),
              ),
              SizedBox(
                height: 50,
                width: 250,
                child: TextField(
                  controller: apiUrlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.grey),
                  cursorColor: Colors.grey,
                  onChanged: (val){
                    context.read<ApiBloc>().add(GetUrl(url: val));
                  },
                  decoration: const InputDecoration(
                    hintText: "Enter Url",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e639c))
                    )
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                controller: paramTabController,
                dividerColor: appTheme.isDark? 
                    const Color.fromARGB(255, 61, 61, 61) :
                    const Color.fromARGB(255, 182, 182, 182),
                dividerHeight: 1.5,
                unselectedLabelColor: appTheme.isDark ? 
                    Colors.grey : 
                    const Color.fromARGB(255, 102, 102, 102),
                labelColor: const Color.fromARGB(255, 62, 142, 195),
                indicatorColor: const Color(0xff0e639c),
                indicatorWeight: 2.5,
                tabs: const[
                Tab(text: "Params"),
                Tab(text: "Headers"),
                Tab(text: "Body")
              ]),
              const SizedBox(height: 15),
              SizedBox(
                height: 60 * (((){
                    if(webState.params.isEmpty && webState.headers.isEmpty){
                      return 1.0;
                    }
                    if(webState.params.length > webState.headers.length){
                      return webState.params.length.toDouble() + 1.0;
                    }
                    return webState.headers.length.toDouble() + 1.0;
                  })()),
                child: TabBarView(
                  controller: paramTabController,
                  children:  [
                    Column(
                      children: List.generate(
                        webState.params.length + 1,
                        (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                cursorColor: Colors.grey,
                                style: TextStyle(color: appTheme.selectScreenCardTextColor),
                                controller: paramControllers.keys.toList()[index],
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xff0e639c))
                                  ),
                                  border: OutlineInputBorder()
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 5,
                              child: TextField(
                                cursorColor: Colors.grey,
                                style: TextStyle(color: appTheme.selectScreenCardTextColor),
                                controller: paramControllers.values.toList()[index],
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xff0e639c))
                                  ),
                                  border: OutlineInputBorder()
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (index == webState.params.length) {
                                  if (paramControllers.keys.toList()[index].text.isNotEmpty &&
                                      paramControllers.values.toList()[index].text.isNotEmpty) {
                                    params.addEntries({
                                      paramControllers.keys.toList()[index].text:
                                          paramControllers.values.toList()[index].text
                                    }.entries);
                                  }
                                } else {
                                  params.remove(paramControllers.keys.toList()[index].text);
                                }
                                context.read<ApiBloc>().add(GetParams(params: params));
                                String baseUrl = apiUrlController.text.split('?')[0];
                                String queryString = '';
                                if (params.isNotEmpty) {
                                  queryString = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
                                }
                                String newUrl = queryString.isNotEmpty ? '$baseUrl?$queryString' : baseUrl;
                                apiUrlController.value = apiUrlController.value.copyWith(
                                  text: newUrl,
                                  selection: TextSelection.collapsed(offset: newUrl.length),
                                );
                                context.read<ApiBloc>().add(GetUrl(url: newUrl));
                              },
                              icon: Icon(
                                index == webState.params.length ? Icons.add : Icons.remove,
                                color: Colors.grey,
                              ),
                            ),
                            ]),
                          );
                        })),
                    Column(
                      children: List.generate(
                        webState.headers.length + 1,
                        (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                cursorColor: Colors.grey,
                                style: const TextStyle(color: Colors.grey),
                                controller: headerControllers.keys.toList()[index],
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xff0e639c))
                                  ),
                                  border: OutlineInputBorder()
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 5,
                              child: TextField(
                                cursorColor: Colors.grey,
                                style: const TextStyle(color: Colors.grey),
                                controller: headerControllers.values.toList()[index],
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xff0e639c))
                                  ),
                                  border: OutlineInputBorder()
                                ),
                              ),
                            ),
                            IconButton(onPressed: (){
                              if(index == webState.headers.length){
                                if(headerControllers.keys.toList()[index].text.isNotEmpty && headerControllers.values.toList()[index].text.isNotEmpty) {
                                  headers.addEntries({headerControllers.keys.toList()[index].text:headerControllers.values.toList()[index].text}.entries);
                                }
                              }
                              else{
                                headers.remove(headerControllers.keys.toList()[index].text);
                              }
                              context.read<ApiBloc>().add(GetHeaders(headers: headers));
                            }, icon: Icon(index == webState.headers.length? Icons.add : Icons.remove,color: Colors.grey))
                            ]),
                          );
                        })),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 7),
                      child: TextField(
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: Colors.grey,
                        style: TextStyle(color: Colors.grey),
                        maxLines: null,
                        minLines: null,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xff0e639c))
                          ),
                          border: OutlineInputBorder()
                        ),
                        expands: true,
                      ),
                    )
                  ]
                ),
              ),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () async{
                    Map<String,dynamic> data = 
                      await sendRequest(
                        url: apiUrlController.text,
                        method: webState.method,
                        headers: webState.headers
                      );
                    if(context.mounted) {
                      context.read<ApiBloc>().add(GotApiData(data: data));
                    }
                  }, 
                    style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
                    backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                    foregroundColor: WidgetStatePropertyAll(Colors.white),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))),
                  child: const Text("Send")),
              ),
              webState.data == null 
                ? const SizedBox.shrink()
                : Align(
                  alignment: Alignment.bottomCenter,
                  child: TabBar(
                    controller: apiTabController,
                    dividerColor: const Color.fromARGB(255, 61, 61, 61),
                    dividerHeight: 1.5,
                    unselectedLabelColor: Colors.grey,
                    labelColor: const Color.fromARGB(255, 62, 142, 195),
                    indicatorColor: const Color(0xff0e639c),
                    indicatorWeight: 2.5,
                    tabs: const [
                      Tab(child: Text("{ }",style: TextStyle(fontSize: 22))), 
                      Tab(icon: Icon(FontAwesomeIcons.html5)),
                      Tab(icon: Icon(Icons.raw_on_sharp,size: 35))
                    ]),
                ),
              const SizedBox(height: 20),
              webState.data == null 
                ? const SizedBox.shrink()
                : Expanded(
                  child: TabBarView(
                    controller: apiTabController,
                    children: [
                      JsonWidget(
                        expandIcon: const Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
                        collapseIcon: const Icon(Icons.keyboard_arrow_right_sharp, color: Colors.grey),
                        json: webState.data!
                      ),
                      InAppWebView(
                        onWebViewCreated: (InAppWebViewController webViewController) {
                          webViewController.loadData(data: webState.data!['body']);
                        },
                      ),
                      SingleChildScrollView(child: 
                        Text(webState.data!.toString(),style: const TextStyle(color: Colors.grey)))
                    ]
                  ),
                ),
            ],
          );
        },
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeState.appTheme.selectScreenCardTextColor,
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

//------------------------Settings--------------------

class SettingsTab extends StatelessWidget {
  final AppTheme appTheme;
  final ThemeBloc uiBloc;
  const SettingsTab({
    super.key,
    required this.appTheme,
    required this.uiBloc
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "SETTINGS",
              style: TextStyle(
                fontWeight: appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                color: appTheme.selectScreenCardTextColor
              ),
            ),
          ),
          const SizedBox(height: 15),
          settingsTile(() {
            showDialog(context: context, builder: (context)=>
            BlocProvider<ThemeBloc>.value(
              value: uiBloc,
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  final String currentTheme = themeState.codeForgeConfig['theme'];
                  return AlertDialog(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    insetPadding: const EdgeInsets.only(bottom: 120,top: 190,left: 45,right: 45),
                    titlePadding: const EdgeInsets.all(15),
                    title: Card(
                      color: const Color.fromARGB(255, 37, 37, 37),
                      child: ListTile(
                        leading: const Icon(Icons.color_lens,color: Colors.white,size: 30),
                        title: const Text("Select a theme"),
                        subtitle: Text("${highlightThemes.length} themes available"),
                        titleTextStyle: const TextStyle(fontSize: 25),
                        subtitleTextStyle: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(255, 61, 61, 61),
                    content: 
                    Scrollbar(
                      thumbVisibility: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SingleChildScrollView(
                          child: Column(
                            children: highlightThemes.keys.toList().map((e)=>Card(
                              elevation: 0,
                              color: e==currentTheme?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                                child: ListTile(
                                  iconColor: Colors.grey,
                                  leading: e==currentTheme? const Icon(Icons.radio_button_checked_sharp,color: Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
                                  onTap: () async{
                                    final prefs = await SharedPreferences.getInstance();
                                    final currentState = themeState.codeForgeConfig;
                                    currentState['theme'] = e;
                                    await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                    if (context.mounted) {
                                      context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  title: Text(e.capitalize(),style: TextStyle(color: Colors.grey[400]))),
                                )).toList()
                          ),
                        ),
                      )
                    )
                  );
                },
              ),
            )
            );
          }, 'Themes',
            Icon(
              Icons.color_lens, 
              size: 24,
              color: appTheme.isDark ? Colors.grey : const Color.fromARGB(255, 100, 100, 100)
            ), appTheme.isDark
          ),
          settingsTile((){
          showDialog(context: context, builder: (context)=>
          BlocProvider<ThemeBloc>.value(
            value: uiBloc,
            child: BlocBuilder<ThemeBloc,ThemeState>(
              builder: (context, themeState){
                final String currentFont = themeState.codeForgeConfig['fontFamily'];
                return AlertDialog(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  insetPadding: const EdgeInsets.only(bottom: 120,top: 190,left: 45,right: 45),
                  titlePadding: const EdgeInsets.all(15),
                  backgroundColor: const Color.fromARGB(255, 61, 61, 61),
                  title: Card(
                    color: const Color.fromARGB(255, 37, 37, 37),
                    child: ListTile(
                      leading: const Icon(FontAwesomeIcons.font,color: Colors.white,size: 30),
                      title: const Text(" Select a font   "),
                      subtitle: Text("   ${fonts.length} fonts available"),
                      titleTextStyle: const TextStyle(fontSize: 25),
                      subtitleTextStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  content:Scrollbar(
                    thumbVisibility: true,
                    child:Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SingleChildScrollView(
                        child: Column(
                          children: fonts.map(
                            (e) => Card(
                              color: e==currentFont?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                              elevation: 0,
                              child:
                              ListTile(
                                onTap: () async{
                                  final currentState = themeState.codeForgeConfig;
                                  currentState['fontFamily'] = e;
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                  if (context.mounted) {
                                    context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                                    Navigator.of(context).pop();
                                  }
                                },
                                iconColor: Colors.grey,
                                leading: e == currentFont ? 
                                  const Icon(Icons.radio_button_checked_sharp,color:Color(0xff39a2f2)):
                                  const Icon(Icons.radio_button_off_sharp),
                                title: Text(e.capitalize(), style: TextStyle(color: appTheme.selectScreenCardTextColor))
                              )
                            )
                          ).toList()
                        ),
                      ),
                    )
                  )
                );  
              }
            ),
          ));
        }, "Fonts", Icon(
          FontAwesomeIcons.font,
          color: appTheme.isDark ? Colors.grey : const Color.fromARGB(255, 100, 100, 100),
          size: 21
        ),appTheme.isDark
      )
      ],
      ),
    );
  }
}