import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:file_tree_view/file_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/terminal/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:path/path.dart' as path;
import 'package:vsdroid/utils/themes.dart';

class HomeScreen extends StatelessWidget {
  final Language languageDetails;
  final File? filePath;
  HomeScreen({super.key, required this.languageDetails, this.filePath});
  final _createFileKey = GlobalKey<FormState>();
  final createFileController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final trasnformationController = TransformationController();
    trasnformationController.value = Matrix4.identity()..scale(1.4);
    final codeEditor = CodeEditor(language: languageDetails,isTemplate: filePath == null,filePath: filePath);
    final ThemeBloc uiBloc = BlocProvider.of<ThemeBloc>(context);

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
          return PopScope(
            canPop: true,
            onPopInvokedWithResult:(didPop, result) async{
              late final File loc;
              if(filePath == null){
                loc = await setTempFile(languageDetails.extension);
              }
              else{
                if(!filePath!.existsSync()){
                  await filePath!.create(recursive: true);
                }
              loc = filePath!;
              }
              loc.writeAsString(codeEditor.code());
              if(context.mounted){
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              drawer: Drawer(
                backgroundColor: const Color(0xff2a2a2a),
                child: Row(
                  children: [
                    Container(
                      color: const Color(0xff181818),
                      child: Column(
                        children: [
                          const SizedBox(height: 25),
                          drawerButtons(() {
                            context.read<StackBloc>().add(StackIndexChange(stackValue: 0));
                          }, Icons.file_copy_outlined,
                              color: const Color(0xff6d6d6d)),
                          drawerButtons(() {
                            context.read<StackBloc>().add(StackIndexChange(stackValue: 1));
                          }, Icons.search),
                          drawerButtons(
                            () {
                              context.read<StackBloc>().add(StackIndexChange(stackValue: 2));
                            },
                            SvgPicture.asset(
                              'assets/icons/code-branch-solid.svg',
                              height: 38,
                              width: 38,
                              colorFilter: const ColorFilter.mode(Color(0xff6d6d6d), BlendMode.srcIn),
                            ),
                          ),
                          drawerButtons(
                            () {
                              context.read<StackBloc>().add(StackIndexChange(stackValue: 3));
                            },
                            SvgPicture.asset(
                              'assets/icons/rest-api-icon.svg',
                              height: 34,
                              width: 34,
                              colorFilter: const ColorFilter.mode(Color(0xff6d6d6d), BlendMode.srcIn),
                            ),
                          ),
                          drawerButtons(() {
                            context.read<StackBloc>().add(StackIndexChange(stackValue: 4));
                          }, Icons.settings),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<StackBloc, StackState>(
                        builder: (context, state) {
                          return IndexedStack(
                            index: state.stackIndex,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 58, left: 20),
                                    child: DirectoryTreeViewer(
                                      rootPath: filePath == null? '/sdcard/VSdroid/Temps': filePath!.parent.path,
                                      fileIconBuilder: (ext) {
                                        return SizedBox(
                                          height: 25,
                                          width: 25,
                                          child:languages.firstWhere(
                                            (lang)=>lang.extension == ext.replaceFirst(".", ""),
                                            orElse: () => languages[0],
                                            ).icon??FileIcon(ext)
                                            );
                                      },
                                      folderClosedicon: SvgPicture.asset('assets/icons/folder.svg',height: 25,width: 25),
                                      folderOpenedicon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 25,width: 25),
                                      folderNameStyle: const TextStyle(color: Color.fromARGB(255, 179, 178, 178),fontSize: 17),
                                      fileNameStyle: const TextStyle(color: Color.fromARGB(255, 179, 178, 178),fontSize: 17,height: 2),
                                      onFileTap: (f) {
                                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                                          builder: (context) => HomeScreen(languageDetails: (() =>languages.firstWhere((language) =>
                                            language.extension == path.extension(f.path).replaceFirst(".", ""),orElse: () =>languages[0]))(),filePath: f)));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 35,horizontal: 5),
                                child: SizedBox(
                                  child: Column(
                                    children: [
                                      ListTile(
                                        trailing: Container(
                                          height: 45,
                                          width: 45,
                                          decoration: const BoxDecoration(
                                            color: Color(0xff0e639c),
                                            borderRadius: BorderRadius.all(Radius.circular(25))
                                          ),
                                          child: const Icon(Icons.search,color: Colors.white)),
                                        title: const TextField(
                                          style: TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                          decoration: InputDecoration(
                                            hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                            hintText: "Search",
                                            border: OutlineInputBorder(
                                            )
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 13.5),
                                      ListTile(
                                        trailing: Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xff0e639c),
                                            borderRadius: BorderRadius.all(Radius.circular(25))
                                          ),
                                          height: 45,
                                          width: 45,
                                          child: const Icon(Icons.find_replace_sharp,color: Colors.white)),
                                        title: const TextField(
                                          style: TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                          decoration: InputDecoration(
                                            hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                            hintText: "Replace",
                                            border: OutlineInputBorder(
                                            )
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 25,left: 10),
                                child: SizedBox(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      const Align(
                                        alignment: Alignment.topLeft,
                                        child: Text("SOURCE CONTROL",style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white))
                                        ),
                                      const SizedBox(height: 13.5),
                                      Text(
                                        "The folder currently open\ndosen't hava a Git repository.\nYou can initialize a repository\nwhich will enable source control\nfeatures powered by Git.",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: (){},
                                        style: const ButtonStyle(
                                          shape: WidgetStatePropertyAll(BeveledRectangleBorder()),
                                          backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                                          textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
                                        ),
                                        child: const Text("Initialize Repository")),
                                      const SizedBox(height: 13.5),
                                      Text(
                                        "You can directly publish this\nfolder to a GitHub repository.\nOnce published, you'll have\naccess to source control\nfeatured powered by Git and GitHub",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(color: Colors.grey[400]),
                                      ),
                                      const SizedBox(height: 13.5),
                                      SizedBox(
                                        width: 200,
                                        child: ElevatedButton(
                                          onPressed: (){},
                                          style: const ButtonStyle(
                                            shape: WidgetStatePropertyAll(BeveledRectangleBorder()),
                                            backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                                            foregroundColor: WidgetStatePropertyAll(Colors.white),
                                            textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
                                          ),
                                          child:  const Row(
                                            children: [
                                              Icon(FontAwesomeIcons.github),
                                              SizedBox(width: 5),
                                              Text("Publish to Github"),
                                            ],
                                          )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30,horizontal: 15),
                                child: SizedBox(
                                  child: Column(
                                    children: [
                                      Card(
                                        child: Row(
                                          children: [
                                            DropdownButton(
                                              value: "post",
                                              dropdownColor: const Color(0xff2b2b2b),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: "post",
                                                  child: Text("POST",style: TextStyle(color: Color(0xffe0790b)))),
                                                DropdownMenuItem(
                                                  value: "get",
                                                  child: Text("GET",style: TextStyle(color: Color(0xff26cda3)))),
                                                DropdownMenuItem(
                                                  value: "put",
                                                  child: Text("PUT",style: TextStyle(color: Color(0xff097bed)))),
                                                DropdownMenuItem(
                                                  value: "delete",
                                                  child: Text("DELETE",style: TextStyle(color: Color(0xfff22814))))
                                              ],
                                              onChanged: (value){}),
                                            const Expanded(
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  hintText: "Enter Url",
                                                  border: OutlineInputBorder()
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: (){}, 
                                         style: const ButtonStyle(
                                          shape: WidgetStatePropertyAll(BeveledRectangleBorder()),
                                          backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                                          textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))),
                                        child: const Text("Send Request"))
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 55),
                                child: Column(
                                  children: [
                                    settingsTile(() {
                                      showDialog(context: context, builder: (context)=>
                                      BlocProvider<ThemeBloc>.value(
                                        value: uiBloc,
                                        child: BlocBuilder<ThemeBloc, ThemeState>(
                                          builder: (context, state) {
                                            final String currentTheme = state.theme;
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
                                                            leading: e==currentTheme?const Icon(Icons.radio_button_checked_sharp,color: Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
                                                            onTap: () async{
                                                              final prefs = await SharedPreferences.getInstance();
                                                              await prefs.setString('selectedTheme', e);
                                                              if (context.mounted) {
                                                                context.read<ThemeBloc>().add(SetTheme(theme: e));
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
                                    }, 'Editor themes',
                                      const Icon(Icons.color_lens, size: 24, color: Colors.grey)),
                                   settingsTile((){
                                    showDialog(context: context, builder: (context)=>
                                    BlocProvider<ThemeBloc>.value(
                                      value: uiBloc,
                                      child: BlocBuilder<ThemeBloc,ThemeState>(builder: (context,state){
                                        final String currentFont = state.fontFamily;
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
                                              (e)=>Card(
                                                color: e==currentFont?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                                                elevation: 0,
                                                child:
                                                ListTile(
                                                  onTap: () async{
                                                    final prefs = await SharedPreferences.getInstance();
                                                    await prefs.setString('selectedFont', e);
                                                    if (context.mounted) {
                                                      context.read<ThemeBloc>().add(SetFont(font: e));
                                                      Navigator.of(context).pop();
                                                    }
                                                  },
                                                  iconColor: Colors.grey,
                                                  leading: e==currentFont?const Icon(Icons.radio_button_checked_sharp,color:Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
                                                  title: Text(e.capitalize(),style: TextStyle(color: Colors.grey[400]))
                                                  ))).toList()
                                              ),
                                            ),
                                          )));
                                      }),
                                    ));
                                  }, "Font style", const Icon(FontAwesomeIcons.font,color: Colors.grey,size: 21))
                                ],
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              appBar: AppBar(
                title: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                        filePath == null? "tempCode.${languageDetails.extension}": path.basename(filePath!.path),
                        style: const TextStyle(color: Colors.white))),
                actions: [
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: TextButton(onPressed: () async{
                          await target!.writeAsString(codeEditor.code());
                          if(context.mounted) {
                            Navigator.of(context).pop();
                          }
                          }, child: const Row(
                              children: [
                                Icon(Icons.save,color: Colors.grey,size: 25),
                                  SizedBox(width: 7),
                                  Text("Save",style: TextStyle(color: Colors.grey,fontSize: 17)),
                                  ],))),
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
                                  Navigator.of(context).pop();
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
                                      ));
                                    }
                                  }
                                }
                                if(context.mounted) {
                                  Navigator.of(context).pop();
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
                                  Navigator.of(context).pop();
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
                        final server = await startServer();
                        if(server!=null) {
                          final terminal = SetupTerminal(projectDir:filePath==null?"/storage/emulated/0/VSdroid/Temps":filePath!.parent.path,server: server);
                          if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>terminal));
                          await NativeChannel.sendCommand(languageDetails, target.path, context);
                        }
                        }
                        else{
                          if(context.mounted) {
                            showDialog(context: context, builder: (context)=>AlertDialog(
                              title: const Text("Failed to connect with Termux",style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
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
                              ));
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow)),
                  IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SetupTerminal(projectDir: filePath==null?"/storage/emulated/0/VSdroid/Temps":filePath!.parent.path)));
                      },
                      icon: const Icon(Icons.terminal, color: Color(0xff717171)))
                ],
              ),
              body: InteractiveViewer(
              transformationController: trasnformationController,
              minScale: 0.1,
              child: codeEditor,
                            )
              
            ),
          );
        },
      );
  }
}
