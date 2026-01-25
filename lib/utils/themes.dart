import 'package:flutter/material.dart';
import 'package:re_highlight/styles/all.dart';
import 'package:xterm/xterm.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final Map<String, Map<String, TextStyle>> highlightThemes = builtinAllThemes..removeWhere(
  (k, v) => v['root']?.backgroundColor == null || v['root']?.color == null
);

final fonts = [
  'monospace',
  'firaCode',
  'cascadia',
  'hack',
  'dejaVuSansMono',
  'inconsolata',
  'jetBrainsMono',
  'proggy',
  'sourceCodePro'
  ];

  const terminalTheme = TerminalTheme(
                cursor: Colors.grey,
                selection: Color.fromARGB(134, 170, 191, 211),
                foreground: Colors.white,
                background: Colors.black,
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
            );
const appBarDark = AppBarTheme(backgroundColor: Color(0xff181818),iconTheme: IconThemeData(color: Colors.grey, size: 32));
const appBarLight = AppBarTheme(backgroundColor: Color.fromARGB(255, 243, 242, 242),iconTheme: IconThemeData(color: Color.fromARGB(255, 25, 25, 25), size: 32));
const darkTileTheme = ListTileThemeData(
  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
  subtitleTextStyle: TextStyle(color: Color(0xff6d6d6d))
);
const lightTileTheme = ListTileThemeData(
  titleTextStyle: TextStyle(color: Color.fromARGB(255, 36, 36, 36), fontSize: 18),
  subtitleTextStyle: TextStyle(color: Color(0xff6d6d6d))
);

const cardDarkTheme = CardTheme(color: Color.fromARGB(255, 37, 37, 37));
const cardLightTheme = CardTheme(color: Color.fromARGB(255, 241, 241, 241));
const popupBtnDarkTheme = PopupMenuThemeData(color: Color.fromARGB(255, 61, 61, 61));
const popupBtnLightTheme = PopupMenuThemeData(color: Color.fromARGB(255, 235, 235, 235));
const progressTheme = ProgressIndicatorThemeData(color: Color(0xff0e639c));

class FolderStyle {
  final dynamic folderClosedicon;
  final dynamic folderOpenedicon;
  final TextStyle? folderNameStyle;
  final dynamic iconForCreateFolder;
  final dynamic iconForCreateFile;
  final dynamic iconForDeleteFolder;
  final dynamic rootFolderClosedIcon;
  final dynamic rootFolderOpenedIcon;
  final double itemGap;
  FolderStyle({
    this.itemGap = 15,
    this.rootFolderClosedIcon = const Icon(Icons.chevron_right_sharp),
    this.rootFolderOpenedIcon = const Icon(Icons.keyboard_arrow_down_sharp),
    this.folderNameStyle = const TextStyle(),
    this.iconForCreateFolder = const Icon(Icons.create_new_folder),
    this.iconForCreateFile =
        const Icon(FontAwesomeIcons.fileCirclePlus, size: 20),
    this.iconForDeleteFolder = const Icon(Icons.delete),
    this.folderClosedicon = const Icon(Icons.folder),
    this.folderOpenedicon = const Icon(Icons.folder_open),
  });
}
class FileStyle {
  final dynamic fileIcon;
  final TextStyle? fileNameStyle;
  final dynamic iconForDeleteFile;
  FileStyle({
    this.fileNameStyle = const TextStyle(),
    this.fileIcon = const Icon(Icons.insert_drive_file),
    this.iconForDeleteFile = const Icon(Icons.delete),
  });
}

