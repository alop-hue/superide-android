import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/ui/folder_page.dart';
import 'package:vsdroid/ui/editor_page.dart';
import 'package:vsdroid/ui/menu_screen.dart';
import 'package:vsdroid/ui/project_screen.dart';
import 'package:vsdroid/ui/settings.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:path/path.dart' as path;
import 'package:vsdroid/utils/themes.dart';
import 'package:vsdroid/utils/widgets.dart';

class SelectType extends StatefulWidget {
  const  SelectType({super.key});
  @override
  State<SelectType> createState() => _SelectTypeState();
}

class _SelectTypeState extends State<SelectType> {
  final createFileController = TextEditingController();
  final _createFileKey = GlobalKey<FormState>();

  @override
  void dispose() {
    createFileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeBloc, AppThemeState>(
      builder: (context, appThemestate) {
        final appTheme = context.read<AppThemeBloc>().state.appTheme;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          drawer: Drawer(
            backgroundColor: appTheme.selectScreenDrawerBg,
            child: ListView(
              children: [
                drawerTile(
                    () {},
                    "Setup Termux",
                    SvgPicture.asset('assets/icons/Termux.svg',height: 28, width: 28)),
                drawerTile(() {
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const Settings(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => SizeTransition(sizeFactor: animation, child: child)
                  ));
                }, "Settings",
                    const Icon(Icons.settings, color: Colors.blueGrey, size: 31.5)),
                Padding(
                  padding: const EdgeInsets.only(left: 1.5),
                  child: drawerTile(
                      () {},
                      "Github",
                      Icon(
                        FontAwesomeIcons.github,
                        color: appTheme.isDark?Colors.grey:const Color.fromARGB(255, 36, 36, 36),
                        size: 26.5,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: drawerTile(
                      () {},
                      "About",
                      Image.asset('assets/icons/about-512.png',
                          height: 25.5, width: 25.5)),
                ),
                drawerTile(
                  () {},
                  "Buy me a coffee",
                  SvgPicture.asset(
                    width: 29,
                    height: 29,
                    'assets/icons/buy-me-a-coffee.svg',
                    colorFilter: const ColorFilter.mode(Color(0xff4783b7), BlendMode.srcIn)
                  )
                ),
              ],
            ),
          ),
          appBar: AppBar(backgroundColor: Colors.transparent, actions: [
            IconButton(
              onPressed: () async{
                final prefs = await SharedPreferences.getInstance();
                final String? current = prefs.getString("savedAppTheme");
                if(current == "dark"){
                  if(context.mounted) context.read<AppThemeBloc>().add(AppThemeEvent(appTheme: LightTheme()));
                  prefs.setString("savedAppTheme", "light");
                }
                else{
                  if(context.mounted) context.read<AppThemeBloc>().add(AppThemeEvent(appTheme: DarkTheme()));
                  prefs.setString("savedAppTheme", "dark");
                }
              },
              icon: appTheme.appThemeIcon
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(FontAwesomeIcons.github)
              ),
            ),
          ]),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30, top: 18),
                  child: Text("Start",
                    style: TextStyle(
                      color: appTheme.selectScreenCardTextColor,
                      fontSize: 35,
                      fontWeight: appTheme.isDark? FontWeight.w300 : FontWeight.w400,
                      )
                    ),
                  ),
                fileTiles(() {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(FontAwesomeIcons.fileCirclePlus),
                      iconColor: Colors.grey,
                      backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                      title: const Text("Create a new file",style: TextStyle(color: Colors.grey)),
                      content: Form(
                        key: _createFileKey,
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
                              border: OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(25)))),
                            ),
                          ),
                          actions: [
                            Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ElevatedButton(
                                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red[700])),
                                onPressed: (){
                                Navigator.of(context).pop();
                              }, child: const Text("Cancel",style: TextStyle(color: Colors.white))),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                _createFileKey.currentState!.validate();
                                if (createFileController.text.isNotEmpty) {
                                  final file = await createFile(
                                    createFileController.text,
                                    "/storage/emulated/0/VSdroid/files",
                                    context
                                  );
                                  if (context.mounted && file != null) {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context ,animation, secondaryAnimation) => EditorPage(rootDir: file.parent.path ,filePath: file,languageDetails: languages
                                        .firstWhere((language) =>language.extension ==path.extension(file.path).replaceFirst(".", ""))),
                                        transitionsBuilder: (context ,animation, secondaryAnimation, child){
                                          return SizeTransition(sizeFactor: animation, child: child);
                                        }
                                      )
                                    );
                                  }
                                }
                              },
                              child: const Text("OK"))
                          ],
                        ));
                  }, "New File...",
                  const Icon(FontAwesomeIcons.fileCirclePlus),
                  appTheme.isDark
                ),
                fileTiles(() async {
                  if (context.mounted) {
                    final file = await pickFiles(context, appTheme.isDark);
                    if (file != null) {
                      final language = languages.firstWhere(
                          (language) =>language.extension == path.extension(file.path).replaceFirst(".", ""),
                          orElse: () => languages[0]);
                          if(context.mounted) {
                            Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context ,animation, secondaryAnimation) => EditorPage(
                                languageDetails: language, rootDir: file.parent.path,filePath: file
                              ),
                              transitionsBuilder: (context ,animation, secondaryAnimation, child){
                                return SizeTransition(sizeFactor: animation,child: child);
                              }
                            )
                          );
                        }
                    } else {
                      if(context.mounted) {
                        showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:  Text("Failed to open file",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                          backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                          icon: const Icon(Icons.error_outline,size: 35),
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
                  }
                  }, "Open File...",
                  const Icon(FontAwesomeIcons.fileImport),
                  appTheme.isDark
                ),
                fileTiles(() async {
                  final dirPath = await pickDir();
                  if (dirPath != null) {
                    final dir = Directory(dirPath);
                    if (dir.existsSync()) {
                      if(context.mounted){
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context ,animation, secondaryAnimation) => FolderPage(dir: dir),
                            transitionsBuilder: (context ,animation, secondaryAnimation, child){
                              return SizeTransition(sizeFactor: animation,child: child);
                            }
                          )
                          );
                      }
                    }
                  }
                  else{
                    if(context.mounted) {
                        showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:  Text("Failed to open folder",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                          backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                          icon: const Icon(Icons.error_outline,size: 35),
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
                  },
                  "Open Folder...",
                  const Icon(FontAwesomeIcons.folderOpen),
                  appTheme.isDark),
                fileTiles(
                  () {},
                  val: 4,
                  "Open Repository...",
                  SvgPicture.asset(
                    'assets/icons/code-branch-solid.svg',
                    height: 28,
                    width: 28,
                    colorFilter:const ColorFilter.mode(Color(0xff4783b7), BlendMode.srcIn),
                  ),
                  appTheme.isDark
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        radius: 5,
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context ,animation, secondaryAnimation) => const ProjectScreen(),
                              transitionsBuilder: (context ,animation, secondaryAnimation, child){
                                return SizeTransition(sizeFactor: animation,child: child);
                              }
                            )
                          );
                        },
                        child: SizedBox(
                          height: 60,
                          width: 320,
                          child: Card(
                            color: appTheme.selectScreenCardsBg,
                            child: Align(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.folderTree,color: appTheme.selectScreenCardTextColor),
                                  const SizedBox(width: 12.5),
                                  Text("New Project",style: TextStyle(fontSize: 16.5,color: appTheme.selectScreenCardTextColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        radius: 5,
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context ,animation, secondaryAnimation) => const MenuScreen(),
                              transitionsBuilder: (context ,animation, secondaryAnimation, child){
                                return SizeTransition(sizeFactor: animation,child: child);
                              }
                            )
                          );
                        },
                        child: SizedBox(
                          height: 60,
                          width: 320,
                          child: Card(
                            color: appTheme.selectScreenCardsBg,
                            child: Align(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.fileCode,color: appTheme.selectScreenCardTextColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Open Template",
                                    style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 16.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text("Recent",
                        style: TextStyle(
                          color: appTheme.selectScreenCardTextColor,
                          fontWeight: appTheme.isDark? FontWeight.w300 : FontWeight.w400,
                          fontSize: 35)),
                      const SizedBox(height: 12),
                      BlocBuilder<RecentBloc, RecentState>(
                        builder: (context, recentState) {
                          final List<dynamic> recentData = recentState.recent;
                          return recentState.recent.isEmpty ? Text(
                            "You don't have any recent activity",
                            style: TextStyle(
                              color: appTheme.selectScreenCardTextColor,
                              fontWeight: appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                              fontSize: 18
                            )
                          ):
                          SizedBox(
                            width: 350,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: recentData.length,
                                itemBuilder: (context,index) {
                                  return Card(
                                    child: ListTile(
                                      textColor: appTheme.selectScreenCardTextColor,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                                      onTap: (){
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            pageBuilder: (context ,animation, secondaryAnimation) => 
                                            EditorPage(
                                              filePath: File(recentData[index].keys.toList()[0]),
                                              rootDir: recentData[index][recentData[index].keys.toList()[0]],
                                              languageDetails:((){
                                                final matchingLang = languages.where((lang)=>
                                                  lang.extension == path.extension(recentData[index].keys.toList()[0]).toLowerCase().replaceFirst(".", "")
                                                ).toList();
                                                if(matchingLang.isNotEmpty) return matchingLang[0];
                                                return Language(
                                                  name: "Unknown",
                                                  extension: "null",
                                                  details: "Unknown language",
                                                  language: unknown,
                                                  helloWorld: "Unknown type of file"
                                                );
                                              })() 
                                            ),
                                            transitionsBuilder: (context ,animation, secondaryAnimation, child){
                                              return SizeTransition(sizeFactor: animation,child: child);
                                            }
                                          )
                                        );
                                      },
                                      title:
                                          ((){
                                            if(File(recentData[index].keys.toList()[0]).existsSync()){
                                              return Text(
                                                path.basename(recentData[index].keys.toList()[0]),
                                                style: const TextStyle(fontSize: 17));
                                            }
                                            return Text("${path.basename(recentData[index].keys.toList()[0])} - File not found");
                                          })(),
                                      subtitle: Text(
                                        recentData[index][recentData[index].keys.toList()[0]],
                                        style: TextStyle(
                                          color:appTheme.isDark ? Colors.grey : Colors.grey[600],fontSize: 12)), 
                                      leading: ((){
                                        final matchingLang = languages.where((lang)=>
                                        lang.extension == path.extension(recentData[index].keys.toList()[0]).toLowerCase().replaceFirst(".", "")).toList();
                                        if(matchingLang.isNotEmpty) return matchingLang[0].icon;
                                        return FileIcon(recentData[index].keys.toList()[0]);
                                      })(),
                                    ),
                                  );
                                }
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
