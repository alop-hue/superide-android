import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:file_tree_view/file_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vsdroid/Terminal/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatelessWidget {
  final Language languageDetails;
  final File? filePath;
  const HomeScreen({super.key, required this.languageDetails, this.filePath});
  static const platform = MethodChannel("com.vsdroid");

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
                              fileIconBuilder: (ext) => FileIcon(ext),
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
                            }, child: const Text("Save"))),
                        PopupMenuItem(
                            child: TextButton(onPressed: () {
                              
                            }, child: const Text("New"))),
                        PopupMenuItem(
                            child: TextButton(onPressed: () {
                              
                            }, child: const Text("Open"))),
                        PopupMenuItem(
                            child: TextButton(onPressed: () {
                              
                            }, child: const Text("Clear")))
                      ]),
              IconButton(
                  onPressed: () async {
                    await target!.writeAsString(codeEditor.code());
                    if (context.mounted) {
                      await NativeChannel.sendCommand(
                          languageDetails, target.path, context);
                    }
                  },
                  icon: const Icon(Icons.play_arrow)),
              IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SetupTerminal(
                            projectDir: "/storage/emulated/0/VSdroid/Temps")));
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