class EditingFieldStyle {
  final dynamic folderIcon;
  final dynamic fileIcon;
  final InputDecoration textfieldDecoration;
  final dynamic doneIcon;
  final dynamic cancelIcon;
  final double textFieldHeight;
  final double textFieldWidth;
  final Color? cursorColor;
  final double cursorHeight;
  final double cursorWidth;
  final Radius? cursorRadius;
  final TextAlignVertical? verticalTextAlign;
  final TextStyle? textStyle;
  EditingFieldStyle(
      {this.textFieldHeight = 30,
      this.textFieldWidth = double.infinity,
      this.cursorHeight = 20,
      this.cursorWidth = 2.0,
      this.cursorRadius,
      this.cursorColor,
      this.verticalTextAlign,
      this.textStyle,
      this.textfieldDecoration = const InputDecoration(),
      this.folderIcon = const Icon(Icons.folder),
      this.fileIcon = const Icon(Icons.edit_document),
      this.doneIcon = const Icon(Icons.check),
      this.cancelIcon = const Icon(Icons.close)});
}

abstract class AppTheme{
  bool get isDark;
  Color get scaffoldBg;
  Color get selectScreenCardsBg;
  Color get selectScreenCardTextColor;
  Color get selectScreenDrawerBg;
  Color get editorPageToolSelectedColor;
  Color get editorPageToolSelectedBgColor;
  Color get editorPageToolbarBg;
  Color get editorPageToolColor;
  Color get editorPageDrawerBg;
  AppBarTheme get appBarTheme;
  CardTheme get cardTheme;
  PopupMenuThemeData get popupBtnTheme;
  ListTileThemeData get tileTheme;
  Icon get appThemeIcon;
}


class DarkTheme extends AppTheme{
  @override
  bool get isDark => true;
  @override
  Color get scaffoldBg => const Color(0xff181818);
  @override
  Color get selectScreenCardTextColor => const Color.fromARGB(255, 193, 193, 193);
  @override
  Color get selectScreenCardsBg => const Color(0xff2b2b2b);
  @override
  Color get selectScreenDrawerBg => const Color.fromARGB(255, 34, 34, 34);
  @override
  Color get editorPageToolSelectedColor => Colors.grey[400]!;
  @override
  Color get editorPageToolSelectedBgColor => const Color.fromARGB(255, 61, 61, 61);
  @override
  Color get editorPageDrawerBg => const Color(0xff2a2a2a);
  @override
  Color get editorPageToolColor => const Color(0xff6d6d6d);
  @override
  Color get editorPageToolbarBg => const Color(0xff181818);
  @override
  AppBarTheme get appBarTheme => appBarDark;
  @override
  CardTheme get cardTheme => cardDarkTheme;
  @override
  PopupMenuThemeData get popupBtnTheme => popupBtnDarkTheme;
  @override
  ListTileThemeData get tileTheme => darkTileTheme;
  @override
  Icon get appThemeIcon => const Icon(Icons.light_mode, color: Colors.grey,);
}

class LightTheme extends AppTheme{
  @override
  bool get isDark => false;
  @override
  Color get scaffoldBg => Colors.white;
  @override
  Color get selectScreenCardTextColor => const Color.fromARGB(255, 47, 47, 47);
  @override
  Color get selectScreenCardsBg => const Color.fromARGB(255, 232, 232, 232);
  @override
  Color get selectScreenDrawerBg => const Color.fromARGB(255, 255, 255, 255);
  @override
  Color get editorPageToolSelectedColor => const Color.fromARGB(255, 37, 37, 37);
  @override
  Color get editorPageToolSelectedBgColor => const Color.fromARGB(255, 186, 186, 186);
  @override
  Color get editorPageDrawerBg => const Color.fromARGB(255, 230, 230, 230);
  @override
  Color get editorPageToolColor => const Color.fromARGB(255, 151, 151, 151);
  @override
  Color get editorPageToolbarBg => Colors.white;
  @override
  AppBarTheme get appBarTheme => appBarLight;
  @override
  CardTheme get cardTheme => cardLightTheme;
  @override
  PopupMenuThemeData get popupBtnTheme => popupBtnLightTheme;
  @override
  ListTileThemeData get tileTheme => lightTileTheme;
  @override
  Icon get appThemeIcon => const Icon(Icons.dark_mode, color: Color.fromARGB(255, 36, 36, 36));
}

final Map<String, AppTheme> themeMap = {"dark": DarkTheme(), "light": LightTheme()};