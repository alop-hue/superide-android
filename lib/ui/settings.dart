import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_crafter/code_crafter.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/utils/widgets.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});
   
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final theme = themeState.codeCrafterConfig['theme'];
        final fontFamily = themeState.codeCrafterConfig['fontFamily'];
        final isIndentEnabled = themeState.codeCrafterConfig['indentLineStatus'];
        final lineWrap = themeState.codeCrafterConfig['lineWrap'];
        final enableFolding = themeState.codeCrafterConfig['enableFolding'];
        return BlocBuilder<AppThemeBloc, AppThemeState>(
          builder: (context, appThemeState) {
            return Scaffold(
              backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text(
                  "Settings", 
                  style: TextStyle(
                    fontSize: 28,
                    color: appThemeState.appTheme.selectScreenCardTextColor
                  )
                )
              ),
              body: Padding(
                padding: const EdgeInsets.only(left: 3, top: 5),
                child: ListView(
                  children: [
                    settingsType("Appearance"),
                    settingsTile(
                      null,
                      "App Theme",
                      appThemeState.appTheme.isDark ? Icon(
                        Icons.dark_mode,
                        color: Colors.grey,
                      ) : Icon(
                        Icons.light_mode,
                        color: const Color.fromARGB(255, 36, 36, 36),
                      ),
                      appThemeState.appTheme.isDark,
                      subTitle: appThemeState.appTheme.isDark ? "Dark" : "Light",
                      trailing: SizedBox(
                        height: 30,
                        width: 55,
                        child: FlutterSwitch(
                          toggleColor: Color(0xff002b6e),
                          inactiveToggleColor: Colors.white,
                          activeColor: Color(0xffb0c6fe),
                          activeIcon: Icon(Icons.dark_mode, color: Colors.white,),
                          inactiveIcon: Icon(Icons.light_mode),
                          value: appThemeState.appTheme.isDark,
                          onToggle: (value) async{
                            final prefs = await SharedPreferences.getInstance();
                            if(value){
                              if(context.mounted) context.read<AppThemeBloc>().add(AppThemeEvent(appTheme: DarkTheme()));
                              prefs.setString("savedAppTheme", "dark");
                            }
                            else{
                              if(context.mounted) context.read<AppThemeBloc>().add(AppThemeEvent(appTheme: LightTheme()));
                              prefs.setString("savedAppTheme", "light");
                            }
                          }
                        ),
                      )
                    ),
                    settingsTile(() {
                      showDialog(context: context, builder: (context) {
                      final String currentTheme = theme;
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
                                leading: e==currentTheme?const Icon(Icons.radio_button_checked_sharp,color:Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
                                onTap: () async{
                                  final prefs = await SharedPreferences.getInstance();
                                  final currentState = themeState.codeCrafterConfig;
                                  currentState['theme'] = e;
                                  await prefs.setString('codeCrafterConfig', jsonEncode(currentState));
                                  if (context.mounted) {
                                    context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                                    Navigator.of(context).pop();
                                  }
                                },
                                title: Text(e.capitalize())),
                              )).toList()
                                ),
                              ),
                            )
                          )
                        );
                      }
                       
                      );
                    }, 'Editor Theme',
                      Icon(Icons.color_lens, size: 22, color: appThemeState.appTheme.selectScreenCardTextColor),
                      appThemeState.appTheme.isDark,
                      subTitle: (theme as String).capitalize()
                    ),
                    settingsTile(
                      (){
                        showDialog(context: context, builder: (context) {
                          final String currentFont = themeState.codeCrafterConfig['fontFamily'];
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
                                          final currentState = themeState.codeCrafterConfig;
                                          currentState['fontFamily'] = e;
                                          final prefs = await SharedPreferences.getInstance();
                                          await prefs.setString('codeCrafterConfig', jsonEncode(currentState));
                                          if (context.mounted) {
                                            context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        iconColor: Colors.grey,
                                        leading: e == currentFont ? 
                                          const Icon(Icons.radio_button_checked_sharp,color:Color(0xff39a2f2)):
                                          const Icon(Icons.radio_button_off_sharp),
                                        title: Text(e.capitalize())
                                      )
                                    )
                                  ).toList()
                                ),
                              ),
                            )
                          )
                        );  
                        });
                      },
                      "Font Style",
                      Icon(FontAwesomeIcons.font,color: appThemeState.appTheme.selectScreenCardTextColor, size: 19),
                      appThemeState.appTheme.isDark,
                      subTitle: (fontFamily as String).capitalize(),
                    ),
                    settingsTile(
                      (){},
                      "Indent Guilde line",
                      Icon(
                        Icons.format_line_spacing_sharp,
                        color: appThemeState.appTheme.selectScreenCardTextColor,
                        size: 19
                      ),
                      appThemeState.appTheme.isDark,
                      trailing: SizedBox(
                        height: 30,
                        width: 55,
                        child: FlutterSwitch(
                          toggleColor: Color(0xff002b6e),
                          inactiveToggleColor: Colors.white,
                          activeColor: Color(0xffb0c6fe),
                          value: isIndentEnabled, 
                          onToggle: (value) async{
                            final prefs = await SharedPreferences.getInstance();
                            final currentState = themeState.codeCrafterConfig;
                            currentState['indentLineStatus'] = value;
                            if(context.mounted) context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                            prefs.setString("codeCrafterConfig", jsonEncode(currentState));                        
                          }
                        ),
                      ),
                      subTitle: isIndentEnabled ? "Enabled" : "Disabled"
                    ),
                    settingsTile(
                      (){},
                      "Line Wrap",
                      Icon(
                        Icons.wrap_text,
                        color: appThemeState.appTheme.selectScreenCardTextColor,
                        size: 19
                      ),
                      appThemeState.appTheme.isDark,
                      trailing: SizedBox(
                        height: 30,
                        width: 55,
                        child: FlutterSwitch(
                          toggleColor: Color(0xff002b6e),
                          inactiveToggleColor: Colors.white,
                          activeColor: Color(0xffb0c6fe),
                          value: lineWrap, 
                          onToggle: (value) async{
                            final prefs = await SharedPreferences.getInstance();
                            final currentState = themeState.codeCrafterConfig;
                            currentState['lineWrap'] = value;
                            if(context.mounted) context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                            prefs.setString("codeCrafterConfig", jsonEncode(currentState));                        
                          }
                        ),
                      ),
                      subTitle: lineWrap ? "Enabled" : "Disabled"
                    ),
                    settingsTile(
                      (){},
                      "Code Folding",
                      Icon(
                        Icons.blur_linear,
                        color: appThemeState.appTheme.selectScreenCardTextColor,
                        size: 19
                      ),
                      appThemeState.appTheme.isDark,
                      trailing: SizedBox(
                        height: 30,
                        width: 55,
                        child: FlutterSwitch(
                          toggleColor: Color(0xff002b6e),
                          inactiveToggleColor: Colors.white,
                          activeColor: Color(0xffb0c6fe),
                          value: enableFolding, 
                          onToggle: (value) async{
                            final prefs = await SharedPreferences.getInstance();
                            final currentState = themeState.codeCrafterConfig;
                            currentState['enableFolding'] = value;
                            if(context.mounted) context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                            prefs.setString("codeCrafterConfig", jsonEncode(currentState));                        
                          }
                        ),
                      ),
                      subTitle: enableFolding ? "Enabled" : "Disabled"
                    ),
                    const SizedBox(height: 25),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 320,
                          maxWidth: 365
                        ),
                        child: CodeCrafter(
                          wrapLines: lineWrap,
                          enableFolding: enableFolding,
                          selectionColor: Colors.blueAccent.withAlpha(80),
                          selectionHandleColor: Colors.blue,
                          key: ValueKey(CodeCrafterDemoKey(
                            theme: theme,
                            fontFamily: fontFamily,
                            indentLineStatus: isIndentEnabled,
                            lineWrap: lineWrap,
                            enableFolding: enableFolding,
                          )),
                          enableRulerLines: isIndentEnabled,
                          controller: CodeCrafterController()
                            ..language = languages[4].language,
                          editorTheme: highlightThemes[theme],
                          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16),
                          initialText: 
'''
#include <stdio.h>

int main() {
    int n = 10, t1 = 0, t2 = 1, nextTerm;
    printf("Fibonacci Series: ");
    for (int i = 1; i <= n; ++i) {
        printf("%d ", t1);
        nextTerm = t1 + t2;
        t1 = t2;
        t2 = nextTerm;
    }
    return 0;
}''',
                          readOnly: true,
                        ),
                      ),
                    ),
                    settingsDivider,
                    settingsType("A I"),
                    settingsDivider
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
