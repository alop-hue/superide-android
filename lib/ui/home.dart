import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:file_tree_view/file_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vsdroid/Terminal/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatelessWidget {
  final Language languageDetails;
  final File? filePath;
  HomeScreen({super.key, required this.languageDetails, this.filePath});
  static const platform = MethodChannel("com.vsdroid");
  final _createFileKey = GlobalKey<FormState>();
  final createFileController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final trasnformationController = TransformationController();
    trasnformationController.value = Matrix4.identity()..scale(1.4);
    final codeEditor = CodeEditor(
        language: languageDetails,
        theme: highlightThemes['atom-one-dark'],
        isTemplate: filePath == null,
        filePath: filePath);
    return FutureBuilder(
      future: filePath == null? setTempFile(languageDetails.extension):(()async{
        if(!filePath!.existsSync()){
          await filePath!.create(recursive: true);
        }
        return filePath;
      })(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          const Center(child: CircularProgressIndicator());
        }
        final target = snapshot.data; //Todo: Create a text file shows error if snapshot returns null
        return Scaffold(
          drawer: Drawer(
            backgroundColor: const Color(0xff2a2a2a),
            child: Row(
              children: [
                Container(
                  color: const Color(0xff181818),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      drawerButtons(() {}, Icons.file_copy_outlined,
                          bgColor: const Color.fromARGB(49, 188, 188, 188),
                          color: Colors.white60),
                      drawerButtons(() {}, Icons.search),
                      drawerButtons(
                        () {},
                        SvgPicture.asset(
                          'assets/icons/code-branch-solid.svg',
                          height: 38,
                          width: 38,
                          colorFilter: const ColorFilter.mode(
                              Color(0xff6d6d6d), BlendMode.srcIn),
                        ),
                      ),
                      drawerButtons(
                        () {},
                        SvgPicture.asset(
                          'assets/icons/rest-api-icon.svg',
                          height: 34,
                          width: 34,
                          colorFilter: const ColorFilter.mode(
                              Color(0xff6d6d6d), BlendMode.srcIn),
                        ),
                      ),
                      drawerButtons(() {}, Icons.settings),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: 0,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50, left: 20),
                            child: DirectoryTreeViewer(
                              rootPath: filePath == null? '/sdcard/VSdroid/Temps': filePath!.parent.path,
                              fileIconBuilder: (ext) {
                                return SizedBox(
                                  height: 25,
                                  width: 25,
                                  child:languages.firstWhere((language)=>language.extension == ext.replaceFirst(".", "")).icon??FileIcon(ext));
                              },
                              folderClosedicon: SvgPicture.asset('assets/icons/folder.svg',height: 25,width: 25),
                              folderOpenedicon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 25,width: 25),
                              folderNameStyle: const TextStyle(color: Color.fromARGB(255, 179, 178, 178),fontSize: 17),
                              fileNameStyle: const TextStyle(color: Color.fromARGB(255, 179, 178, 178),fontSize: 17,height: 2),
                              onFileTap: (f) {
                                Navigator.of(context).pushReplacement(MaterialPageRoute(
                                  builder: (context) => HomeScreen(languageDetails: (() =>languages.firstWhere((language) =>
                                    language.extension == path.extension(f.path).replaceFirst(".", ""),orElse: () =>languages[0]))())));
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          appBar: AppBar(
            title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                    filePath == null
                        ? "tempCode.${languageDetails.extension}"
                        : path.basename(filePath!.path),
                    style: const TextStyle(color: Colors.white))),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: TextButton(onPressed: () async{
                      await target!.writeAsString(codeEditor.code());
                      }, child: const Row(
                          children: [
                            Icon(Icons.save,color: Colors.grey,size: 25),
                              SizedBox(width: 7),
                              Text("Save",style: TextStyle(color: Colors.grey,fontSize: 17)),
                              ],
                            ))),
                  PopupMenuItem(
                    child: TextButton(onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: const Icon(FontAwesomeIcons.fileCirclePlus),
                          iconColor: Colors.grey,
                          backgroundColor: const Color(0xff2b2b2b),
                          title: const Text("Create a new file",
                              style: TextStyle(color: Colors.grey)),
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
                                  border: OutlineInputBorder(
                                    borderRadius:BorderRadius.all(Radius.circular(25)))),
                                ),
                              ),
                              actions: [
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
                            }, child:  const Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 3),
                                  child: Icon(FontAwesomeIcons.fileCirclePlus,color: Colors.grey,size: 20),
                                ),
                                SizedBox(width: 10),
                                Text("New",style: TextStyle(color: Colors.grey,fontSize: 17)),
                              ],
                            ))),
                  PopupMenuItem(
                    child: TextButton(onPressed: () async{
                      if (context.mounted) {
                        final file = await pickFiles(context);
                        if (file != null) {
                          final language = languages.firstWhere(
                          (language) =>language.extension == path.extension(file.path).replaceFirst(".", ""),
                          orElse: () => languages[0]);
                          if(context.mounted) {Navigator.of(context).pushReplacement(MaterialPageRoute(
                                  builder: (context) => HomeScreen(languageDetails: language, filePath: file)));}
                        } else {
                          if(context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Failed to open file",
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
                                backgroundColor: const Color(0xff2b2b2b),
                                icon: const Icon(Icons.error_outline),
                                iconColor: Colors.red[600],
                                actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("OK"))
                                  ],
                              )
                            );
                                  }
                                }
                              }
                            }, child: const Row(
                              children: [
                                Icon(FontAwesomeIcons.fileImport,color: Colors.grey,size: 20),
                                SizedBox(width: 10),
                                Text("Open",style: TextStyle(color: Colors.grey,fontSize: 17)),
                              ],
                            ))),
                        PopupMenuItem(
                            child: TextButton(onPressed: () {
                              codeEditor.codeController.clear();
                            }, child: const Row(
                              children: [
                                Icon(Icons.clear_sharp,color: Colors.grey,size: 25),
                                SizedBox(width: 7),
                                Text("Clear",style: TextStyle(color: Colors.grey,fontSize: 17)),
                              ],
                            )))
                      ]),
              IconButton(
                  onPressed: () async {
                    await target!.writeAsString(codeEditor.code());
                    if (context.mounted) {
                      await NativeChannel.sendCommand(languageDetails, target.path, context);
                    }
                  },
                  icon: const Icon(Icons.play_arrow)),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SetupTerminal(projectDir: "/storage/emulated/0/VSdroid/Temps")));
                  },
                  icon: const Icon(Icons.terminal, color: Color(0xff717171)))
            ],
          ),
          body: InteractiveViewer(
            transformationController: trasnformationController,
            minScale: 0.1,
            child: codeEditor,
          ),
        );
      },
    );
  }
}
