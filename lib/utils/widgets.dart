import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../bloc/repo_bloc/repo_bloc.dart';
import '../bloc/ui_bloc/ui_bloc.dart';
import '../utils/functions.dart';
import '../utils/languages.dart';
import '../utils/themes.dart';
import '../utils/constants.dart';

Directory? _findRepoRoot(File file) {
  try {
    Directory dir = file.parent;
    while (true) {
      if (Directory(path.join(dir.path, '.git')).existsSync()) return dir;
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }
  } catch (_) {}
  return null;
}

String _extractGitFilename(String gitStatusLine) {
  String fileName = gitStatusLine.substring(2).trim();
  
  if (fileName.startsWith('"') && fileName.endsWith('"')) {
    fileName = fileName.substring(1, fileName.length - 1);
  }
  
  return fileName;
}

void _refreshRepoStatusForFile(BuildContext context, File file) {
  try {
    final root = _findRepoRoot(file);
    if (root != null) context.read<RepoStatusBloc>().add(LoadRepoStatus(root.path));
  } catch (_) {}
}

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



class CodeEditor extends StatefulWidget {
  final File filePath;
  final CodeForgeController codeController;
  final UndoRedoController undoRedoController;
  final Language language;
  final FindController findController;
  final bool showFindPanel;
  final VoidCallback? onFindPanelClose;
  const CodeEditor({
    super.key,
    required this.codeController,
    required this.undoRedoController,
    required this.filePath,
    required this.language,
    required this.findController,
    this.showFindPanel = false,
    this.onFindPanelClose,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> with AutomaticKeepAliveClientMixin{
  double _initialFontSize = 10.0;
  double _currentScale = 1.0;
  Timer? _saveTimer, _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    final controller = widget.codeController;
    final generalState = context.read<GeneralBloc>().state;
    controller.addListener(() {
      if (!mounted) return;
      if (generalState.generalSettings['autoSave'] ?? true) {
        _saveTimer?.cancel();
        _saveTimer = Timer(
          const Duration(milliseconds: 85),
          () {
            try {
              controller.saveFile();
            } catch (_) {}
            _statusRefreshTimer?.cancel();
            _statusRefreshTimer = Timer(const Duration(milliseconds: 400), () {
              if (mounted) {
                _refreshRepoStatusForFile(context, widget.filePath);
              }
            });
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final codeController = widget.codeController;
    return BlocBuilder<GeneralBloc, GeneralState>(
      builder: (context, generalState) {
        return BlocBuilder<ConfigBloc, ConfigState>(
          builder: (context, configState) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (details) {
                if (details.pointerCount == 2) {
                  _initialFontSize = configState.fontSize;
                }
              },
              onScaleUpdate: (details) {
                if (details.pointerCount == 2) {
                  _currentScale = details.scale;
                  double newFontSize = _initialFontSize * _currentScale;
                  newFontSize = newFontSize.clamp(8.0, 48.0);
                  context.read<ConfigBloc>().add(
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
                        configState.codeForgeConfig['indentLineStatus'],
                    selectionStyle: CodeSelectionStyle(
                      selectionColor: Colors.blueAccent.withAlpha(80),
                      cursorBubbleColor: Colors.blue,
                    ),
                    matchHighlightStyle: const MatchHighlightStyle(
                      currentMatchStyle: TextStyle(
                        backgroundColor: Color(0xFFFFA726),
                      ),
                      otherMatchStyle: TextStyle(
                        backgroundColor: Color(0x55FFFF00),
                      ),
                    ),
                    editorTheme:
                        highlightThemes[configState.codeForgeConfig['theme']],
                    textStyle: TextStyle(
                      fontFamily: configState.codeForgeConfig['fontFamily'],
                      fontSize: configState.fontSize,
                    ),
                    controller: codeController,
                    findController: widget.findController,
                    finderBuilder: (context, findController) {
                      return FindPanelWidget(
                        controller: findController,
                        onClose: widget.onFindPanelClose,
                      );
                    },
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



const double _kFindPanelWidth = 380;
const double _kFindPanelHeight = 36;
const double _kReplacePanelHeight = _kFindPanelHeight * 2;
const double _kFindIconSize = 18;
const double _kFindInputFontSize = 13;
const double _kFindResultFontSize = 11;

class FindPanelWidget extends StatelessWidget implements PreferredSizeWidget {
  final FindController controller;
  final VoidCallback? onClose;

  const FindPanelWidget({
    super.key,
    required this.controller,
    this.onClose,
  });

  @override
  Size get preferredSize => Size(
    double.infinity,
    !controller.isActive
        ? 0
        : (controller.isReplaceMode ? _kReplacePanelHeight : _kFindPanelHeight + 2) + 10,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (!controller.isActive) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: 8, top: 4),
          alignment: Alignment.topRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (n, e) {
                if (e.logicalKey == LogicalKeyboardKey.escape) {
                  controller.isActive = false;
                  onClose?.call();
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.tab &&
                    controller.isReplaceMode &&
                    controller.findInputFocusNode.hasFocus) {
                  controller.replaceInputFocusNode.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                width: _kFindPanelWidth,
                decoration: BoxDecoration(
                  color: const Color(0xff252526),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        controller.isReplaceMode
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        maxWidth: 22,
                        minHeight: preferredSize.height,
                        maxHeight: preferredSize.height,
                      ),
                      tooltip: 'Toggle Replace',
                      onPressed: controller.toggleReplaceMode,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFindRow(context),
                          if (controller.isReplaceMode) _buildReplaceRow(context),
                          if (!controller.isReplaceMode) const SizedBox(height: 2),
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
    );
  }

  Widget _buildFindRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _kFindPanelHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildTextField(
                  focusNode: controller.findInputFocusNode,
                  controller: controller.findInputController,
                  iconsWidth: 60,
                  padding: const EdgeInsets.only(left: 3, right: 5, top: 4, bottom: 2),
                  hintText: 'Find',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCheckText(
                      context: context,
                      text: 'Aa',
                      tooltip: 'Match Case',
                      checked: controller.caseSensitive,
                      onPressed: controller.toggleCaseSensitive,
                    ),
                    _buildCheckText(
                      context: context,
                      text: 'W',
                      tooltip: 'Match Whole Word',
                      checked: controller.matchWholeWord,
                      onPressed: controller.toggleMatchWholeWord,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildCheckText(
                        context: context,
                        text: '\u2022\u2731',
                        tooltip: 'Use Regular Expression',
                        checked: controller.isRegex,
                        onPressed: controller.toggleRegex,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildResultText(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(
              icon: Icons.arrow_upward,
              tooltip: 'Previous (Shift+Enter)',
              onPressed: controller.matchCount == 0 ? null : controller.previous,
            ),
            _buildIconButton(
              icon: Icons.arrow_downward,
              tooltip: 'Next (Enter)',
              onPressed: controller.matchCount == 0 ? null : controller.next,
            ),
            _buildIconButton(
              icon: Icons.close,
              tooltip: 'Close (Escape)',
              onPressed: () {
                controller.toggleActive();
                onClose?.call();
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ],
    );
  }

  Widget _buildReplaceRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _kFindPanelHeight,
            child: _buildTextField(
              focusNode: controller.replaceInputFocusNode,
              controller: controller.replaceInputController,
              padding: const EdgeInsets.only(left: 3, right: 5, top: 2, bottom: 4),
              hintText: 'Replace',
              onSubmit: (_) {
                controller.replace();
                controller.replaceInputFocusNode.requestFocus();
              },
            ),
          ),
        ),
        _buildIconButton(
          icon: Icons.done,
          tooltip: 'Replace',
          onPressed: controller.matchCount == 0 ? null : controller.replace,
        ),
        _buildIconButton(
          icon: Icons.done_all,
          tooltip: 'Replace All',
          onPressed: controller.matchCount == 0 ? null : controller.replaceAll,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    double iconsWidth = 0,
    EdgeInsets padding = EdgeInsets.zero,
    String? hintText,
    ValueChanged<String>? onSubmit,
  }) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        maxLines: 1,
        focusNode: focusNode,
        autofocus: false,
        style: const TextStyle(fontSize: _kFindInputFontSize, color: Colors.white),
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xff3c3c3c),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: _kFindInputFontSize),
          contentPadding: EdgeInsets.fromLTRB(8, 5, iconsWidth, 5),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(
              width: 0.5,
              color: Colors.grey[700]!,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(
              width: 1,
              color: Color(0xff0178b9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckText({
    required BuildContext context,
    required String text,
    required String tooltip,
    required bool checked,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              text,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _kFindInputFontSize,
                color: checked ? const Color(0xff0178b9) : Colors.grey[500],
                fontWeight: checked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon, 
            size: _kFindIconSize, 
            color: onPressed != null ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildResultText() {
    final text = controller.matchCount == 0
        ? 'No results'
        : '${controller.currentMatchIndex + 1}/${controller.matchCount}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: _kFindResultFontSize,
          color: controller.matchCount == 0 ? Colors.red[300] : Colors.grey[400],
        ),
      ),
    );
  }
}



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
              child: CodeEditor(
                language: language,
                undoRedoController: undoRedoController,
                codeController: controller,
                filePath: editor.filePath,
                findController: editor.findController!,
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
                          double currentFontSize = context.read<ConfigBloc>().state.fontSize;
                          context.read<ConfigBloc>().add(SetFontSize(fontSize:  currentFontSize * 1.15));
                        }
                      ),
                      bottomTool(
                        appTheme.isDark,
                        Icons.zoom_out,
                        (){
                          double currentFontSize = context.read<ConfigBloc>().state.fontSize;
                          context.read<ConfigBloc>().add(SetFontSize(fontSize:  currentFontSize * 0.9));
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



class DirectoryTreeViewerCustom extends StatefulWidget {
  final String rootPath;
  final bool isUnfoldedFirst;
  final bool enableCreateFolderOption;
  final bool enableCreateFileOption;
  final bool enableDeleteFolderOption;
  final bool enableDeleteFileOption;
  final bool enableRenameFolderOption;
  final bool enableRenameFileOption;
  final bool enableGitFeatures;
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
    this.enableGitFeatures = false,
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

  (Color, String?) _getFileColor(File file, RepoStatusState repoState) {
    const defaultColor = Colors.white;
    if (repoState is! RepoStatusLoaded) return (defaultColor, null);
    final relativePath = path.relative(file.path, from: widget.rootPath);
    for (final line in repoState.staged) {
      final fileName = _extractGitFilename(line);
      if (fileName == relativePath) {
        final status = line.substring(0, 2).trim();
        final indicator = gitFileStatus[status];
        return (indicator?.$2 ?? defaultColor, indicator?.$1);
      }
    }
    for (final line in repoState.unstaged) {
      final fileName = _extractGitFilename(line);
      if (fileName == relativePath) {
        final status = line.substring(0, 2).trim();
        final indicator = gitFileStatus[status];
        return (indicator?.$2 ?? defaultColor, indicator?.$1);
      }
    }
    return (defaultColor, null);
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
    if (!isUnfolded(parentPath)) {
      toggleFolder(parentPath);
    }
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
    try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.rootPath)); } catch (_) {}
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
      } catch (_) {
        
      }
    }
    stopRenaming();
    try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.rootPath)); } catch (_) {}
  }

  void _showFolderContextMenu(BuildContext context, Directory directory, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final isRootDirectory = directory.path == widget.rootPath;
    
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
        if (widget.enableRenameFolderOption && !isRootDirectory)
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
        if (isRootDirectory)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.refresh, size: 25, color: widget.appTheme.selectScreenCardTextColor),
                const SizedBox(width: 8),
                Text(
                  'Refresh Explorer',
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
                if(context.mounted){
                  try {
                    context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.rootPath));
                  } catch (_) {}
                }
              },
            ),
          ),
        if (isRootDirectory)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.unfold_more, size: 25, color: widget.appTheme.selectScreenCardTextColor),
                const SizedBox(width: 8),
                Text(
                  'Expand All',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => _expandAllFolders(),
            ),
          ),
        if (isRootDirectory)
          PopupMenuItem(
            child: Row(
              children: [
                Icon(Icons.unfold_less, size: 25, color: widget.appTheme.selectScreenCardTextColor),
                const SizedBox(width: 8),
                Text(
                  'Collapse All',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor,
                    fontSize: 16
                  ),
                ),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
              () => _collapseAllFolders(),
            ),
          ),
        if (widget.enableDeleteFolderOption && !isRootDirectory)
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
            onTap: () => _showDeleteFolderConfirmation(context, directory),
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
            onTap: () => _showDeleteFileConfirmation(context, file),
          ),
      ],
    );
  }

  Widget _buildDirectoryTree(Directory directory, RepoStatusState repoState) {
    final entries = directory.listSync();
    entries.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

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
                      ? _buildDirectoryTree(entry, repoState)
                      : _buildFileItem(entry as File, repoState),
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

  Widget _buildFileItem(File file, RepoStatusState repoState) {
    if (renamingPath == file.path) {
      return _buildRenameField(file.path, false);
    }

    final (color, letter) = _getFileColor(file, repoState);
    final baseStyle = widget.fileStyle?.fileNameStyle ?? FileStyle().fileNameStyle ?? const TextStyle();
    final key = GlobalKey();
    return InkWell(
      key: key,
      onTap: () => widget.onFileTap?.call(file),
      onLongPress: () {
        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
        final position = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
        _showFileContextMenu(context, file, position);
      },
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
              style: baseStyle.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if(letter != null) Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              letter,
              style: baseStyle.copyWith(color: color, fontSize: 15),
            ),
          ),
          if (widget.fileActions != null) ...widget.fileActions!,
        ],
      ),
    );
  }

  void _expandAllFolders() {
    final folderBloc = context.read<FolderBloc>();
    final allPaths = _getAllDirectoryPaths(Directory(widget.rootPath));
    folderBloc.setAllFoldersExpanded(allPaths, true);
  }

  void _collapseAllFolders() {
    final folderBloc = context.read<FolderBloc>();
    final allPaths = _getAllDirectoryPaths(Directory(widget.rootPath));
    folderBloc.setAllFoldersExpanded(allPaths, false);
  }

  List<String> _getAllDirectoryPaths(Directory directory) {
    final paths = <String>[];
    try {
      final entries = directory.listSync(recursive: true);
      for (final entry in entries) {
        if (entry is Directory) {
          paths.add(entry.path);
        }
      }
    } catch (_) {}
    return paths;
  }

  void _showDeleteFolderConfirmation(BuildContext context, Directory directory) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: widget.appTheme.isDark ? const Color(0xff2b2b2b) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Folder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.appTheme.selectScreenCardTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "${path.basename(directory.path)}" and all its contents? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: widget.appTheme.selectScreenCardTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _performFolderDeletion(context, directory);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performFolderDeletion(BuildContext context, Directory directory) {
    try {
      directory.deleteSync(recursive: true);
      setState(() {});
      if (context.mounted) {
        try {
          context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.rootPath));
        } catch (_) {}
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteFileConfirmation(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: widget.appTheme.isDark ? const Color(0xff2b2b2b) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete File',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.appTheme.selectScreenCardTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "${path.basename(file.path)}"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: widget.appTheme.selectScreenCardTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _performFileDeletion(context, file);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performFileDeletion(BuildContext context, File file) {
    try {
      file.deleteSync();
      setState(() {});
      if (context.mounted) {
        try {
          context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.rootPath));
        } catch (_) {}
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootDirectory = Directory(widget.rootPath);
    if (!rootDirectory.existsSync()) {
      return const Center(child: Text('Directory does not exist'));
    }
    if (widget.enableGitFeatures) {
      return BlocBuilder<RepoStatusBloc, RepoStatusState>(
        builder: (context, repoState) {
          return BlocBuilder<FolderBloc, FolderState>(
            builder: (context, folderState) {
              return SingleChildScrollView(
                child: _buildDirectoryTree(rootDirectory, repoState),
              );
            },
          );
        },
      );
    } else {
      return BlocBuilder<FolderBloc, FolderState>(
        builder: (context, folderState) {
          return SingleChildScrollView(
            child: _buildDirectoryTree(rootDirectory, const RepoStatusInitial()),
          );
        },
      );
    }
  }
}



