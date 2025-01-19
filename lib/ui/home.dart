import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:file_tree_view/file_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_json/flutter_json.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/terminal/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/ui/webview.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:path/path.dart' as path;
import 'package:vsdroid/utils/themes.dart';

class HomeScreen extends StatefulWidget {
  final Language languageDetails;
  final String? rootDir;
  final File? filePath;
  const HomeScreen({super.key, required this.languageDetails, this.filePath, this.rootDir});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin{
  final createFileKey = GlobalKey<FormState>();
  final createFileController = TextEditingController();
  final findWordController = TextEditingController(),replaceWordController = TextEditingController();
  final apiUrlController = TextEditingController();
  late TabController apiTabController, paramTabController;
  Map<String,String> params = {}, headers = {};

  @override 
  void initState(){
    apiTabController =  TabController(length: 3, vsync: this);
    paramTabController = TabController(length: 3, vsync: this);
    setTempFile(widget.languageDetails.extension);
    super.initState();
  }

  @override
  void dispose() {
    apiUrlController.dispose();
    apiTabController.dispose();
    paramTabController.dispose();
    findWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trasnformationController = TransformationController();
    trasnformationController.value = Matrix4.identity()..scale(1.45);
    final codeEditor = CodeEditor(
      isTemplate: widget.filePath == null,
      language: widget.languageDetails,
      filePath: widget.filePath ?? (widget.languageDetails.extension == 'html'
                ?File("/sdcard/VSdroid/Temps/index.html"):widget.languageDetails.extension == 'css'
                  ?File("/sdcard/VSdroid/Temps/style.css"):widget.languageDetails.extension == 'js'
                    ?File("/sdcard/VSdroid/Temps/script.js")
                      :File("/sdcard/VSdroid/Temps/tempCode.${widget.languageDetails.extension}"))
      );
    final ThemeBloc uiBloc = BlocProvider.of<ThemeBloc>(context);

    return FutureBuilder(
        future: widget.filePath == null? setTempFile(widget.languageDetails.extension):(()async{
          if(!widget.filePath!.existsSync()){
            await widget.filePath!.create(recursive: true);
          }
          return widget.filePath;
        })(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            const Center(child: CircularProgressIndicator());
          }
          final target = snapshot.data;
          return Scaffold(
            drawer: BlocBuilder<StackBloc, StackState>(
              buildWhen: (previous, current) => current != previous,
              builder: (context, state) { 
                return Drawer(
                  width: 350,
                  backgroundColor: const Color(0xff2a2a2a),
                  child: Row(
                    children: [
                      Container(
                        color: const Color(0xff181818),
                        child: Column(
                          children: [
                            const SizedBox(height: 25),
                            drawerButtons(
                              () => context.read<StackBloc>().add(StackIndexChange(stackValue: 0)), 
                              Icons.file_copy_outlined,
                              color: state.stackIndex == 0 ?Colors.grey[400]!:const Color(0xff6d6d6d),
                              bgColor: state.stackIndex == 0 ? const Color.fromARGB(255, 61, 61, 61):Colors.transparent
                              ),
                            drawerButtons(
                              () => context.read<StackBloc>().add(StackIndexChange(stackValue: 1)),
                              Icons.search,
                              color: state.stackIndex == 1 ?Colors.grey[400]!:const Color(0xff6d6d6d),
                              bgColor: state.stackIndex == 1 ? const Color.fromARGB(255, 61, 61, 61):Colors.transparent
                            )
                            ,
                            drawerButtons(
                              () => context.read<StackBloc>().add(StackIndexChange(stackValue: 2)),
                              FontAwesomeIcons.codeBranch,
                              color: state.stackIndex == 2 ?Colors.grey[400]!:const Color(0xff6d6d6d),
                              bgColor: state.stackIndex == 2 ? const Color.fromARGB(255, 61, 61, 61):Colors.transparent
                            ),
                            drawerButtons(
                              () => context.read<StackBloc>().add(StackIndexChange(stackValue: 3)),
                              SvgPicture.asset(
                                'assets/icons/rest-api-icon.svg',
                                height: 34,
                                width: 34,
                                colorFilter: ColorFilter.mode(
                                  state.stackIndex == 3 ?Colors.grey[400]!:const Color(0xff6d6d6d), BlendMode.srcIn),
                              ),
                              bgColor: state.stackIndex == 3 ? const Color.fromARGB(255, 61, 61, 61):Colors.transparent
                            ),
                            drawerButtons(
                              () => context.read<StackBloc>().add(StackIndexChange(stackValue: 4)),
                              Icons.settings,
                              color: state.stackIndex == 4 ?Colors.grey[400]!:const Color(0xff6d6d6d),
                              bgColor: state.stackIndex == 4 ? const Color.fromARGB(255, 61, 61, 61):Colors.transparent
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:  IndexedStack(
                          index: state.stackIndex,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 58, left: 20),
                                  child: DirectoryTreeViewer(
                                    rootPath: widget.filePath == null? '/sdcard/VSdroid/Temps': (widget.rootDir ?? widget.filePath!.parent.path),
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
                                    folderClosedicon: SvgPicture.asset('assets/icons/folder.svg',height: 30,width: 30),
                                    folderOpenedicon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 30,width: 30),
                                    folderNameStyle: const TextStyle(color: Color.fromARGB(255, 179, 178, 178),fontSize: 20),
                                    fileNameStyle: const TextStyle(color: Color.fromARGB(255, 179, 178, 178),fontSize: 20,height: 2),
                                    onFileTap: (f) {
                                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                                        builder: (context) => HomeScreen(languageDetails: (() =>languages.firstWhere(
                                          (language) =>language.extension == path.extension(f.path).replaceFirst(".", ""),
                                          orElse: () =>languages[0]))(),filePath: f,rootDir: widget.rootDir)));
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 35,horizontal: 5),
                              child: SizedBox(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 17),
                                      child: Text("SEARCH",style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white)),
                                    ),
                                    const SizedBox(height: 15),
                                    ListTile(
                                      title: SizedBox(
                                        height: 47,
                                        child: BlocListener<FindWordBloc, FindWordState>(
                                          listener: (context, wordState) {
                                            if (findWordController.text != wordState.word) {
                                              findWordController.text = wordState.word;
                                              findWordController.selection = TextSelection.collapsed(offset: wordState.word.length);
                                            }
                                          },
                                          child: TextField(
                                            controller: findWordController,
                                            onChanged: (word) {
                                              context.read<FindWordBloc>().add(FindWord(word: word));
                                            },
                                            cursorColor: Colors.grey,
                                            style: const TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                            decoration: const InputDecoration(
                                              hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                              hintText: "Find word",
                                              border: OutlineInputBorder(),
                                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0178b9)))
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    ListTile(
                                      trailing: InkWell(
                                        onTap: () async{
                                          if (findWordController.text.isNotEmpty) {
                                            final currentState = context.read<FindWordBloc>().state;
                                            await codeEditor.filePath.writeAsString(codeEditor.code().replaceAll(
                                              currentState.word, replaceWordController.text));
                                            if(context.mounted) {
                                              context.read<FindWordBloc>().add(FindWord(word: ""));
                                            }
                                          }
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xff0e639c),
                                            borderRadius: BorderRadius.all(Radius.circular(25))
                                          ),
                                          height: 45,
                                          width: 45,
                                          child: const Icon(Icons.find_replace_sharp,color: Colors.white)),
                                      ),
                                      title: SizedBox(
                                        height: 47,
                                        child: TextField(
                                          controller: replaceWordController,
                                          cursorColor: Colors.grey,
                                          style: const TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                          decoration: const InputDecoration(
                                            hintStyle: TextStyle(color: Color.fromARGB(255, 189, 189, 189)),
                                            hintText: "Replace",
                                            border: OutlineInputBorder(),
                                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xff0178b9)))
                                          ),
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
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(5))
                                          )),
                                        backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                                        foregroundColor: WidgetStatePropertyAll(Colors.white),
                                        textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
                                      ),
                                      child: const Text("Initialize Repository")),
                                    const SizedBox(height: 13.5),
                                    Text(
                                      "You can directly publish this\nfolder to a GitHub repository.\nOnce published, you'll have\naccess to source control featured\npowered by Git and GitHub",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    const SizedBox(height: 13.5),
                                    SizedBox(
                                      width: 200,
                                      child: ElevatedButton(
                                        onPressed: (){},
                                        style: const ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(5))
                                            )),
                                          backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                                          textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))
                                        ),
                                        child:  const Row(
                                          children: [
                                            Icon(FontAwesomeIcons.github,color: Colors.white),
                                            SizedBox(width: 8),
                                            Text("Publish to Github"),
                                          ],
                                        )),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28,horizontal: 15),
                              child: BlocBuilder<ApiBloc, ApiState>(
                                builder: (context, webState) {
                                  Map<TextEditingController,TextEditingController> paramControllers = {
                                    for (int _ in Iterable.generate(webState.params.length + 1)) 
                                      TextEditingController() : TextEditingController()
                                  };
                                  Map<TextEditingController,TextEditingController> headerControllers = {
                                    for (int _ in Iterable.generate(webState.headers.length + 1)) 
                                      TextEditingController() : TextEditingController()
                                  };
                                  if(webState.params.isNotEmpty){
                                    for(int index = 0; index < webState.params.length; index++){
                                      paramControllers.keys.toList()[index].text = webState.params.keys.toList()[index];
                                      paramControllers.values.toList()[index].text = webState.params.values.toList()[index];
                                      params[webState.params.keys.toList()[index]] = webState.params.values.toList()[index];
                                    }
                                  }
                                  if(webState.headers.isNotEmpty){
                                    for(int index = 0; index < webState.headers.length; index++){
                                      headerControllers.keys.toList()[index].text = webState.headers.keys.toList()[index];
                                      headerControllers.values.toList()[index].text = webState.headers.values.toList()[index];
                                      headers[webState.headers.keys.toList()[index]] = webState.headers.values.toList()[index];
                                    }
                                  }
                                  apiUrlController.text = webState.url ?? "Enter URL";
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 15),
                                      const Text(
                                        "API TESTING",
                                        style: TextStyle(color: Colors.white,fontWeight: FontWeight.w300)
                                      ),
                                      const SizedBox(height: 15),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton(
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                          value: webState.method,
                                          dropdownColor: const Color(0xff2b2b2b),
                                          items: const [  
                                            DropdownMenuItem(
                                              value: "POST",
                                              child: Text("POST",style: TextStyle(color: Color(0xffe0790b)))),
                                            DropdownMenuItem(
                                              value: "GET",
                                              child: Text("GET",style: TextStyle(color: Color(0xff26cda3)))),
                                            DropdownMenuItem(
                                              value: "PUT",
                                              child: Text("PUT",style: TextStyle(color: Color(0xff097bed)))),
                                            DropdownMenuItem(
                                              value: "DELETE",
                                              child: Text("DELETE",style: TextStyle(color: Color(0xfff22814))))
                                          ],
                                          onChanged: (value) async{
                                            context.read<ApiBloc>().add(ApiEvent(method: value!));
                                          }),
                                      ),
                                      SizedBox(
                                        height: 50,
                                        width: 250,
                                        child: TextField(
                                          controller: apiUrlController,
                                          keyboardType: TextInputType.url,
                                          style: const TextStyle(color: Colors.grey),
                                          cursorColor: Colors.grey,
                                          decoration: const InputDecoration(
                                            hintText: "Enter Url",
                                            border: OutlineInputBorder(),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Color(0xff0e639c))
                                            )
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TabBar(
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                                        controller: paramTabController,
                                        dividerColor: const Color.fromARGB(255, 61, 61, 61),
                                        dividerHeight: 1.5,
                                        unselectedLabelColor: Colors.grey,
                                        labelColor: const Color.fromARGB(255, 62, 142, 195),
                                        indicatorColor: const Color(0xff0e639c),
                                        indicatorWeight: 2.5,
                                        tabs: const[
                                        Tab(text: "Params"),
                                        Tab(text: "Headers"),
                                        Tab(text: "Body")
                                      ]),
                                      const SizedBox(height: 15),
                                      SizedBox(
                                        height: 60 * (((){
                                            if(webState.params.isEmpty && webState.headers.isEmpty){
                                              return 1.0;
                                            }
                                            if(webState.params.length > webState.headers.length){
                                              return webState.params.length.toDouble() + 1.0;
                                            }
                                            return webState.headers.length.toDouble() + 1.0;
                                          })()),
                                        child: TabBarView(
                                          controller: paramTabController,
                                          children:  [
                                            Column(
                                              children: List.generate(
                                                webState.params.length + 1,
                                                (index) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 5),
                                                    child: Row(children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: TextField(
                                                        cursorColor: Colors.grey,
                                                        style: const TextStyle(color: Colors.grey),
                                                        controller: paramControllers.keys.toList()[index],
                                                        textAlignVertical: TextAlignVertical.top,
                                                        decoration: const InputDecoration(
                                                          contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: Color(0xff0e639c))
                                                          ),
                                                          border: OutlineInputBorder()
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      flex: 5,
                                                      child: TextField(
                                                        cursorColor: Colors.grey,
                                                        style: const TextStyle(color: Colors.grey),
                                                        controller: paramControllers.values.toList()[index],
                                                        textAlignVertical: TextAlignVertical.top,
                                                        decoration: const InputDecoration(
                                                          contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: Color(0xff0e639c))
                                                          ),
                                                          border: OutlineInputBorder()
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(onPressed: (){
                                                      if(index == webState.params.length){
                                                        if(paramControllers.keys.toList()[index].text.isNotEmpty && paramControllers.values.toList()[index].text.isNotEmpty) {
                                                          params.addEntries({paramControllers.keys.toList()[index].text:paramControllers.values.toList()[index].text}.entries);
                                                        }
                                                      }
                                                      else{
                                                        params.remove(paramControllers.keys.toList()[index].text);
                                                      }
                                                      context.read<ApiBloc>().add(GetParams(params: params));
                                                    }, icon: Icon(index == webState.params.length? Icons.add : Icons.remove,color: Colors.grey))
                                                    ]),
                                                  );
                                                })),
                                            Column(
                                              children: List.generate(
                                                webState.headers.length + 1,
                                                (index) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 5),
                                                    child: Row(children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: TextField(
                                                        cursorColor: Colors.grey,
                                                        style: const TextStyle(color: Colors.grey),
                                                        controller: headerControllers.keys.toList()[index],
                                                        textAlignVertical: TextAlignVertical.top,
                                                        decoration: const InputDecoration(
                                                          contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: Color(0xff0e639c))
                                                          ),
                                                          border: OutlineInputBorder()
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      flex: 5,
                                                      child: TextField(
                                                        cursorColor: Colors.grey,
                                                        style: const TextStyle(color: Colors.grey),
                                                        controller: headerControllers.values.toList()[index],
                                                        textAlignVertical: TextAlignVertical.top,
                                                        decoration: const InputDecoration(
                                                          contentPadding: EdgeInsets.symmetric(vertical: 0,horizontal: 8.5),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: Color(0xff0e639c))
                                                          ),
                                                          border: OutlineInputBorder()
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(onPressed: (){
                                                      if(index == webState.headers.length){
                                                        if(headerControllers.keys.toList()[index].text.isNotEmpty && headerControllers.values.toList()[index].text.isNotEmpty) {
                                                          headers.addEntries({headerControllers.keys.toList()[index].text:headerControllers.values.toList()[index].text}.entries);
                                                        }
                                                      }
                                                      else{
                                                        headers.remove(headerControllers.keys.toList()[index].text);
                                                      }
                                                      context.read<ApiBloc>().add(GetHeaders(headers: headers));
                                                    }, icon: Icon(index == webState.headers.length? Icons.add : Icons.remove,color: Colors.grey))
                                                    ]),
                                                  );
                                                })),
                                            const Padding(
                                              padding: EdgeInsets.only(bottom: 7),
                                              child: TextField(
                                                textAlignVertical: TextAlignVertical.top,
                                                cursorColor: Colors.grey,
                                                style: TextStyle(color: Colors.grey),
                                                maxLines: null,
                                                minLines: null,
                                                decoration: InputDecoration(
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: Color(0xff0e639c))
                                                  ),
                                                  border: OutlineInputBorder()
                                                ),
                                                expands: true,
                                              ),
                                            )
                                          ]
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () async{
                                            Map<String,dynamic> data = 
                                              await sendRequest(
                                                url: apiUrlController.text,
                                                method: webState.method,
                                                headers: webState.headers
                                              );
                                            if(context.mounted) {
                                              context.read<ApiBloc>().add(GotApiData(data: data,url: apiUrlController.text));
                                            }
                                          }, 
                                            style: const ButtonStyle(
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))),
                                            backgroundColor: WidgetStatePropertyAll(Color(0xff0e639c)),
                                            foregroundColor: WidgetStatePropertyAll(Colors.white),
                                            textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.bold))),
                                          child: const Text("Send")),
                                      ),
                                      webState.data == null 
                                        ? const SizedBox.shrink()
                                        : Align(
                                          alignment: Alignment.bottomCenter,
                                          child: TabBar(
                                            controller: apiTabController,
                                            dividerColor: const Color.fromARGB(255, 61, 61, 61),
                                            dividerHeight: 1.5,
                                            unselectedLabelColor: Colors.grey,
                                            labelColor: const Color.fromARGB(255, 62, 142, 195),
                                            indicatorColor: const Color(0xff0e639c),
                                            indicatorWeight: 2.5,
                                            tabs: const [
                                              Tab(child: Text("{ }",style: TextStyle(fontSize: 22))), 
                                              Tab(icon: Icon(FontAwesomeIcons.html5)),
                                              Tab(icon: Icon(Icons.raw_on_sharp,size: 35))
                                            ]),
                                        ),
                                      const SizedBox(height: 20),
                                      webState.data == null 
                                        ? const SizedBox.shrink()
                                        : Expanded(
                                          child: TabBarView(
                                            controller: apiTabController,
                                            children: [
                                              JsonWidget(
                                                expandIcon: const Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),
                                                collapseIcon: const Icon(Icons.keyboard_arrow_right_sharp, color: Colors.grey),
                                                json: webState.data!
                                              ),
                                              InAppWebView(
                                                onWebViewCreated: (InAppWebViewController webViewController) {
                                                  webViewController.loadData(data: webState.data!['body']);
                                                },
                                              ),
                                              SingleChildScrollView(child: 
                                                Text(webState.data!.toString(),style: const TextStyle(color: Colors.grey)))
                                            ]
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 45),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 20),
                                    child: Text("SETTINGS",style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white)),
                                  ),
                                  const SizedBox(height: 15),
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
                                  }, 'Themes',
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
                                }, "Font", const Icon(FontAwesomeIcons.font,color: Colors.grey,size: 21))
                              ],
                              ),
                            )
                          ],
                        )
                      )
                    ],
                  ),
                );
              },
            ),
            appBar: AppBar(
              title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                      widget.filePath == null
                        ? (widget.languageDetails.extension=='html'
                            ? "index.html"
                            :widget.languageDetails.extension=='css'
                              ?'style.css'
                              :widget.languageDetails.extension=='js'
                                ?'script.js'
                                :"tempCode.${widget.languageDetails.extension}")
                        : path.basename(widget.filePath!.path),
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
                              key: createFileKey,
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
                                      createFileKey.currentState!.validate();
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
                      if(path.extension(target!.path)=='.html'){
                        if(context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                          builder: (context)=>WebView(
                            dirPath: widget.filePath==null?Directory('/sdcard/VSdroid/Temps/'):widget.filePath!.parent)));
                        }
                      }
                      else{
                        final server = await startServer();
                        bool stats = false;
                        if (server != null) {
                          try {
                            if (context.mounted) {
                              stats = await NativeChannel.sendCommand(widget.languageDetails, target.path, context);
                            }
                          }
                          catch(e){
                            await startTermuxActivity();
                            if(context.mounted) {
                              stats = await NativeChannel.sendCommand(widget.languageDetails, target.path, context);
                            }
                          }
                          final terminal = SetupTerminal(projectDir:widget.filePath==null?"/storage/emulated/0/VSdroid/Temps":widget.filePath!.parent.path,server: server);
                          if(context.mounted && stats){
                            Navigator.of(context).push(MaterialPageRoute(builder: (context)=>terminal));
                          }
                        }
                        else{
                          if(context.mounted) {
                            showDialog(context: context,builder: (context) => AlertDialog(
                              backgroundColor: const Color.fromARGB(255, 49, 49, 49),
                              title: const Text("Failed to Connect",style: TextStyle(color: Colors.white)),
                              content: const Text("Failed to connect with Termux",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white)),
                              icon: const Icon(Icons.error_outline_sharp),
                              iconColor: Colors.red[700],
                            ));
                          }
                        }
                      }
          
                    },
                    icon: const Icon(Icons.play_arrow)),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SetupTerminal(
                        projectDir: widget.filePath==null?"/storage/emulated/0/VSdroid/Temps":widget.filePath!.parent.path
                      )));
                  },
                  icon: const Icon(Icons.terminal, color: Color(0xff717171)))
              ],
            ),
            body: InteractiveViewer(
              transformationController: trasnformationController,
              minScale: 0.1,
            child: codeEditor)
                    );
      },
     );
  }
}
