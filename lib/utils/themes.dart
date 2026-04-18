import 'package:flutter/material.dart';
import 'package:re_highlight/styles/all.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';
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

@immutable
class TerminalThemePreset {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color foregroundColor;
  final GhosttyTerminalPalette palette;
  final Color cursorColor;
  final Color selectionColor;
  final Color hyperlinkColor;

  const TerminalThemePreset({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.palette,
    required this.cursorColor,
    required this.selectionColor,
    required this.hyperlinkColor,
  });
}

const String defaultTerminalThemePresetId = 'xterm_classic';
const double defaultTerminalFontSize = 14.0;

const Map<String, TerminalThemePreset> terminalThemePresets = {
  'xterm_classic': TerminalThemePreset(
    id: 'xterm_classic',
    name: 'Xterm Classic',
    backgroundColor: Color(0xFF0A0F14),
    foregroundColor: Color(0xFFE6EDF3),
    palette: GhosttyTerminalPalette.xterm,
    cursorColor: Color(0xFF9AD1C0),
    selectionColor: Color(0x665DA9FF),
    hyperlinkColor: Color(0xFF61AFEF),
  ),
  'matrix_green': TerminalThemePreset(
    id: 'matrix_green',
    name: 'Matrix Green',
    backgroundColor: Color(0xFF060B08),
    foregroundColor: Color(0xFF97F1A0),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF06130A),
        Color(0xFF67D76A),
        Color(0xFF8BFFB1),
        Color(0xFFC0FF9D),
        Color(0xFF62E48F),
        Color(0xFF89EFAF),
        Color(0xFF5CD8A3),
        Color(0xFFB7FFD0),
        Color(0xFF1B3E29),
        Color(0xFF8BFF98),
        Color(0xFFB7FFD8),
        Color(0xFFE1FFC1),
        Color(0xFF88FFC3),
        Color(0xFFA7FFE0),
        Color(0xFF83F5CA),
        Color(0xFFD8FFE8),
      ],
    ),
    cursorColor: Color(0xFF74FFB8),
    selectionColor: Color(0x5537E890),
    hyperlinkColor: Color(0xFF6BFFDC),
  ),
  'amber_noir': TerminalThemePreset(
    id: 'amber_noir',
    name: 'Amber Noir',
    backgroundColor: Color(0xFF12100A),
    foregroundColor: Color(0xFFFFE6B3),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF211A10),
        Color(0xFFFF7E5F),
        Color(0xFFFFB86B),
        Color(0xFFFFD479),
        Color(0xFFF7A76B),
        Color(0xFFFFA07A),
        Color(0xFFFFC28A),
        Color(0xFFFFE8C7),
        Color(0xFF3A2A1B),
        Color(0xFFFF9A82),
        Color(0xFFFFC789),
        Color(0xFFFFE29D),
        Color(0xFFFFBD8C),
        Color(0xFFFFC3A6),
        Color(0xFFFFD3A9),
        Color(0xFFFFF0DA),
      ],
    ),
    cursorColor: Color(0xFFFFC66D),
    selectionColor: Color(0x55FFB347),
    hyperlinkColor: Color(0xFFFFC37A),
  ),
  'ocean_ink': TerminalThemePreset(
    id: 'ocean_ink',
    name: 'Ocean Ink',
    backgroundColor: Color(0xFF08131E),
    foregroundColor: Color(0xFFD4E8FF),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF0D1F30),
        Color(0xFFFA7B7B),
        Color(0xFF54D0C9),
        Color(0xFFF7D17A),
        Color(0xFF63A8FF),
        Color(0xFFC38BFF),
        Color(0xFF55C8FF),
        Color(0xFFD8E8FF),
        Color(0xFF27435E),
        Color(0xFFFF9696),
        Color(0xFF70E5DE),
        Color(0xFFFFE199),
        Color(0xFF83BFFF),
        Color(0xFFD7A7FF),
        Color(0xFF7DD9FF),
        Color(0xFFF1F7FF),
      ],
    ),
    cursorColor: Color(0xFF86D5FF),
    selectionColor: Color(0x554F8DFF),
    hyperlinkColor: Color(0xFF9AC6FF),
  ),
  'retro_phosphor': TerminalThemePreset(
    id: 'retro_phosphor',
    name: 'Retro Phosphor',
    backgroundColor: Color(0xFF0E120B),
    foregroundColor: Color(0xFFD8FFB7),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF151A10),
        Color(0xFFFF8A66),
        Color(0xFFA3E46E),
        Color(0xFFF4DD77),
        Color(0xFF7BB0FF),
        Color(0xFFCE9DFF),
        Color(0xFF8EDBD0),
        Color(0xFFE6F7D3),
        Color(0xFF37442D),
        Color(0xFFFFA985),
        Color(0xFFC4F78E),
        Color(0xFFFFEB98),
        Color(0xFF9CC5FF),
        Color(0xFFDDB8FF),
        Color(0xFFAEEFE4),
        Color(0xFFF5FFE8),
      ],
    ),
    cursorColor: Color(0xFFA8FF90),
    selectionColor: Color(0x554DA35D),
    hyperlinkColor: Color(0xFF9FDDB2),
  ),
  'aurora_borealis': TerminalThemePreset(
    id: 'aurora_borealis',
    name: 'Aurora Borealis',
    backgroundColor: Color(0xFF071B1F),
    foregroundColor: Color(0xFFD7FFF8),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF11242A),
        Color(0xFFFF7C9B),
        Color(0xFF5BE7B2),
        Color(0xFFFAD777),
        Color(0xFF67B9FF),
        Color(0xFFC89DFF),
        Color(0xFF61F0E6),
        Color(0xFFD9F7FF),
        Color(0xFF25414A),
        Color(0xFFFF97AF),
        Color(0xFF82FFD0),
        Color(0xFFFFE69B),
        Color(0xFF8CCDFF),
        Color(0xFFD8B9FF),
        Color(0xFF87FFF3),
        Color(0xFFF1FFFF),
      ],
    ),
    cursorColor: Color(0xFF8EFFE1),
    selectionColor: Color(0x5549D7C3),
    hyperlinkColor: Color(0xFF88D9FF),
  ),
  'neon_city': TerminalThemePreset(
    id: 'neon_city',
    name: 'Neon City',
    backgroundColor: Color(0xFF100A20),
    foregroundColor: Color(0xFFF3E8FF),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF1A1031),
        Color(0xFFFF5CA8),
        Color(0xFF62FFA6),
        Color(0xFFFFE16E),
        Color(0xFF5AA7FF),
        Color(0xFFD27BFF),
        Color(0xFF4BF4FF),
        Color(0xFFEAD9FF),
        Color(0xFF342458),
        Color(0xFFFF85C2),
        Color(0xFF8BFFBE),
        Color(0xFFFFEE9A),
        Color(0xFF88C1FF),
        Color(0xFFE0A8FF),
        Color(0xFF81F9FF),
        Color(0xFFF9F2FF),
      ],
    ),
    cursorColor: Color(0xFFFF7BE6),
    selectionColor: Color(0x55B065FF),
    hyperlinkColor: Color(0xFF8CC8FF),
  ),
  'desert_sand': TerminalThemePreset(
    id: 'desert_sand',
    name: 'Desert Sand',
    backgroundColor: Color(0xFFF7EBD5),
    foregroundColor: Color(0xFF3A2A1A),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF534739),
        Color(0xFFB94A4A),
        Color(0xFF5D8F55),
        Color(0xFFB98633),
        Color(0xFF5A79C8),
        Color(0xFF8A63B9),
        Color(0xFF4F8E97),
        Color(0xFFF5E7D0),
        Color(0xFF7A6D5C),
        Color(0xFFD16868),
        Color(0xFF79A96E),
        Color(0xFFD7A556),
        Color(0xFF7A98DF),
        Color(0xFFA781CF),
        Color(0xFF70AAB2),
        Color(0xFFFFFFFF),
      ],
    ),
    cursorColor: Color(0xFF7C5D2A),
    selectionColor: Color(0x55D6AE63),
    hyperlinkColor: Color(0xFF4E78B7),
  ),
  'lavender_dusk': TerminalThemePreset(
    id: 'lavender_dusk',
    name: 'Lavender Dusk',
    backgroundColor: Color(0xFF1A1428),
    foregroundColor: Color(0xFFF0E9FF),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF231B35),
        Color(0xFFFF8AAE),
        Color(0xFF8EE6A6),
        Color(0xFFF5CF7C),
        Color(0xFF8EA5FF),
        Color(0xFFC89CFF),
        Color(0xFF7EE0E4),
        Color(0xFFEADFFF),
        Color(0xFF3B2E56),
        Color(0xFFFFA4C0),
        Color(0xFFA9F2BB),
        Color(0xFFFFE2A3),
        Color(0xFFAFC0FF),
        Color(0xFFD7B7FF),
        Color(0xFFA1EEF1),
        Color(0xFFF9F4FF),
      ],
    ),
    cursorColor: Color(0xFFD5B1FF),
    selectionColor: Color(0x557B65B0),
    hyperlinkColor: Color(0xFFA9C0FF),
  ),
  'volcanic_ash': TerminalThemePreset(
    id: 'volcanic_ash',
    name: 'Volcanic Ash',
    backgroundColor: Color(0xFF141414),
    foregroundColor: Color(0xFFE7E7E7),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF1F1F1F),
        Color(0xFFE56A54),
        Color(0xFF8BC17A),
        Color(0xFFD1B061),
        Color(0xFF7FA4CF),
        Color(0xFFAF86CC),
        Color(0xFF72BEB5),
        Color(0xFFD9D9D9),
        Color(0xFF3A3A3A),
        Color(0xFFF08A75),
        Color(0xFFA7D69A),
        Color(0xFFE3C988),
        Color(0xFFA0C0E3),
        Color(0xFFC8A7DE),
        Color(0xFF94D2CB),
        Color(0xFFF7F7F7),
      ],
    ),
    cursorColor: Color(0xFFFF8A5B),
    selectionColor: Color(0x55666666),
    hyperlinkColor: Color(0xFFAEC9E8),
  ),
  'arctic_frost': TerminalThemePreset(
    id: 'arctic_frost',
    name: 'Arctic Frost',
    backgroundColor: Color(0xFFEFF6FF),
    foregroundColor: Color(0xFF1B2A3A),
    palette: GhosttyTerminalPalette(
      ansi: <Color>[
        Color(0xFF6C7A8A),
        Color(0xFFC75A66),
        Color(0xFF4E9A78),
        Color(0xFFC49A52),
        Color(0xFF4B7FB8),
        Color(0xFF7C64A8),
        Color(0xFF4E93A2),
        Color(0xFFE6EEF8),
        Color(0xFF8EA1B3),
        Color(0xFFE17684),
        Color(0xFF6FB895),
        Color(0xFFDAB372),
        Color(0xFF6C9BD0),
        Color(0xFF9A83C1),
        Color(0xFF71AFBC),
        Color(0xFFFFFFFF),
      ],
    ),
    cursorColor: Color(0xFF3E79B7),
    selectionColor: Color(0x555CA3E0),
    hyperlinkColor: Color(0xFF3E79B7),
  ),
};

TerminalThemePreset terminalThemePresetFromConfig(dynamic rawId) {
  final id = rawId?.toString() ?? defaultTerminalThemePresetId;
  return terminalThemePresets[id] ??
      terminalThemePresets[defaultTerminalThemePresetId]!;
}

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