class FindWordWidget extends StatefulWidget {
  final AppTheme appTheme;
  final TextEditingController findWordController, replaceWordController;
  final ActiveEditorsState editorState;
  final TabController? tabController;
  final String workspacePath;
  final void Function(File file, int lineNumber, String searchQuery)? onFileOpen;
  const FindWordWidget({
    super.key,
    required this.appTheme,
    required this.findWordController,
    required this.editorState,
    required this.replaceWordController,
    required this.tabController,
    required this.workspacePath,
    this.onFileOpen,
  });

  @override
  State<FindWordWidget> createState() => _FindWordWidgetState();
}

class _FindWordWidgetState extends State<FindWordWidget> {
  final ScrollController _resultsScrollController = ScrollController();

  ActiveEditors? _getActiveEditor() {
    if (widget.editorState.activeEditors.isEmpty) return null;
    
    
    if (widget.tabController != null) {
      final index = widget.tabController!.index;
      if (index >= 0 && index < widget.editorState.activeEditors.length) {
        return widget.editorState.activeEditors[index];
      }
    }
    
    
    for (final editor in widget.editorState.activeEditors) {
      if (editor.isActive) {
        return editor;
      }
    }
    
    
    return widget.editorState.activeEditors.first;
  }

  
  
  
  void _goToMatchNearLine(ActiveEditors editor, int targetLine, String searchQuery) {
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

  Future<void> _searchWorkspace(BuildContext context, String query, WorkspaceSearchState searchState) async {
    if (query.isEmpty) {
      context.read<WorkspaceSearchBloc>().add(UpdateSearchResults(results: [], query: ''));
      return;
    }

    context.read<WorkspaceSearchBloc>().add(SetSearching(isSearching: true));

    final results = <SearchResultData>[];
    final dir = Directory(widget.workspacePath);
    
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          
          final relativePath = entity.path.replaceFirst('${widget.workspacePath}/', '');
          if (relativePath.contains('/.') || 
              relativePath.startsWith('.') ||
              relativePath.contains('/build/') ||
              relativePath.contains('/.git/')) {
            continue;
          }
          
          
          final ext = path.extension(entity.path).toLowerCase();
          final textExtensions = ['.dart', '.js', '.ts', '.json', '.xml', '.html', '.css', '.md', '.txt', '.yaml', '.yml', '.java', '.kt', '.py', '.c', '.cpp', '.h', '.hpp', '.sh', '.gradle', '.properties', '.swift', '.m', '.go', '.rs', '.rb', '.php', '.sql', '.vue', '.jsx', '.tsx'];
          if (!textExtensions.contains(ext) && ext.isNotEmpty) {
            continue;
          }

          try {
            final content = await entity.readAsString();
            final lines = content.split('\n');
            
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i];
              bool hasMatch = false;
              
              if (searchState.isRegex) {
                try {
                  final regex = RegExp(query, caseSensitive: searchState.matchCase);
                  hasMatch = regex.hasMatch(line);
                } catch (_) {
                  
                }
              } else if (searchState.matchWholeWord) {
                final pattern = RegExp(
                  '\\b${RegExp.escape(query)}\\b',
                  caseSensitive: searchState.matchCase,
                );
                hasMatch = pattern.hasMatch(line);
              } else {
                hasMatch = searchState.matchCase 
                    ? line.contains(query)
                    : line.toLowerCase().contains(query.toLowerCase());
              }
              
              if (hasMatch) {
                results.add(SearchResultData(
                  filePath: entity.path,
                  lineNumber: i + 1,
                  lineContent: line.trim(),
                  relativePath: relativePath,
                ));
              }
            }
          } catch (_) {
            
          }
        }
      }
    } catch (_) {
      
    }

    if (context.mounted) {
      context.read<WorkspaceSearchBloc>().add(UpdateSearchResults(results: results, query: query));
    }
  }

  Future<void> _replaceInWorkspace(BuildContext context, String findText, String replaceText, WorkspaceSearchState searchState) async {
    if (findText.isEmpty || searchState.results.isEmpty) return;

    final filesModified = <String>{};

    for (final result in searchState.results) {
      try {
        final file = File(result.filePath);
        String content = await file.readAsString();
        String newContent;
        
        if (searchState.isRegex) {
          try {
            final regex = RegExp(findText, caseSensitive: searchState.matchCase);
            newContent = content.replaceAll(regex, replaceText);
          } catch (_) {
            continue;
          }
        } else if (searchState.matchWholeWord) {
          final pattern = RegExp(
            '\\b${RegExp.escape(findText)}\\b',
            caseSensitive: searchState.matchCase,
          );
          newContent = content.replaceAll(pattern, replaceText);
        } else {
          if (searchState.matchCase) {
            newContent = content.replaceAll(findText, replaceText);
          } else {
            newContent = content.replaceAll(
              RegExp(RegExp.escape(findText), caseSensitive: false),
              replaceText,
            );
          }
        }
        
        if (content != newContent) {
          await file.writeAsString(newContent);
          filesModified.add(result.filePath);
        }
      } catch (_) {
        
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Replaced in ${filesModified.length} file(s)'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      _searchWorkspace(context, findText, searchState);
    }
  }

  @override
  void dispose() {
    _resultsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceSearchBloc, WorkspaceSearchState>(
      builder: (context, searchState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 17, bottom: 15),
                child: Text(
                  "SEARCH",
                  style: TextStyle(
                    fontWeight: widget.appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                    color: widget.appTheme.selectScreenCardTextColor,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final activeEditor = _getActiveEditor();
                      if (activeEditor != null && activeEditor.findController != null) {
                        
                        Navigator.of(context).pop();
                        
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          activeEditor.findController!.isActive = true;
                          
                          activeEditor.findController!.findInputFocusNode.requestFocus();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No active editor'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.article_outlined, color: widget.appTheme.selectScreenCardTextColor, size: 18),
                    label: Text(
                      "Find in Current File",
                      style: TextStyle(color: widget.appTheme.selectScreenCardTextColor, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.appTheme.selectScreenCardTextColor.withAlpha(100)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "Search in Workspace",
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(180),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildOptionButton('Aa', 'Match Case', searchState.matchCase, () {
                      context.read<WorkspaceSearchBloc>().add(UpdateSearchOptions(
                        matchCase: !searchState.matchCase,
                        matchWholeWord: searchState.matchWholeWord,
                        isRegex: searchState.isRegex,
                      ));
                      if (widget.findWordController.text.isNotEmpty) {
                        _searchWorkspace(context, widget.findWordController.text, searchState.copyWith(matchCase: !searchState.matchCase));
                      }
                    }),
                    _buildOptionButton('ab', 'Match Word', searchState.matchWholeWord, () {
                      context.read<WorkspaceSearchBloc>().add(UpdateSearchOptions(
                        matchCase: searchState.matchCase,
                        matchWholeWord: !searchState.matchWholeWord,
                        isRegex: searchState.isRegex,
                      ));
                      if (widget.findWordController.text.isNotEmpty) {
                        _searchWorkspace(context, widget.findWordController.text, searchState.copyWith(matchWholeWord: !searchState.matchWholeWord));
                      }
                    }, underline: true),
                    _buildOptionButton('\u2022\u2731', 'Regex', searchState.isRegex, () {
                      context.read<WorkspaceSearchBloc>().add(UpdateSearchOptions(
                        matchCase: searchState.matchCase,
                        matchWholeWord: searchState.matchWholeWord,
                        isRegex: !searchState.isRegex,
                      ));
                      if (widget.findWordController.text.isNotEmpty) {
                        _searchWorkspace(context, widget.findWordController.text, searchState.copyWith(isRegex: !searchState.isRegex));
                      }
                    }),
                  ],
                ),
              ),
              
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: widget.findWordController,
                    onChanged: (value) {
                      if (value.length >= 2) {
                        _searchWorkspace(context, value, searchState);
                      } else if (value.isEmpty) {
                        context.read<WorkspaceSearchBloc>().add(ClearSearchResults());
                      }
                    },
                    onSubmitted: (value) => _searchWorkspace(context, value, searchState),
                    cursorColor: Colors.grey,
                    style: TextStyle(color: widget.appTheme.selectScreenCardTextColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: widget.appTheme.selectScreenCardTextColor.withAlpha(120), fontSize: 14),
                      hintText: "Search",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0178b9))),
                      suffixIcon: widget.findWordController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: widget.appTheme.selectScreenCardTextColor.withAlpha(150)),
                              onPressed: () {
                                widget.findWordController.clear();
                                context.read<WorkspaceSearchBloc>().add(ClearSearchResults());
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: widget.replaceWordController,
                          cursorColor: Colors.grey,
                          style: TextStyle(color: widget.appTheme.selectScreenCardTextColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintStyle: TextStyle(color: widget.appTheme.selectScreenCardTextColor.withAlpha(120), fontSize: 14),
                            hintText: "Replace",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0178b9))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: searchState.results.isNotEmpty
                          ? () => _replaceInWorkspace(
                                context,
                                widget.findWordController.text,
                                widget.replaceWordController.text,
                                searchState,
                              )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: searchState.results.isNotEmpty ? const Color(0xff0e639c) : Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 38,
                        width: 38,
                        child: const Icon(Icons.find_replace, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              if (searchState.isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.appTheme.selectScreenCardTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Searching...",
                        style: TextStyle(
                          color: widget.appTheme.selectScreenCardTextColor.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (searchState.results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Text(
                    "${searchState.results.length} result${searchState.results.length == 1 ? '' : 's'} found",
                    style: TextStyle(
                      color: widget.appTheme.selectScreenCardTextColor.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              
              Expanded(
                child: searchState.results.isEmpty
                    ? Center(
                        child: Text(
                          widget.findWordController.text.isEmpty
                              ? "Enter search term"
                              : searchState.isSearching ? "" : "No results found",
                          style: TextStyle(
                            color: widget.appTheme.selectScreenCardTextColor.withAlpha(100),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _resultsScrollController,
                        itemCount: searchState.results.length,
                        itemBuilder: (context, index) {
                          final result = searchState.results[index];
                          return _buildResultTile(result, searchState.query);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(String text, String tooltip, bool isActive, VoidCallback onTap, {bool underline = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xff0178b9).withAlpha(100) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? widget.appTheme.selectScreenCardTextColor : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: widget.appTheme.selectScreenCardTextColor,
              fontSize: 13,
              decoration: underline ? TextDecoration.underline : null,
              decorationColor: widget.appTheme.selectScreenCardTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultTile(SearchResultData result, String searchQuery) {
    return InkWell(
      onTap: () {
        final file = File(result.filePath);
        
        
        final existingIndex = widget.editorState.activeEditors.indexWhere(
          (editor) => editor.filePath.path == file.path,
        );
        
        if (existingIndex >= 0) {
          
          if (widget.tabController != null) {
            widget.tabController!.animateTo(existingIndex);
          }
          Navigator.of(context).pop();
          
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final editor = widget.editorState.activeEditors[existingIndex];
            if (editor.findController != null) {
              
              _goToMatchNearLine(editor, result.lineNumber, searchQuery);
            }
          });
        } else {
          
          Navigator.of(context).pop();
          widget.onFileOpen?.call(file, result.lineNumber, searchQuery);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: widget.appTheme.selectScreenCardTextColor.withAlpha(30),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 14,
                  width: 14,
                  child: (() {
                    try {
                      final ext = path.extension(result.filePath).replaceAll('.', '');
                      return languages.singleWhere(
                        (lang) => lang.extension.contains(ext),
                      ).icon;
                    } catch (_) {
                      
                      return langtxt.icon;
                    }
                  })(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.relativePath,
                    style: TextStyle(
                      color: widget.appTheme.selectScreenCardTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  ':${result.lineNumber}',
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(120),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              result.lineContent,
              style: TextStyle(
                color: widget.appTheme.selectScreenCardTextColor.withAlpha(180),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}



class SourceControl extends StatefulWidget {
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
  State<SourceControl> createState() => _SourceControlState();
}

class _SourceControlState extends State<SourceControl> {
  bool _isARepo = false;
  late final TextEditingController _commitController;
  late final StreamSubscription<GitCommitState> _commitSub;
  bool _stagedExpanded = true;
  bool _unstagedExpanded = true;
  bool _commitGraphExpanded = true;
  late final ScrollController _commitGraphScrollController;
  final ScrollController _changesListScrollController = ScrollController();

  @override
  void initState() {
    _commitController = TextEditingController(
      text: context.read<GitCommitBloc>().state.commitMessage,
    );

    _commitSub = context.read<GitCommitBloc>().stream.listen((s) {
      final newText = s.commitMessage;
      if (newText != _commitController.text) {
        _commitController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });

    _commitGraphScrollController = ScrollController();

    if (widget.isRepoThere) {
      context.read<RepoStatusBloc>().add(LoadCommitGraph(widget.workSpace));
    }

    super.initState();
  }

  @override
  void dispose() {
    _commitSub.cancel();
    _commitController.dispose();
    _commitGraphScrollController.dispose();
    _changesListScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SourceControl oldWidget) {
    if (oldWidget.workSpace != widget.workSpace) {
      try {
        context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.workSpace));
        if (widget.isRepoThere) {
          context.read<RepoStatusBloc>().add(LoadCommitGraph(widget.workSpace));
        }
      } catch (_) {}
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget _buildCollapsibleChangesList({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required Widget actionButton,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 12, bottom: 4, right: 4),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(150),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(150),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.appTheme.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$itemCount',
                    style: TextStyle(
                      color: widget.appTheme.selectScreenCardTextColor.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
                actionButton,
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            );
          },
          child: isExpanded
              ? ConstrainedBox(
                  key: ValueKey('$title-expanded'),
                  constraints: BoxConstraints(
                    maxHeight: itemCount > 5 ? 250 : itemCount * 50.0,
                  ),
                  child: Scrollbar(
                    controller: _changesListScrollController,
                    thumbVisibility: itemCount > 5,
                    child: ListView.builder(
                      controller: _changesListScrollController,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: itemCount,
                      itemBuilder: itemBuilder,
                    ),
                  ),
                )
              : SizedBox.shrink(key: ValueKey('$title-collapsed')),
        ),
      ],
    );
  }

  Widget _buildCollapsibleCommitGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _commitGraphExpanded = !_commitGraphExpanded),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8, right: 4),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _commitGraphExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(150),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Commit History",
                  style: TextStyle(
                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(150),
                    fontSize: 14,
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            );
          },
          child: _commitGraphExpanded
              ? ConstrainedBox(
                  key: const ValueKey('commit-graph-expanded'),
                  constraints: const BoxConstraints(
                    maxHeight: 600,
                  ),
                  child: BlocBuilder<RepoStatusBloc, RepoStatusState>(
                    builder: (context, state) {
                      if (state is RepoStatusLoaded && state.commits != null) {
                        if (state.commits!.isEmpty) {
                          return Center(child: Text('No commits found', style: TextStyle(color: widget.appTheme.selectScreenCardTextColor)));
                        }
                        final commits = state.commits!;
                        return Scrollbar(
                          controller: _commitGraphScrollController,
                          thumbVisibility: commits.length > 10,
                          child: SingleChildScrollView(
                            controller: _commitGraphScrollController,
                            child: GitCommitGraph(
                              commits: commits,
                              appTheme: widget.appTheme
                            ),
                          ),
                        );
                      } else if (state is RepoStatusLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        return Center(child: Text('Loading commits...', style: TextStyle(color: widget.appTheme.selectScreenCardTextColor)));
                      }
                    }
                  ),
                )
              : SizedBox.shrink(key: const ValueKey('commit-graph-collapsed')),
        ),
      ],
    );
  }

  void _showInitializeRepoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff0e639c).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.create_new_folder,
                      color: Color(0xff0e639c),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Initialize Repository",
                      style: TextStyle(
                        color: widget.appTheme.selectScreenCardTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "This will create a new Git repository in the current folder. This action initializes Git tracking for version control.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.appTheme.selectScreenCardTextColor.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _initializeRepository(widget.workSpace);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0e639c),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Initialize",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPublishToGithubDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.github,
                      color: Colors.black87,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Publish to GitHub",
                      style: TextStyle(
                        color: widget.appTheme.selectScreenCardTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "This will create a new repository on GitHub and push your local code. You'll need to authenticate with GitHub first.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.appTheme.selectScreenCardTextColor.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Make sure you have GitHub CLI installed and authenticated.",
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _publishToGithub();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Publish",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeRepository(String workspacePath) async {
    try {
      await initRepo(workspacePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repository initialized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isARepo = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize repository: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishToGithub() async {
    try {
      
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publishing to GitHub... (Feature coming soon)'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish to GitHub: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTemp = widget.workSpace == templateDir;
    _isARepo = Directory(path.join(widget.workSpace, '.git')).existsSync();
    final List<Widget> noRepoFound = [
            Text(
              "The folder currently open\ndosen't hava a Git repository.\nYou can initialize a repository\nwhich will enable source control\nfeatures powered by Git.",
              textAlign: TextAlign.start,
              style: TextStyle(color: widget.appTheme.isDark ?Colors.grey[400] : widget.appTheme.selectScreenCardTextColor),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showInitializeRepoDialog,
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
              style: TextStyle(color: widget.appTheme.isDark ?Colors.grey[400] : widget.appTheme.selectScreenCardTextColor),
            ),
            const SizedBox(height: 13.5),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _showPublishToGithubDialog,
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
    return !isTemp ? SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 25,left: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topLeft,
              child: Text("SOURCE CONTROL",
                style: TextStyle(
                  fontWeight: widget.appTheme.isDark? FontWeight.w300 : FontWeight.w500,
                  color: widget.appTheme.selectScreenCardTextColor,
                ),
              )
            ),
            const SizedBox(height: 13.5),
            if(!_isARepo) ...noRepoFound,
            if(_isARepo) ...[
              BlocBuilder<GitCommitBloc, GitCommitState>(
                builder: (context, commitState) {
                  return SizedBox(
                    height: 50,
                    width: 250,
                    child: TextField(
                      controller: _commitController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: Colors.grey),
                      cursorColor: Colors.grey,
                      onChanged: (val){
                        context.read<GitCommitBloc>().add(GitCommitEvent(commitMessage: val));
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
                          color: widget.appTheme.selectScreenCardTextColor.withAlpha(120)
                        ),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0e639c))
                        )
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<RepoStatusBloc, RepoStatusState>(
                builder: (_, repoState){
                  final bool stagedEmpty;
                  final bool unstagedEmpty;
                  if (repoState is RepoStatusLoaded) {
                    stagedEmpty = repoState.staged.isEmpty;
                    unstagedEmpty = repoState.unstaged.isEmpty;
                  } else {
                    stagedEmpty = true;
                    unstagedEmpty = true;
                  }
                  return Column(
                    children: [
                      SizedBox(
                        width: 250,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: const WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.only(
                                        topRight: Radius.zero,
                                        bottomRight: Radius.zero,
                                        topLeft: Radius.circular(6),
                                        bottomLeft: Radius.circular(6),
                                      )
                                    )
                                  ),
                                  backgroundColor: WidgetStatePropertyAll(!(stagedEmpty && unstagedEmpty) ? Color(0xff0e639c) : Color.fromARGB(255, 15, 61, 92)),
                                  foregroundColor: WidgetStatePropertyAll(!(stagedEmpty && unstagedEmpty) ? Colors.white: Colors.grey),
                                  textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
                                ),
                                onPressed: () async {
                                  if(stagedEmpty && unstagedEmpty) return;
                                  final commitMessage = context.read<GitCommitBloc>().state.commitMessage;
                                  if(commitMessage.isEmpty){
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:  Text("Commit message cannot be empty.", style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                                        backgroundColor: widget.appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                        icon: const Icon(Icons.info_outline, size: 35),
                                        iconColor: Colors.red,
                                        actionsAlignment: MainAxisAlignment.center,
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("OK")
                                            ),
                                          ],
                                      ),
                                    );
                                    return;
                                  }
                        
                                  if(!stagedEmpty) {
                                    await gitCommit(widget.workSpace, commitMessage);
                                    if(context.mounted){
                                      context.read<GitCommitBloc>().add(GitCommitEvent(commitMessage: ''));
                                      try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.workSpace)); } catch (_) {}
                                    }
                                  } else if(!unstagedEmpty){
                                    final repoBloc = context.read<RepoStatusBloc>();
                                    final gitBloc = context.read<GitCommitBloc>();
                                    showDialog(
                                      context: context,
                                      builder: (context) => BlocProvider.value(
                                        value: repoBloc,
                                        child: BlocProvider.value(
                                          value: gitBloc,
                                          child: AlertDialog(
                                            title:  Text("Changes aren't staged", style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                                            backgroundColor: widget.appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                            icon: const Icon(Icons.warning_amber_outlined,size: 35),
                                            iconColor: Colors.amber,
                                            actionsAlignment: MainAxisAlignment.center,
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("Cancel", style: TextStyle(color: widget.appTheme.selectScreenCardTextColor))
                                                ),
                            
                                                TextButton(
                                                  onPressed: () async{
                                                    await gitCommit(widget.workSpace, commitMessage, all: true);
                                                    if(context.mounted){
                                                      gitBloc.add(GitCommitEvent(commitMessage: ''));
                                                      try {
                                                        repoBloc.add(LoadRepoStatus(widget.workSpace));
                                                      } catch (_) {}
                                                      Navigator.of(context).pop();
                                                    }
                                                  },
                                                  child: const Text("Stage all and Commit", style: TextStyle(color: Colors.blue)),
                                                )
                                              ],
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  } else {
                                    return;
                                  }
                                },
                                child: Text("\u2713 Commit")
                              )
                            ),
                            SizedBox(
                              width: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: BorderDirectional(start: BorderSide(color: Colors.white, width: 0.5)),
                                  color: !(stagedEmpty && unstagedEmpty) ? Color(0xff0e639c) : Color.fromARGB(255, 15, 61, 92),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomRight: Radius.circular(6)
                                  ),
                                ),
                                child: DropdownMenu(
                                  enabled: !(unstagedEmpty && stagedEmpty),
                                  trailingIcon: Icon(
                                    FontAwesomeIcons.caretDown,
                                    color: widget.appTheme.selectScreenCardTextColor,
                                    size: 14,
                                  ),
                                  selectedTrailingIcon: Icon(
                                    FontAwesomeIcons.caretUp,
                                    color: widget.appTheme.selectScreenCardTextColor,
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
                                    backgroundColor: WidgetStatePropertyAll(widget.appTheme.cardTheme.color),
                                  ),
                                  dropdownMenuEntries: [
                                    DropdownMenuEntry(
                                      style: ButtonStyle(
                                        foregroundColor: WidgetStatePropertyAll(widget.appTheme.selectScreenCardTextColor)
                                      ),
                                      value: "Commit and Push", label: "Commit and Push"
                                    ),
                                    DropdownMenuEntry(
                                      style: ButtonStyle(
                                        foregroundColor: WidgetStatePropertyAll(widget.appTheme.selectScreenCardTextColor)
                                      ),
                                      value: "Commit and Sync", label: "Commit and Sync",
                                    )
                                ]),
                              ),
                            )
                          ],
                        ),
                      ),
                      if (repoState is RepoStatusLoading || repoState is RepoStatusInitial) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      ] else if (repoState is RepoStatusError) ...[
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('Error: ${repoState.message}', style: TextStyle(color: widget.appTheme.selectScreenCardTextColor)),
                        )
                      ] else if (repoState is RepoStatusLoaded) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(repoState.staged.isNotEmpty) _buildCollapsibleChangesList(
                              title: "Staged Changes",
                              isExpanded: _stagedExpanded,
                              onToggle: () => setState(() => _stagedExpanded = !_stagedExpanded),
                              itemCount: repoState.staged.length,
                              actionButton: Tooltip(
                                message: "Unstage All Changes",
                                child: IconButton(
                                  onPressed: () async {
                                    await unstageAll(widget.workSpace);
                                    try { 
                                      if(context.mounted) {
                                        context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.workSpace));
                                      }
                                    } catch (_) {}
                                  },
                                  icon: Text(
                                    "—",
                                    style: TextStyle(color: widget.appTheme.selectScreenCardTextColor.withAlpha(180))
                                  )
                                ),
                              ),
                              itemBuilder: (_, index) {
                                final fileName = _extractGitFilename(repoState.staged[index]);
                                final (String, Color) repoIndicator = gitFileStatus[repoState.staged[index].substring(0,2).trim()]!;
                                return ListTile(
                                  visualDensity: VisualDensity(vertical: -4),
                                  leading: SizedBox(
                                    height: 21,
                                    width: 21,
                                    child: ((){
                                      try {
                                        return languages.singleWhere((lang) => lang.extension.contains(path.extension(path.basename(fileName)).replaceAll('.', ''))).icon;
                                      } catch (e) {
                                        debugPrint(e.toString());
                                        return SizedBox.shrink();
                                      }
                                    })()
                                  ),
                                  title: Text(path.basename(fileName)),
                                  subtitle: Text(fileName, style: TextStyle(fontSize: 11)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: "Unstage Changes",
                                        child: IconButton(
                                          onPressed: () async {
                                            await unstageChange(fileName, widget.workSpace);
                                            if(context.mounted){
                                              try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.workSpace)); } catch (_) {}
                                            }
                                          },
                                          icon: Text(
                                            "—",
                                            style: TextStyle(color: widget.appTheme.selectScreenCardTextColor.withAlpha(180))
                                          )
                                        ),
                                      ),
                                      Text(repoIndicator.$1),
                                    ],
                                  ),
                                  titleTextStyle: TextStyle(fontSize: 14, color: repoIndicator.$2),
                                  leadingAndTrailingTextStyle: TextStyle(
                                    color: repoIndicator.$2,
                                    fontWeight: FontWeight.bold
                                  ),
                                );
                              },
                            ),
                            if (repoState.unstaged.isNotEmpty) _buildCollapsibleChangesList(
                              title: "Unstaged Changes",
                              isExpanded: _unstagedExpanded,
                              onToggle: () => setState(() => _unstagedExpanded = !_unstagedExpanded),
                              itemCount: repoState.unstaged.length,
                              actionButton: Tooltip(
                                message: "Stage All Changes",
                                child: IconButton(
                                  onPressed: () async{
                                    await stageAll(widget.workSpace);
                                    if(context.mounted){
                                      try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.workSpace)); } catch (_) {}
                                    }
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    color: widget.appTheme.selectScreenCardTextColor.withAlpha(180),
                                  )
                                ),
                              ),
                              itemBuilder: (_, index) {
                                final fileName = _extractGitFilename(repoState.unstaged[index]);
                                final (String, Color) repoIndicator = gitFileStatus[repoState.unstaged[index].substring(0,2).trim()]!;
                                return ListTile(
                                  visualDensity: VisualDensity(vertical: -4),
                                  leading: SizedBox(
                                    height: 21,
                                    width: 21,
                                    child: ((){
                                      try {
                                        return languages.singleWhere((lang) => lang.extension.contains(path.extension(path.basename(fileName)).replaceAll('.', ''))).icon;
                                      } catch (e) {
                                        debugPrint(e.toString());
                                        return SizedBox.shrink();
                                      }
                                    })()
                                  ),
                                  title: Text(path.basename(fileName), overflow: TextOverflow.ellipsis),
                                  subtitle: Text(fileName, style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: "Discard Change",
                                        child: IconButton(
                                          onPressed: (){
                                            final repoBloc = context.read<RepoStatusBloc>();
                                            showDialog(
                                              context: context, 
                                              builder: (context) => BlocProvider.value(
                                                value: repoBloc,
                                                child: AlertDialog(
                                                  title:  Text("Are you sure want to discard the changes?", style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                                                  backgroundColor: widget.appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                                  icon: const Icon(Icons.info_outline, size: 35),
                                                  iconColor: Colors.blue,
                                                  actionsAlignment: MainAxisAlignment.center,
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 17
                                                          ),
                                                        )
                                                      ),
                                                      const SizedBox(width: 25),
                                                      TextButton(
                                                        onPressed: () async{
                                                          await gitRestoreFile(fileName, widget.workSpace);
                                                          if (context.mounted) {
                                                            try {
                                                              repoBloc.add(LoadRepoStatus(widget.workSpace));
                                                            } catch (_) {}
                                                            Navigator.of(context).pop();
                                                          }
                                                        },
                                                        child: const Text(
                                                          "Yes",
                                                          style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 17
                                                          ),
                                                        )
                                                      ),
                                                    ],
                                                ),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            FontAwesomeIcons.arrowRotateLeft,
                                            size: 13.5,
                                            color: widget.appTheme.selectScreenCardTextColor.withAlpha(180)
                                          )
                                        ),
                                      ),
                                      Tooltip(
                                        message: "Stage Changes",
                                        child: IconButton(
                                          onPressed: () async{
                                            await stageChange(fileName, widget.workSpace);
                                            if(context.mounted){
                                              try { context.read<RepoStatusBloc>().add(LoadRepoStatus(widget.workSpace)); } catch (_) {}    
                                            }
                                          },
                                          icon: Icon(Icons.add, color: widget.appTheme.selectScreenCardTextColor.withAlpha(180))
                                        ),
                                      ),
                                      Text(repoIndicator.$1),
                                    ],
                                  ),
                                  titleTextStyle: TextStyle(fontSize: 14, color: repoIndicator.$2),
                                  leadingAndTrailingTextStyle: TextStyle(
                                    color: repoIndicator.$2,
                                    fontWeight: FontWeight.bold
                                  ),
                                );
                              },
                            ),
                            Divider(
                              thickness: 0.1,
                              endIndent: 12,
                              color: widget.appTheme.selectScreenCardTextColor.withAlpha(180),
                            ),
                            _buildCollapsibleCommitGraph()
                          ],
                        )
                      ]
                    ],
                  );
                }
              )
            ],
          ],
        ),
      ),
    ) : Center(
          child: Text(
            "Cannot initalize a git repository in the temp directory.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.appTheme.selectScreenCardTextColor
            ),
          )
        );
  }
}



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
              } catch (_) {
                
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
      builder: (context, configState) {
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
                    color: configState.appTheme.selectScreenCardTextColor,
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
                                fontWeight: configState.appTheme.isDark
                                    ? FontWeight.w300
                                    : FontWeight.w500,
                                color: configState
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
                                color: configState
                                    .appTheme
                                    .selectScreenCardTextColor
                                    .withAlpha(200),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.history,
                                color: configState
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
                              configState.appTheme.selectScreenCardTextColor,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color:
                                configState.appTheme.selectScreenCardTextColor,
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
                                color: configState
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
                              color: configState
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
                                  color: configState
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
                              final isDark = configState.appTheme.isDark;
                              final config = isDark
                                  ? MarkdownConfig(
                                      configs: [
                                        PConfig(
                                          textStyle: TextStyle(
                                            color: configState
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



class SettingsTab extends StatelessWidget {
  final AppTheme appTheme;
  final ConfigBloc uiBloc;
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
            BlocProvider<ConfigBloc>.value(
              value: uiBloc,
              child: BlocBuilder<ConfigBloc, ConfigState>(
                builder: (context, configState) {
                  final String currentTheme = configState.codeForgeConfig['theme'];
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
                          primary: true,
                          child: Column(
                            children: highlightThemes.keys.toList().map((e)=>Card(
                              elevation: 0,
                              color: e==currentTheme?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                                child: ListTile(
                                  iconColor: Colors.grey,
                                  leading: e==currentTheme? const Icon(Icons.radio_button_checked_sharp,color: Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
                                  onTap: () async{
                                    final prefs = await SharedPreferences.getInstance();
                                    final currentState = configState.codeForgeConfig;
                                    currentState['theme'] = e;
                                    await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                    if (context.mounted) {
                                      context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
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
          BlocProvider<ConfigBloc>.value(
            value: uiBloc,
            child: BlocBuilder<ConfigBloc,ConfigState>(
              builder: (context, configState){
                final String currentFont = configState.codeForgeConfig['fontFamily'];
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
                        primary: true,
                        child: Column(
                          children: fonts.map(
                            (e) => Card(
                              color: e==currentFont?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                              elevation: 0,
                              child:
                              ListTile(
                                onTap: () async{
                                  final currentState = configState.codeForgeConfig;
                                  currentState['fontFamily'] = e;
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                  if (context.mounted) {
                                    context.read<ConfigBloc>().add(ChangeConfigEvent(currentState));
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



const List<Color> _gitGraphColors = [
  Color(0xFF4EC9B0), 
  Color(0xFFCE9178), 
  Color(0xFF569CD6), 
  Color(0xFFB5CEA8), 
  Color(0xFFC586C0), 
  Color(0xFFDCDCAA), 
  Color(0xFF4FC1FF), 
  Color(0xFFD16969), 
  Color(0xFF6A9955), 
  Color(0xFFD7BA7D), 
];

Color _getGraphColor(int index) {
  return _gitGraphColors[index % _gitGraphColors.length];
}

class VSCodeGitGraphPainter extends CustomPainter {
  final CommitRowInfo rowInfo;
  final double laneWidth;
  final double rowHeight;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;
  final double maxWidth;

  VSCodeGitGraphPainter({
    required this.rowInfo,
    required this.textColor,
    required this.secondaryTextColor,
    required this.maxWidth,
    this.laneWidth = 16,
    this.rowHeight = 36,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final nodeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final commitX = rowInfo.commitLane * laneWidth + laneWidth / 2;
    final commitY = rowHeight / 2;

    for (final line in rowInfo.lines) {
      final fromX = line.fromLane * laneWidth + laneWidth / 2;
      final toX = line.toLane * laneWidth + laneWidth / 2;
      final color = _getGraphColor(line.colorIndex);
      linePaint.color = color;

      if (line.isPassThrough) {
        canvas.drawLine(
          Offset(fromX, 0),
          Offset(fromX, rowHeight),
          linePaint,
        );
      } else if (line.fromLane == line.toLane) {
        canvas.drawLine(
          Offset(fromX, commitY + 5),
          Offset(fromX, rowHeight),
          linePaint,
        );
      } else {
        final path = Path();
        
        if (line.toLane > line.fromLane) {
          path.moveTo(fromX, commitY + 5);
          path.lineTo(fromX, commitY + 10);
          path.quadraticBezierTo(
            fromX, rowHeight - 4,
            toX, rowHeight,
          );
        } else {
          path.moveTo(fromX, commitY + 5);
          path.quadraticBezierTo(
            fromX, rowHeight - 4,
            toX, rowHeight,
          );
        }
        canvas.drawPath(path, linePaint);
      }
    }

    linePaint.color = _getGraphColor(rowInfo.colorIndex);
    canvas.drawLine(
      Offset(commitX, 0),
      Offset(commitX, commitY - 5),
      linePaint,
    );

    final nodeColor = _getGraphColor(rowInfo.colorIndex);
    
    if (rowInfo.commit.isMerge) {
      nodePaint.color = nodeColor;
      canvas.drawCircle(Offset(commitX, commitY), 5, nodePaint);
      nodeStrokePaint.color = nodeColor.withAlpha(180);
      canvas.drawCircle(Offset(commitX, commitY), 7, nodeStrokePaint);
    } else {
      nodePaint.color = nodeColor;
      canvas.drawCircle(Offset(commitX, commitY), 5, nodePaint);
    }

    int maxLaneInRow = rowInfo.commitLane;
    for (final line in rowInfo.lines) {
      if (line.fromLane > maxLaneInRow) maxLaneInRow = line.fromLane;
      if (line.toLane > maxLaneInRow) maxLaneInRow = line.toLane;
    }
    
    final graphWidth = (maxLaneInRow + 1) * laneWidth + 12;
    double textStartX = graphWidth;
    final availableWidth = maxWidth - textStartX;
    
    if (availableWidth > 50) {
      if (rowInfo.commit.isMerge) {
        final badgePainter = TextPainter(
          text: TextSpan(
            text: 'Merge',
            style: TextStyle(
              color: _getGraphColor(rowInfo.colorIndex),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        badgePainter.layout();
        
        final badgeWidth = badgePainter.width + 8;
        final badgeHeight = badgePainter.height + 2;
        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(textStartX, 8, badgeWidth, badgeHeight),
          const Radius.circular(3),
        );
        
        final badgeBgPaint = Paint()
          ..color = _getGraphColor(rowInfo.colorIndex).withAlpha(40)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(badgeRect, badgeBgPaint);
        
        final badgeBorderPaint = Paint()
          ..color = _getGraphColor(rowInfo.colorIndex).withAlpha(100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRRect(badgeRect, badgeBorderPaint);
        badgePainter.paint(canvas, Offset(textStartX + 4, 8));
        textStartX += badgeWidth + 6;
      }
      
      final messagePainter = TextPainter(
        text: TextSpan(
          text: rowInfo.commit.message,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      messagePainter.layout(maxWidth: availableWidth - (rowInfo.commit.isMerge ? 50 : 0));
      messagePainter.paint(canvas, Offset(textStartX, 6));
      
      final authorHash = '${rowInfo.commit.author} • ${rowInfo.commit.hash.substring(0, 7)}';
      final authorPainter = TextPainter(
        text: TextSpan(
          text: authorHash,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 10,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      authorPainter.layout(maxWidth: availableWidth);
      authorPainter.paint(canvas, Offset(graphWidth, 22));
    }
  }

  @override
  bool shouldRepaint(covariant VSCodeGitGraphPainter oldDelegate) {
    return oldDelegate.rowInfo != rowInfo || 
           oldDelegate.maxWidth != maxWidth ||
           oldDelegate.textColor != textColor;
  }
}

class GitCommitGraph extends StatelessWidget {
  final List<CommitNode> commits;
  final AppTheme appTheme;

  const GitCommitGraph({super.key, required this.commits, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    final rowInfos = assignVSCodeLanes(commits);
    const contentWidth = 500.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: contentWidth,
        height: commits.length * 36.0,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: rowInfos.length,
          itemBuilder: (context, index) {
            final rowInfo = rowInfos[index];
            return SizedBox(
              height: 36,
              child: CustomPaint(
                size: Size(contentWidth, 36),
                painter: VSCodeGitGraphPainter(
                  rowInfo: rowInfo,
                  isDark: appTheme.isDark,
                  textColor: appTheme.selectScreenCardTextColor,
                  secondaryTextColor: appTheme.selectScreenCardTextColor.withAlpha(150),
                  maxWidth: contentWidth,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
