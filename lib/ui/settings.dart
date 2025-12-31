import 'dart:convert';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ui_bloc/ui_bloc.dart';
import '../utils/functions.dart';
import '../utils/languages.dart';
import '../utils/themes.dart';
import '../utils/widgets.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController apiController = TextEditingController();
  final TextEditingController modelNameController = TextEditingController();
  final TextEditingController modelIdController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final themeScroll = ScrollController(), fontScroll = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final String demoCode =
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
}''';
  final List<String> models = [
    "Gemini",
    "Claude",
    "OpenAI",
    "Grok",
    "DeepSeek",
    "Gorq",
    "TogetherAI",
    "Sonar",
    "OpenRouter",
    "FireWorks",
    ];
  
  @override void dispose() {
    scrollController.dispose();
    themeScroll.dispose();
    fontScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final theme = themeState.codeForgeConfig['theme'];
        final fontFamily = themeState.codeForgeConfig['fontFamily'];
        final isIndentEnabled = themeState.codeForgeConfig['indentLineStatus'];
        final lineWrap = themeState.codeForgeConfig['lineWrap'];
        final enableFolding = themeState.codeForgeConfig['enableFolding'];
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
                child: Scrollbar(
                  controller: scrollController,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      settingsType("General", appThemeState.appTheme.isDark),
                      settingsTile(
                        null,
                        "Auto Save",
                        Icon(Icons.save, color: appThemeState.appTheme.selectScreenCardTextColor, size: 19),
                        appThemeState.appTheme.isDark,
                        trailing: SizedBox(
                          height: 30,
                          width: 55,
                          child: BlocBuilder<GeneralBloc, GeneralState>(
                            builder: (context, generalState) {
                              return FlutterSwitch(
                                toggleColor: Color(0xff002b6e),
                                inactiveToggleColor: Colors.white,
                                activeColor: Color(0xffb0c6fe),
                                value: generalState.generalSettings['autoSave'] ?? true,
                                onToggle: (value) async{
                                  final prefs = await SharedPreferences.getInstance();
                                  final currentState = themeState.codeForgeConfig;
                                  currentState['autoSave'] = value;
                                  await prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                  prefs.setInt("fontSize", value ? 20 : 15);
                                  if(context.mounted) {
                                    final currentval = context.read<GeneralBloc>().state.generalSettings;
                                    currentval['autoSave'] = value;
                                    context.read<GeneralBloc>().add(GeneralEvent(generalSettings: currentval));
                                  }
                                }
                              );
                            },
                          ),
                        ),
                        subTitle: themeState.fontSize > 15 ? "Large" : "Normal"
                      ),
                      settingsDivider,
                      settingsType("Appearance", appThemeState.appTheme.isDark),
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
                          WidgetsBinding.instance.addPostFrameCallback((_){
                            final selectedIndex = highlightThemes.keys.toList().indexOf(currentTheme);
                            themeScroll.jumpTo(selectedIndex * 58);
                          });
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
                              controller: themeScroll,
                              thumbVisibility: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: SingleChildScrollView(
                                  controller: themeScroll,
                                  child: Column(
                                    children: highlightThemes.keys.toList().map((e)=>Card(
                                      elevation: 0,
                                      color: e==currentTheme?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                                      child: ListTile(
                                        iconColor: Colors.grey,
                                        leading: e==currentTheme?const Icon(Icons.radio_button_checked_sharp,color:Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
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
                                        title: Text(e.capitalize())
                                      ))).toList()
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
                            final String currentFont = themeState.codeForgeConfig['fontFamily'];
                            WidgetsBinding.instance.addPostFrameCallback((_){
                              final selectedIndex = fonts.indexOf(currentFont);
                              fontScroll.jumpTo(selectedIndex * 58);
                            });
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
                                controller: fontScroll,
                                thumbVisibility: true,
                                child:Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: SingleChildScrollView(
                                    controller: fontScroll,
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
                        null,
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
                              final currentState = themeState.codeForgeConfig;
                              currentState['indentLineStatus'] = value;
                              if(context.mounted) context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                              prefs.setString("codeForgeConfig", jsonEncode(currentState));                        
                            }
                          ),
                        ),
                        subTitle: isIndentEnabled ? "Enabled" : "Disabled"
                      ),
                      settingsTile(
                        null,
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
                              final currentState = themeState.codeForgeConfig;
                              currentState['lineWrap'] = value;
                              if(context.mounted) context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                              prefs.setString("codeForgeConfig", jsonEncode(currentState));                        
                            }
                          ),
                        ),
                        subTitle: lineWrap ? "Enabled" : "Disabled"
                      ),
                      settingsTile(
                        null,
                        "Code Folding",
                        Icon(
                          Icons.blur_linear,
                          color:  appThemeState.appTheme.selectScreenCardTextColor,
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
                              final currentState = themeState.codeForgeConfig;
                              currentState['enableFolding'] = value;
                              if(context.mounted) context.read<ThemeBloc>().add(ChangeConfigEvent(currentState));
                              prefs.setString("codeForgeConfig", jsonEncode(currentState));                        
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
                          child: CodeForge(
                            lineWrap: lineWrap,
                            enableFolding: enableFolding,
                            selectionStyle: CodeSelectionStyle(
                              selectionColor: Colors.blueAccent.withAlpha(80),
                              cursorBubbleColor: Colors.blue,
                            ),
                            key: ValueKey(CodeForgeDemoKey(
                              theme: theme,
                              fontFamily: fontFamily,
                              indentLineStatus: isIndentEnabled,
                              lineWrap: lineWrap,
                              enableFolding: enableFolding,
                              isDark: appThemeState.appTheme.isDark,
                              
                            )),
                            enableGuideLines: isIndentEnabled,
                            language: languages[6].language,
                            editorTheme: highlightThemes[theme],
                            textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16),
                            initialText: demoCode,
                            readOnly: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      settingsDivider,
                      const SizedBox(height: 20),
                      settingsType("AI Configuration", appThemeState.appTheme.isDark),
                      BlocBuilder<AIBloc, AIState>(
                        builder: (context, aiState) {
                          return Column(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [    
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                                  child: TextButton(
                                    onPressed: (){
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          late final String provider;
                                          return AlertDialog(
                                            backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                            title: Text(
                                              'Create a completion model',
                                              style: TextStyle(
                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                fontSize: 20
                                              ),
                                            ),
                                            content: SizedBox(
                                              height: 350,
                                              width: 350,
                                              child: Form(
                                                key: _formKey,
                                                child: Scrollbar(
                                                  interactive: true,
                                                  thumbVisibility: true,
                                                  child: ListView(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: DropdownButtonFormField(
                                                          dropdownColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                                          hint: Text(
                                                            "Select a Provider",
                                                            style: TextStyle(
                                                              color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                            ),
                                                          ),
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(20)
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(20),
                                                              borderSide: BorderSide(
                                                                color: Colors.lightBlue
                                                              )
                                                            ),
                                                          ),
                                                          items: List.generate(
                                                            models.length, 
                                                            (index) => DropdownMenuItem(
                                                              value: models[index],
                                                              child: Text(
                                                                models[index],
                                                                style: TextStyle(
                                                                  color: appThemeState.appTheme.selectScreenCardTextColor
                                                                ),
                                                              )
                                                            )
                                                          ),
                                                          onChanged: (val){
                                                            provider = val!;
                                                          },
                                                          validator: (value) => value == null ? "Select a valid provider" : null,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: TextFormField(
                                                          style: TextStyle(
                                                            color: appThemeState.appTheme.selectScreenCardTextColor
                                                          ),
                                                          controller: modelNameController,
                                                          cursorColor: Colors.lightBlue,
                                                          decoration: InputDecoration(
                                                            hintText: "model name as per the provider's api",
                                                            hintStyle: TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 12
                                                            ),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(20)
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(20),
                                                              borderSide: BorderSide(
                                                                color: Colors.lightBlue
                                                              )
                                                            ),
                                                            labelText: "model name",
                                                            labelStyle: TextStyle(
                                                              color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                              fontSize: 15
                                                            ),
                                                          ),
                                                          validator: (value) => value == null || value.isEmpty ? "Enter a valid model name" : null,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: TextFormField(
                                                          style: TextStyle(
                                                            color: appThemeState.appTheme.selectScreenCardTextColor
                                                          ),
                                                          controller: apiController,
                                                          cursorColor: Colors.lightBlue,
                                                          decoration: InputDecoration(
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(20)
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(20),
                                                              borderSide: BorderSide(
                                                                color: Colors.lightBlue
                                                              )
                                                            ),
                                                            labelText: "API Key",
                                                            hintText: "API key for the corresponding provider",
                                                            hintStyle: TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 12
                                                            ),
                                                            labelStyle: TextStyle(
                                                              color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                              fontSize: 15
                                                            ),
                                                          ),
                                                          validator: (value) => value == null || value.isEmpty ? "Enter a valid API key" : null,
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: settingsDivider,
                                                      ),
                                                      TextField(
                                                        style: TextStyle(
                                                          color: appThemeState.appTheme.selectScreenCardTextColor
                                                        ),
                                                        controller: modelIdController,
                                                        cursorColor: Colors.lightBlue,
                                                        decoration: InputDecoration(
                                                          hintText: "A unique model ID, leave it empty to generate one",
                                                          hintStyle: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(20)
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(20),
                                                            borderSide: BorderSide(
                                                              color: Colors.lightBlue
                                                            )
                                                          ),
                                                          labelText: "Model ID (Optional)",
                                                          labelStyle: TextStyle(
                                                            color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                            fontSize: 15
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: ()=> Navigator.of(context).pop(),
                                                child: Text('Cancel')
                                              ),
                                              ElevatedButton(
                                                onPressed:() async{
                                                  final prefs = await SharedPreferences.getInstance();
                                                  if(_formKey.currentState!.validate()){
                                                    final modelName = modelNameController.text.trim();
                                                    final apiKey = apiController.text.trim();
                                                    final modelId = ((){
                                                        final modelId = modelIdController.text.trim();
                                                        if(modelId.isEmpty) {
                                                          return "$modelName-${DateTime.now().millisecondsSinceEpoch}";
                                                        }
                                                        return modelId;
                                                      })();
                                                    final aiConfig = {
                                                      modelId:{
                                                        "provider": provider,
                                                        "modelName": modelName,
                                                        "apiKey": apiKey,
                                                      }
                                                    };
                                                    final newConfig = Map<String, dynamic>.from(aiState.config)..addAll(aiConfig);
                                                    prefs.setString('aiConfig', jsonEncode(newConfig));
                                                    if(context.mounted){
                                                      context.read<AIBloc>().add(AIConfigEvent(newConfig));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text("Successfully created model $modelName"))
                                                      );
                                                      Navigator.of(context).pop();
                                                    }
                                                  }
                                                },
                                                child: Text('OK')
                                              )
                                            ],
                                          );
                                        }
                                      );
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all<Color>(Colors.lightBlue),
                                    ),
                                    child: Text(
                                      "Create an AI model +",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13
                                      ),
                                    )
                                  ),
                                ),
                              ),
                               Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 35, 37, 54) : Colors.grey[200],
                                    ),
                                    width: 350,
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: appThemeState.appTheme.isDark ? Colors.indigo : Colors.grey[200],
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(10))
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Text(
                                                "AI Models", 
                                                style: TextStyle(
                                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                                  fontSize: 13
                                                )
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: aiState.config.isEmpty ? Text(
                                            "No models created yet", 
                                            style: TextStyle(
                                              color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                              fontSize: 16
                                            )
                                          ) : Column(
                                            children: aiState.config.entries.map((e) {
                                              return Card(
                                              color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 44, 47, 71) : Colors.grey[200],
                                              child: ListTile(
                                                dense: true,
                                                leading: Icon(Icons.model_training_outlined, color: appThemeState.appTheme.selectScreenCardTextColor),
                                                title: Text(e.key, style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor)),
                                                subtitle: Text(e.value['modelName'], style: TextStyle(color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150))),
                                                trailing: IconButton(
                                                  icon: Icon(Icons.delete,color: Colors.red),
                                                  onPressed: () async{
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                                        title: Text(
                                                          'Delete model ${e.key}?',
                                                          style: TextStyle(
                                                            color: appThemeState.appTheme.selectScreenCardTextColor,
                                                            fontSize: 20
                                                          ),
                                                        ),
                                                        content: Text(
                                                          "Are you sure you want to delete this model? This action cannot be undone.",
                                                          style: TextStyle(
                                                            color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                                            fontSize: 16
                                                          )
                                                        ),
                                                        actions: [
                                                          ElevatedButton(
                                                            onPressed: ()=> Navigator.of(context).pop(),
                                                            child: Text('Cancel')
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () async{
                                                              final currentState = aiState.config;
                                                              currentState.remove(e.key);
                                                              final prefs = await SharedPreferences.getInstance();
                                                              prefs.setString('aiConfig', jsonEncode(currentState));
                                                              if(context.mounted) {
                                                                context.read<AIBloc>().add(AIConfigEvent(currentState));
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(content: Text("Successfully deleted model ${e.key}"))
                                                                );
                                                                Navigator.of(context).pop(true);
                                                              }
                                                            },
                                                            style: ButtonStyle(
                                                              backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                                                            ),
                                                            child: Text('Delete', style: TextStyle(color: Colors.white))
                                                          )
                                                        ],
                                                      )
                                                    );
                                                  }
                                                ),
                                              ),
                                            );
                                            }).toList()
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              settingsTile(
                                null,
                                "Enable AI completion",
                                Icon(
                                  Icons.lightbulb,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  size: 19
                                ),
                                appThemeState.appTheme.isDark,
                                isEnabled: aiState.config.isNotEmpty,
                                trailing: SizedBox(
                                  height: 30,
                                  width: 55,
                                  child: FlutterSwitch(
                                    toggleColor: Color(0xff002b6e),
                                    inactiveToggleColor: Colors.white,
                                    activeColor: Color(0xffb0c6fe),
                                    value: aiState.config.isNotEmpty && aiState.isEnabled, 
                                    onToggle: (value) async{
                                      if(aiState.config.isNotEmpty){
                                        final prefs = await SharedPreferences.getInstance();
                                        if(context.mounted){
                                          final currentValue = themeState.codeForgeConfig;
                                          currentValue['isAIEnabled'] = value;
                                          prefs.setString('codeForgeConfig', jsonEncode(currentValue));
                                          context.read<AIBloc>().add(AIEnableEvent(value));
                                        }
                                      }
                                      else{
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("No AI models created yet. Please create a model first."))
                                        );
                                      }
                                    }
                                  ),
                                ),
                              ),
                              settingsTile(
                                null,
                                "Show on tapping the AI icon",
                                Icon(
                                  Icons.touch_app_rounded,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                ),
                                appThemeState.appTheme.isDark,
                                trailing: SizedBox(
                                  height: 30,
                                  width: 55,
                                  child: FlutterSwitch(
                                    toggleColor: Color(0xff002b6e),
                                    inactiveToggleColor: Colors.white,
                                    activeColor: Color(0xffb0c6fe),
                                    value: aiState.config.isNotEmpty && aiState.showSuggestionOntap && aiState.isEnabled,
                                    onToggle: (val) async{
                                      if(aiState.config.isNotEmpty){
                                        final prefs = await SharedPreferences.getInstance();
                                        if(context.mounted){
                                          context.read<AIBloc>().add(AIModeEvent(val));
                                          final currentState = themeState.codeForgeConfig;
                                          currentState['manualCompletion'] = val;
                                          prefs.setString('codeForgeConfig', jsonEncode(currentState));
                                        }
                                      }
                                      else{
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("No AI models created yet. Please create a model first."))
                                        );
                                      }
                                    }
                                  ),
                                ),
                                subTitle: aiState.showSuggestionOntap ? "Suggestion shows only on tapping the AI icon located in the bottom right corner.\nRcommended, less api usage" 
                                : "Suggestion on every 1.5 seconds if user stops typing.\nHigh api usage",
                              ),
                              settingsTile(
                                () async{
                                  if(aiState.config.isEmpty){
                                    final prefs = await SharedPreferences.getInstance();
                                    if(context.mounted){
                                      prefs.setString('modelSelected', jsonEncode({}));
                                      context.read<AIBloc>().add(ModelSelectEvent({}));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("No AI models created yet. Please create a model first."))
                                      );
                                    }
                                  }
                                  else{
                                    showDialog(
                                      context: context,
                                      builder: (contex) => AlertDialog(
                                        backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                        title: Card(
                                          color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 35, 37, 54) : Colors.grey[400],
                                          child: Padding(
                                            padding: const EdgeInsets.all(9),
                                            child: Text(
                                              "Completion Model",
                                              style: TextStyle(
                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                fontSize: 20
                                              ),
                                            ),
                                          ),
                                        ),
                                        content: SizedBox(
                                          height: 300,
                                          width: 250,
                                          child: RadioGroup<String>(
                                            groupValue: aiState.modelSelected['code'] ?? "",
                                            onChanged: (val) async {
                                              final currentState = aiState.modelSelected;
                                              currentState['code'] = val!;
                                              final prefs = await SharedPreferences.getInstance();
                                              prefs.setString('modelSelected', jsonEncode(currentState));

                                              if (context.mounted) {
                                                context.read<AIBloc>().add(ModelSelectEvent(currentState));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Successfully selected model $val")),
                                                );
                                                Navigator.of(context).pop(true);
                                              }
                                            },
                                            child: ListView(
                                              children: List.generate(aiState.config.length, (index) {
                                                return RadioListTile<String>(
                                                  value: aiState.config.entries.elementAt(index).key,
                                                  title: Text(aiState.config.entries.elementAt(index).key),
                                                  activeColor: appThemeState.appTheme.isDark
                                                      ? const Color(0xffb0c6fe)
                                                      : const Color(0xff181a26),
                                                );
                                              }),
                                            ),
                                          ),

                                        ),
                                      )
                                    );
                                  }
                                },
                                "Select completion model",
                                Icon(
                                  Icons.chrome_reader_mode_outlined,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  size: 19
                                ),
                                appThemeState.appTheme.isDark,
                                subTitle: aiState.modelSelected['code'],
                              ),
                              settingsTile(
                                () async{
                                  if(aiState.config.isEmpty){
                                    final prefs = await SharedPreferences.getInstance();
                                    if(context.mounted){
                                      prefs.setString('modelSelected', jsonEncode({}));
                                      context.read<AIBloc>().add(ModelSelectEvent({}));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("No AI models created yet. Please create a model first."))
                                      );
                                    }
                                  }
                                  else{
                                    showDialog(
                                      context: context,
                                      builder: (contex) => AlertDialog(
                                        backgroundColor: appThemeState.appTheme.isDark ? const Color(0xff181A26) : null,
                                        title: Card(
                                          color: appThemeState.appTheme.isDark ? const Color.fromARGB(255, 35, 37, 54) : Colors.grey[400],
                                          child: Padding(
                                            padding: const EdgeInsets.all(9),
                                            child: Text(
                                              "Chat Model",
                                              style: TextStyle(
                                                color: appThemeState.appTheme.selectScreenCardTextColor,
                                                fontSize: 20
                                              ),
                                            ),
                                          ),
                                        ),
                                        content: SizedBox(
                                          height: 300,
                                          width: 250,
                                          child: RadioGroup<String>(
                                            groupValue: aiState.modelSelected['chat'] ?? "",
                                            onChanged: (val) async {
                                              final prefs = await SharedPreferences.getInstance();
                                              final currentState = aiState.modelSelected;
                                              currentState['chat'] = val!;
                                              prefs.setString('modelSelected', jsonEncode(currentState));

                                              if (context.mounted) {
                                                context.read<AIBloc>().add(ModelSelectEvent(currentState));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Successfully selected model $val")),
                                                );
                                                Navigator.of(context).pop(true);
                                              }
                                            },
                                            child: ListView(
                                              children: List.generate(aiState.config.length, (index) {
                                                return RadioListTile<String>(
                                                  value: aiState.config.entries.elementAt(index).key,
                                                  title: Text(aiState.config.entries.elementAt(index).key),
                                                  activeColor: appThemeState.appTheme.isDark
                                                      ? const Color(0xffb0c6fe)
                                                      : const Color(0xff181a26),
                                                );
                                              }),
                                            ),
                                          ),

                                        ),
                                      )
                                    );
                                  }
                                },
                                "Select chat model",
                                Icon(
                                  Icons.chat,
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  size: 19
                                ),
                                appThemeState.appTheme.isDark,
                                subTitle: aiState.modelSelected['chat']
                              ),
                              settingsDivider
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 35),
                      settingsDivider,
                      const SizedBox(height: 20),
                      settingsType("LSP Configuration", appThemeState.appTheme.isDark),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
