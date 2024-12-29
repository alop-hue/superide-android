import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vsdroid/ui/folder_page.dart';
import 'package:vsdroid/ui/home.dart';
import 'package:vsdroid/ui/menu_screen.dart';
import 'package:vsdroid/ui/settings.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:path/path.dart' as path;

class SelectType extends StatefulWidget {
  const SelectType({super.key});

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 34, 34, 34),
        child: ListView(
          children: [
            drawerTile(
                () {},
                "Setup Termux",
                SvgPicture.asset('assets/icons/Termux.svg',
                    height: 28, width: 28)),
            drawerTile(() {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const Settings()));
            }, "Settings",
                const Icon(Icons.settings, color: Colors.blueGrey, size: 28)),
            Padding(
              padding: const EdgeInsets.only(left: 1.5),
              child: drawerTile(
                  () {},
                  "Github",
                  const Icon(
                    FontAwesomeIcons.github,
                    color: Colors.grey,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: drawerTile(
                  () {},
                  "About",
                  Image.asset('assets/icons/about-512.png',
                      height: 25, width: 25)),
            ),
            drawerTile(
                () {},
                "Buy me a coffee",
                SvgPicture.asset(
                    width: 28,
                    height: 28,
                    'assets/icons/buy-me-a-coffee.svg',
                    colorFilter: const ColorFilter.mode(
                        Color(0xff4783b7), BlendMode.srcIn))),
          ],
        ),
      ),
      appBar: AppBar(backgroundColor: Colors.transparent, actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
              onPressed: () {},
              icon: const Icon(FontAwesomeIcons.github, color: Colors.grey)),
        )
      ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 30, top: 18),
            child: Text("Start",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.w300)),
          ),
          fileTiles(() {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: const Icon(FontAwesomeIcons.fileCirclePlus),
                iconColor: Colors.grey,
                backgroundColor: const Color(0xff2b2b2b),
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
                            borderRadius:
                                BorderRadius.all(Radius.circular(25)),
                            borderSide:
                                BorderSide(color: Color(0xff5090c8))),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(25)))),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ElevatedButton(onPressed: (){
                          Navigator.of(context).pop();
                        }, child: const Text("Cancel")),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          _createFileKey.currentState!.validate();
                          if (createFileController.text.isNotEmpty) {
                            final file = await createFile(createFileController.text, context);
                            if (context.mounted && file != null) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => HomeScreen(filePath: file,languageDetails: languages
                                  .firstWhere((language) =>language.extension ==path.extension(file.path).replaceFirst(".", "")))));
                            }
                          }
                        },
                        child: const Text("OK"))
                    ],
                  ));
          }, "New File...", const Icon(FontAwesomeIcons.fileCirclePlus)),
          fileTiles(() async {
            if (context.mounted) {
              final file = await pickFiles(context);
              if (file != null) {
                final language = languages.firstWhere(
                    (language) =>language.extension == path.extension(file.path).replaceFirst(".", ""),
                    orElse: () => languages[0]);
                    if(context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => HomeScreen(
                          languageDetails: language, filePath: file)));
                    }
              } else {
                if(context.mounted) {
                  showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title:  Text("Failed to open file",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                    backgroundColor: const Color(0xff2b2b2b),
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
          }, "Open File...", const Icon(FontAwesomeIcons.fileImport)),
          fileTiles(() async {
            final dirPath = await pickDir();
            if (dirPath != null) {
              final dir = Directory(dirPath);
              if (dir.existsSync()) {
                if(context.mounted){
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=> FolderPage(dir: dir)));
                }
              }
            }
            else{
              if(context.mounted) {
                  showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title:  Text("Failed to open folder",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                    backgroundColor: const Color(0xff2b2b2b),
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
          }, "Open Folder...", const Icon(FontAwesomeIcons.folderOpen)),
          fileTiles(
              () {},
              val: 4,
              "Open Repository...",
              SvgPicture.asset(
                'assets/icons/code-branch-solid.svg',
                height: 28,
                width: 28,
                colorFilter:const ColorFilter.mode(Color(0xff4783b7), BlendMode.srcIn),
              )),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                InkWell(
                  onTap: () {},
                  child: const SizedBox(
                    height: 60,
                    width: 320,
                    child: Card(
                      color: Color(0xff2b2b2b),
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.folderTree,color: Color.fromARGB(255, 193, 193, 193)),
                            SizedBox(width: 12.5),
                            Text("New Project",style: TextStyle(fontSize: 16.5,color: Color.fromARGB(255, 193, 193, 193))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MenuScreen()));
                  },
                  child: const SizedBox(
                    height: 60,
                    width: 320,
                    child: Card(
                      color: Color(0xff2b2b2b),
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.fileCode,color: Color.fromARGB(255, 193, 193, 193)),
                            SizedBox(width: 5),
                            Text(
                              "Open Template",
                              style: TextStyle(color: Color.fromARGB(255, 193, 193, 193),fontSize: 16.5),
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
          const Padding(
            padding: EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Recent",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 35)),
                SizedBox(height: 12),
                Text("You don't have any recent projects",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
