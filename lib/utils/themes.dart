import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/agate.dart';
import 'package:flutter_highlight/themes/an-old-hope.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/arduino-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/brown-paper.dart';
import 'package:flutter_highlight/themes/codepen-embed.dart';
import 'package:flutter_highlight/themes/color-brewer.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_highlight/themes/dark.dart';
import 'package:flutter_highlight/themes/default.dart';
import 'package:flutter_highlight/themes/docco.dart';
import 'package:flutter_highlight/themes/far.dart';
import 'package:flutter_highlight/themes/foundation.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/gml.dart';
import 'package:flutter_highlight/themes/googlecode.dart';
import 'package:flutter_highlight/themes/gradient-dark.dart';
import 'package:flutter_highlight/themes/grayscale.dart';
import 'package:flutter_highlight/themes/hybrid.dart';
import 'package:flutter_highlight/themes/idea.dart';
import 'package:flutter_highlight/themes/ir-black.dart';
import 'package:flutter_highlight/themes/isbl-editor-dark.dart';
import 'package:flutter_highlight/themes/isbl-editor-light.dart';
import 'package:flutter_highlight/themes/kimbie.dark.dart';
import 'package:flutter_highlight/themes/kimbie.light.dart';
import 'package:flutter_highlight/themes/lightfair.dart';
import 'package:flutter_highlight/themes/magula.dart';
import 'package:flutter_highlight/themes/mono-blue.dart';
import 'package:flutter_highlight/themes/monokai.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/night-owl.dart';
import 'package:flutter_highlight/themes/nord.dart';
import 'package:flutter_highlight/themes/obsidian.dart';
import 'package:flutter_highlight/themes/paraiso-dark.dart';
import 'package:flutter_highlight/themes/paraiso-light.dart';
import 'package:flutter_highlight/themes/pojoaque.dart';
import 'package:flutter_highlight/themes/purebasic.dart';
import 'package:flutter_highlight/themes/qtcreator_dark.dart';
import 'package:flutter_highlight/themes/qtcreator_light.dart';
import 'package:flutter_highlight/themes/railscasts.dart';
import 'package:flutter_highlight/themes/shades-of-purple.dart';
import 'package:flutter_highlight/themes/solarized-dark.dart';
import 'package:flutter_highlight/themes/solarized-light.dart';
import 'package:flutter_highlight/themes/sunburst.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/xcode.dart';
import 'package:flutter_highlight/themes/xt256.dart';
import 'package:flutter_highlight/themes/zenburn.dart';

final Map<String, dynamic> highlightThemes = {
  'a11y-dark': a11yDarkTheme,
  'a11y-light': a11yLightTheme,
  'agate': agateTheme,
  'an-old-hope': anOldHopeTheme,
  'androidstudio': androidstudioTheme,
  'arduino-light': arduinoLightTheme,
  'atom-one-dark': atomOneDarkTheme,
  'atom-one-dark-reasonable': atomOneDarkReasonableTheme,
  'atom-one-light': atomOneLightTheme,
  'brown-paper': brownPaperTheme,
  'codepen-embed': codepenEmbedTheme,
  'color-brewer': colorBrewerTheme,
  'darcula': darculaTheme,
  'dark': darkTheme,
  'default': defaultTheme,
  'docco': doccoTheme,
  'far': farTheme,
  'foundation': foundationTheme,
  'github': githubTheme,
  'gml': gmlTheme,
  'googlecode': googlecodeTheme,
  'gradient-dark': gradientDarkTheme,
  'grayscale': grayscaleTheme,
  'hybrid': hybridTheme,
  'idea': ideaTheme,
  'ir-black': irBlackTheme,
  'isbl-editor-dark': isblEditorDarkTheme,
  'isbl-editor-light': isblEditorLightTheme,
  'kimbie-dark': kimbieDarkTheme,
  'kimbie-light': kimbieLightTheme,
  'lightfair': lightfairTheme,
  'magula': magulaTheme,
  'mono-blue': monoBlueTheme,
  'monokai': monokaiTheme,
  'monokai-sublime': monokaiSublimeTheme,
  'night-owl': nightOwlTheme,
  'nord': nordTheme,
  'obsidian': obsidianTheme,
  'paraiso-dark': paraisoDarkTheme,
  'paraiso-light': paraisoLightTheme,
  'pojoaque': pojoaqueTheme,
  'purebasic': purebasicTheme,
  'qtcreator-dark': qtcreatorDarkTheme,
  'qtcreator-light': qtcreatorLightTheme,
  'railscasts': railscastsTheme,
  'shades-of-purple': shadesOfPurpleTheme,
  'solarized-dark': solarizedDarkTheme,
  'solarized-light': solarizedLightTheme,
  'sunburst': sunburstTheme,
  'vs': vsTheme,
  'vs2015': vs2015Theme,
  'xcode': xcodeTheme,
  'xt256': xt256Theme,
  'zenburn': zenburnTheme,
};

const appBarDark = AppBarTheme(
    backgroundColor: Color(0xff181818),
    iconTheme: IconThemeData(color: Color(0xff6d6d6d), size: 32));

const tileTheme = ListTileThemeData(
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
    subtitleTextStyle: TextStyle(color: Color(0xff6d6d6d)));

const cardTheme = CardTheme(color: Color.fromARGB(255, 37, 37, 37));
