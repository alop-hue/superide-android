import 'dart:convert';
import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_json/flutter_json.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'webview.dart';
import '../bloc/ui_bloc.dart';
import '../terminal/terminal.dart';
import '../utils/languages.dart';
import '../utils/functions.dart';
import '../utils/themes.dart';
import '../utils/widgets.dart';

class EditorPage extends StatefulWidget {
  final Language languageDetails;
  final String rootDir;
  final File? filePath;
  const EditorPage({super.key, required this.languageDetails, this.filePath, required this.rootDir});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with TickerProviderStateMixin {
  final createFileKey = GlobalKey<FormState>();
  final trasnformationController = TransformationController();
  late final TextEditingController createFileController, findWordController;
  late final TextEditingController replaceWordController, apiUrlController;
  late final TabController apiTabController, paramTabController;
  late List<int> mruOrder;
  Map<String,String> params = {}, headers = {};
  TabController? tabController;

  @override 
  void initState(){
    mruOrder = [0];
    createFileController = TextEditingController();
    findWordController = TextEditingController();
    replaceWordController = TextEditingController();
    apiUrlController = TextEditingController();
    trasnformationController.value = Matrix4.identity()..scale(1.45);
    apiTabController =  TabController(length: 3, vsync: this);
    paramTabController = TabController(length: 3, vsync: this);
    
    super.initState();
  }

  @override
  void dispose() {
    apiUrlController.dispose();
    apiTabController.dispose();
    paramTabController.dispose();
    findWordController.dispose();
    trasnformationController.dispose();
    tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int tabCount) {
    if (tabController == null || tabController!.length != tabCount) {
      tabController?.dispose();
      tabController = TabController(length: tabCount, vsync: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTheme appTheme = context.read<AppThemeBloc>().state.appTheme;
    final ThemeBloc uiBloc = BlocProvider.of<ThemeBloc>(context);
        return FutureBuilder(
      future: Future.wait([
        widget.filePath == null
        ? setTempFile(widget.languageDetails.extension[0])
        : Future.value(widget.filePath),
        (() async {
          final prefs = await SharedPreferences.getInstance();
          List<dynamic> storedData = jsonDecode(await getRecent());
          final File file = widget.filePath ?? await setTempFile(widget.languageDetails.extension[0]);
          final dataToInsert = {file.path: widget.rootDir};
          final Set<String> uniquePaths = {};
          storedData.insert(0, dataToInsert);
          final List<dynamic> uniqueData = [];
          for (final data in storedData) {
            final path = data.keys.toList()[0];
            if (!uniquePaths.contains(path)) {
              uniquePaths.add(path);
              uniqueData.add(data);
            }
          }
          if (uniqueData.length > 3) {
            uniqueData.removeRange(3, uniqueData.length);
          }
          if (context.mounted) {
            context.read<RecentBloc>().add(RecentEvent(recent: uniqueData));
          }
          prefs.setString('recent', jsonEncode(uniqueData));
      })(),
      startLspServer(
        ext: widget.languageDetails.extension[0],
        executable: widget.languageDetails.lspExecutable,
        args: widget.languageDetails.args ?? [],
        workspacePath: widget.rootDir,
        langId: widget.languageDetails.name
      )
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final initialController = CodeForgeController(
          lspConfig: snapshot.data?[2] as LspConfig?
        );
        final initalUndoController = UndoRedoController();
        final target = snapshot.data![0] as File;
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => StackBloc()),
            BlocProvider(create: (_) => FindWordBloc()),
            BlocProvider(create: (_) => ApiBloc()),
            BlocProvider(create: (_) => FolderBloc()),
            BlocProvider(create: (_) => AIChatBloc()),
            BlocProvider(create: (_) => ActiveEditorsBloc(
              ActiveEditors(
                filePath: target,
                controller: initialController,
                languageDetails: widget.languageDetails,
                undoRedoController: initalUndoController,
                isActive: true,
              )
            )),
          ],
          child: BlocBuilder<ActiveEditorsBloc, ActiveEditorsState>(
            buildWhen: (previous, current) => previous.activeEditors.length != current.activeEditors.length,
            builder: (context, editorState) {
              _updateTabController(editorState.activeEditors.length);
              return Scaffold(
                resizeToAvoidBottomInset: true,
                drawer: BlocBuilder<StackBloc, StackState>(
                  buildWhen: (previous, current) => current != previous,
                  builder: (context, state) { 
                    return Drawer(
                      width: 350,
                      backgroundColor: appTheme.editorPageDrawerBg,
                      child: Row(
                        children: [
                          Container(
                            color: appTheme.editorPageToolbarBg,
                            child: Column(
                              children: [
                                const SizedBox(height: 25),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 0)), 
                                  Icons.file_copy_outlined,
                                  color: state.stackIndex == 0 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 0 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                  ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 1)),
                                  Icons.search,
                                  color: state.stackIndex == 1 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 1 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 2)),
                                  FontAwesomeIcons.codeBranch,
                                  color: state.stackIndex == 2 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 2 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 3)),
                                  SvgPicture.asset(
                                    'assets/icons/rest-api-icon.svg',
                                    height: 34,
                                    width: 34,
                                    colorFilter: ColorFilter.mode(
                                      state.stackIndex == 3 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor, BlendMode.srcIn),
                                  ),
                                  bgColor: state.stackIndex == 3 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 4)),
                                  SvgPicture.asset(
                                    'assets/icons/ai.svg',
                                    height: 34,
                                    width: 34,
                                  ),
                                  bgColor: state.stackIndex == 4 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 5)
                                ),
                                drawerButtons(
                                  () => context.read<StackBloc>().add(StackIndexChange(stackValue: 5)),
                                  Icons.settings,
                                  color: state.stackIndex == 5 ?appTheme.editorPageToolSelectedColor:appTheme.editorPageToolColor,
                                  bgColor: state.stackIndex == 5 ? appTheme.editorPageToolSelectedBgColor:Colors.transparent
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: IndexedStack(
                              index: state.stackIndex,
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: ListView(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 15),
                                            child: Text(
                                              "EXPLORER",
                                              style: TextStyle(
                                                fontWeight: appTheme.isDark? FontWeight.w300 : FontWeight.w500,
                                                color: appTheme.selectScreenCardTextColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          child: DirectoryTreeViewerCustom(
                                            isUnfoldedFirst: false,
                                            rootPath: widget.rootDir,
                                            enableCreateFileOption: true,
                                            enableCreateFolderOption: true,
                                            editingFieldStyle: EditingFieldStyle(
                                              textFieldWidth: MediaQuery.of(context).size.width,
                                              textStyle: const TextStyle(color: Colors.grey,),
                                              cursorColor: Colors.grey,
                                              cursorHeight: 19,
                                              verticalTextAlign: TextAlignVertical.top,
                                              textfieldDecoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 1.0),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                                  borderSide: BorderSide(color: Colors.grey)
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                                  borderSide: BorderSide(color: Colors.grey)
                                                ),
                                              ),
                                              folderIcon: const Icon(Icons.folder, color: Colors.grey,size: 20),
                                              fileIcon: const Icon(Icons.edit_document, color: Colors.grey,size: 20),
                                              doneIcon: const Icon(Icons.check, color: Colors.grey,size: 20),
                                              cancelIcon: const Icon(Icons.close, color: Colors.grey,size: 20),
                                            ),
                                            fileIconBuilder: (ext) {
                                              return SizedBox(
                                                height: 25,
                                                width: 25,
                                                child:languages.firstWhere(
                                                  (lang)=>lang.extension.contains(ext.replaceFirst(".", "")),
                                                  orElse: () => languages[0],
                                                ).icon??FileIcon(ext)
                                              );
                                            },
                                            folderStyle: FolderStyle(
                                              iconForCreateFolder: Icon(
                                                Icons.create_new_folder,
                                                color: appTheme.isDark? Colors.grey : const Color(0xff2b2b2b),
                                              ),
                                              iconForCreateFile: Icon(
                                                FontAwesomeIcons.fileCirclePlus,
                                                size: 20,
                                                color: appTheme.isDark? Colors.grey : const Color(0xff2b2b2b),
                                              ),
                                              rootFolderClosedIcon: const Icon(Icons.chevron_right_sharp,color: Colors.grey),
                                              rootFolderOpenedIcon: const Icon(Icons.keyboard_arrow_down_sharp,color: Colors.grey),
                                              folderClosedicon: SvgPicture.asset('assets/icons/folder.svg',height: 30,width: 30),
                                              folderOpenedicon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 30,width: 30),
                                              folderNameStyle: TextStyle(
                                                color: appTheme.selectScreenCardTextColor,
                                                fontSize: 20,
                                                fontWeight: appTheme.isDark ? FontWeight.w400 : FontWeight.w500,
                                              ),
                                            ),
                                            fileStyle: FileStyle(
                                              fileNameStyle: TextStyle(
                                                color: appTheme.selectScreenCardTextColor,
                                                fontSize: 20,
                                                fontWeight: appTheme.isDark ? FontWeight.w400 : FontWeight.w500,
                                                height: 2,
                                              ),
                                            ),
                                            onFileTap: (f) async{
                                              final List<ActiveEditors> currentState = List.from(editorState.activeEditors);
                                              for(ActiveEditors item in currentState){
                                                item.isActive = false;
                                              }
                                              final lang = languages.firstWhere(
                                                (language) =>language.extension.contains(path.extension(f.path).replaceFirst(".", "")),
                                                orElse: () =>languages[0]
                                              );
                                              final lspConfig = await startLspServer(
                                                ext: lang.extension[0],
                                                executable: lang.lspExecutable,
                                                args: lang.args ?? [],
                                                workspacePath: f.parent.path,
                                                langId: lang.name
                                              );
                                              currentState.add(
                                                ActiveEditors(
                                                  controller: CodeForgeController(
                                                    lspConfig: lspConfig
                                                  ),
                                                  undoRedoController: UndoRedoController(),
                                                  filePath: f,
                                                  isActive: true,
                                                  languageDetails: lang
                                                )
                                              );
                                              mruOrder.insert(0, currentState.length - 1);
                                              if(context.mounted) {
                                                context.read<ActiveEditorsBloc>().add(ActiveEditorsEvent(currentState));
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  final newIndex = currentState.indexWhere((item) => item.isActive == true);
                                                  if (tabController != null && tabController!.length > newIndex && newIndex >= 0) {
                                                    tabController!.animateTo(newIndex);
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                FindWordWidget(
                                  appTheme: appTheme,
                                  findWordController: findWordController,
                                  editorState: editorState,
                                  replaceWordController: replaceWordController,
                                  tabController: tabController
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 25,left: 10),
                                  child: SizedBox(
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Text("SOURCE CONTROL",
                                            style: TextStyle(
                                              fontWeight: appTheme.isDark? FontWeight.w300 : FontWeight.w500,
                                              color: appTheme.selectScreenCardTextColor,
                                            ),
                                          )
                                        ),
                                        const SizedBox(height: 13.5),
                                        Text(
                                          "The folder currently open\ndosen't hava a Git repository.\nYou can initialize a repository\nwhich will enable source control\nfeatures powered by Git.",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(color: appTheme.isDark ?Colors.grey[400] : appTheme.selectScreenCardTextColor),
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
                                          style: TextStyle(color: appTheme.isDark ?Colors.grey[400] : appTheme.selectScreenCardTextColor),
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
                                          Text(
                                            "API TESTING",
                                            style: TextStyle(
                                              color: appTheme.selectScreenCardTextColor,
                                              fontWeight: appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                                            )
                                          ),
                                          const SizedBox(height: 15),
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton(
                                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                                              value: webState.method,
                                              dropdownColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 241, 241, 241),
                                              items: [  
                                                DropdownMenuItem(
                                                  value: "POST",
                                                  child: Text(
                                                    "POST",
                                                    style: TextStyle(
                                                      color: const Color(0xffe0790b),
                                                      fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "GET",
                                                  child: Text(
                                                    "GET",
                                                    style: TextStyle(
                                                      color: const Color(0xff26cda3),
                                                      fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "PUT",
                                                  child: Text(
                                                    "PUT",
                                                    style: TextStyle(
                                                      color: const Color(0xff097bed),
                                                      fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: "DELETE",
                                                  child: Text(
                                                    "DELETE",
                                                    style: TextStyle(
                                                      color: const Color(0xfff22814),
                                                      fontWeight: appTheme.isDark ? FontWeight.w500 : FontWeight.w600
                                                    ),
                                                  ),
                                                ),
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
                                              onChanged: (val){
                                                context.read<ApiBloc>().add(GetUrl(url: val));
                                              },
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
                                            dividerColor: appTheme.isDark? 
                                                const Color.fromARGB(255, 61, 61, 61) :
                                                const Color.fromARGB(255, 182, 182, 182),
                                            dividerHeight: 1.5,
                                            unselectedLabelColor: appTheme.isDark ? 
                                                Colors.grey : 
                                                const Color.fromARGB(255, 102, 102, 102),
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
                                                            style: TextStyle(color: appTheme.selectScreenCardTextColor),
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
                                                            style: TextStyle(color: appTheme.selectScreenCardTextColor),
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
                                                        IconButton(
                                                          onPressed: () {
                                                            if (index == webState.params.length) {
                                                              if (paramControllers.keys.toList()[index].text.isNotEmpty &&
                                                                  paramControllers.values.toList()[index].text.isNotEmpty) {
                                                                params.addEntries({
                                                                  paramControllers.keys.toList()[index].text:
                                                                      paramControllers.values.toList()[index].text
                                                                }.entries);
                                                              }
                                                            } else {
                                                              params.remove(paramControllers.keys.toList()[index].text);
                                                            }
                                                            context.read<ApiBloc>().add(GetParams(params: params));
                                                            String baseUrl = apiUrlController.text.split('?')[0];
                                                            String queryString = '';
                                                            if (params.isNotEmpty) {
                                                              queryString = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
                                                            }
                                                            String newUrl = queryString.isNotEmpty ? '$baseUrl?$queryString' : baseUrl;
                                                            apiUrlController.value = apiUrlController.value.copyWith(
                                                              text: newUrl,
                                                              selection: TextSelection.collapsed(offset: newUrl.length),
                                                            );
                                                            context.read<ApiBloc>().add(GetUrl(url: newUrl));
                                                          },
                                                          icon: Icon(
                                                            index == webState.params.length ? Icons.add : Icons.remove,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
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
                                                  context.read<ApiBloc>().add(GotApiData(data: data));
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
                                AIChat(filePath: editorState.activeEditors.isNotEmpty
                                  ? editorState.activeEditors[(tabController != null ? tabController!.index : editorState.activeEditors.indexWhere((item) => item.isActive == true))].filePath.path
                                  : ''),
                                Padding(
                                  padding: const EdgeInsets.only(top: 45),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Text(
                                          "SETTINGS",
                                          style: TextStyle(
                                            fontWeight: appTheme.isDark ? FontWeight.w300 : FontWeight.w500,
                                            color: appTheme.selectScreenCardTextColor
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      settingsTile(() {
                                        showDialog(context: context, builder: (context)=>
                                        BlocProvider<ThemeBloc>.value(
                                          value: uiBloc,
                                          child: BlocBuilder<ThemeBloc, ThemeState>(
                                            builder: (context, themeState) {
                                              final String currentTheme = themeState.codeForgeConfig['theme'];
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
                                                              leading: e==currentTheme? const Icon(Icons.radio_button_checked_sharp,color: Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
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
                                        Icon(
                                          Icons.color_lens, 
                                          size: 24,
                                          color: appTheme.isDark ? Colors.grey : const Color.fromARGB(255, 100, 100, 100)
                                        ), appTheme.isDark
                                      ),
                                      settingsTile((){
                                      showDialog(context: context, builder: (context)=>
                                      BlocProvider<ThemeBloc>.value(
                                        value: uiBloc,
                                        child: BlocBuilder<ThemeBloc,ThemeState>(
                                          builder: (context, themeState){
                                            final String currentFont = themeState.codeForgeConfig['fontFamily'];
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
                                                            title: Text(e.capitalize(), style: TextStyle(color: appTheme.selectScreenCardTextColor))
                                                          )
                                                        )
                                                      ).toList()
                                                    ),
                                                  ),
                                                )
                                              )
                                            );  
                                          }
                                        ),
                                      ));
                                    }, "Fonts", Icon(
                                      FontAwesomeIcons.font,
                                      color: appTheme.isDark ? Colors.grey : const Color.fromARGB(255, 100, 100, 100),
                                      size: 21
                                    ),appTheme.isDark
                                  )
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
                      child: tabController == null
                        ? Text(
                            editorState.activeEditors.isNotEmpty
                              ? path.basename(editorState.activeEditors[0].filePath.path)
                              : '',
                            style: TextStyle(color: appTheme.selectScreenCardTextColor)
                          )
                        : AnimatedBuilder(
                            animation: tabController!,
                            builder: (context, _) {
                              int idx = tabController!.index;
                              if (idx < 0 || idx >= editorState.activeEditors.length) idx = 0;
                              final fileName = editorState.activeEditors.isNotEmpty
                                ? path.basename(editorState.activeEditors[idx].filePath.path)
                                : '';
                              return Text(fileName, style: TextStyle(color: appTheme.selectScreenCardTextColor));
                            },
                          )
                    ),
                  bottom: TabBar(
                    labelPadding: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    indicator: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0xff157dcc),
                          width: 2
                        ),
                        left: BorderSide(
                          color: appTheme.isDark? Colors.grey : Colors.blueGrey[600]!,
                          width: 0.2
                        ),
                        right: BorderSide(
                          color: appTheme.isDark? Colors.grey : Colors.blueGrey[600]!,
                          width: 0.2
                        ),
                      )
                    ),
                    labelColor: appTheme.selectScreenCardTextColor,
                    unselectedLabelColor: appTheme.isDark ? null : Colors.grey[400],
                    dividerColor: Colors.transparent,
                    controller: tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    onTap: (value) {
                      mruOrder.remove(value);
                      mruOrder.insert(0, value);
                      if (tabController != null && tabController!.index != value) {
                        tabController!.animateTo(value);
                      }
                    },
                    tabs: List.generate(editorState.activeEditors.length, (index){
                      return Tab(
                        height: 32,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                path.basename(editorState.activeEditors[index].filePath.path),
                                softWrap: false,
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final List<ActiveEditors> currentState = List.from(editorState.activeEditors);
                                if(currentState.length <= 1){
                                  Navigator.of(context).pop();
                                  return;
                                }
                                final wasActive = currentState[index].isActive;
                                currentState.removeAt(index);
                                mruOrder.remove(index);
                                mruOrder = mruOrder.map((i) => i > index ? i - 1 : i).toList();
                                if (currentState.isNotEmpty && wasActive) {
                                  int newActive = mruOrder.isNotEmpty ? mruOrder[0] : 0;
                                  for (int i = 0; i < currentState.length; i++) {
                                    currentState[i].isActive = i == newActive;
                                  }
                                }
                                context.read<ActiveEditorsBloc>().add(ActiveEditorsEvent(currentState));
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final newIndex = currentState.indexWhere((item) => item.isActive == true);
                                  if (tabController != null && newIndex >= 0 && newIndex < tabController!.length) {
                                    tabController!.animateTo(newIndex);
                                  }
                                });
                              }, 
                              icon: Icon(Icons.close, size: 20)
                            )
                          ]
                        ),
                      );
                    })
                  ),
                  actions: [
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: TextButton(onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                icon: const Icon(FontAwesomeIcons.fileCirclePlus),
                                iconColor: Colors.grey,
                                backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
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
                                            final file = await createFile(
                                              createFileController.text, 
                                              widget.rootDir,
                                              context
                                            ); 
                                            if (context.mounted && file != null) {
                                              /* Navigator.of(context).push(MaterialPageRoute(
                                                builder: (context) => EditorPage(
                                                  rootDir: widget.rootDir ?? file.parent.path,
                                                  filePath: file,
                                                  languageDetails: languages
                                                  .firstWhere((language) => 
                                                    language.extension == path.extension(file.path).replaceFirst(".", ""))
                                                  )
                                                )
                                              ); */
                                            }
                                          }
                                        },
                                        child: const Text("OK")
                                      )
                                    ],
                                  ));
                                  }, child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: Icon(
                                          FontAwesomeIcons.fileCirclePlus,
                                          color: appTheme.selectScreenCardTextColor,
                                          size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Text("New",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                    ],
                                  ))),
                              PopupMenuItem(
                                child: TextButton(onPressed: () async{
                                  if (context.mounted) {
                                    final file = await pickFiles(context, appTheme.isDark);
                                    if (file != null) {
                                    } else {
                                      if(context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Failed to open file",
                                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
                                            backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
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
                                        }, child: Row(
                                          children: [
                                            Icon(FontAwesomeIcons.fileImport,color: appTheme.selectScreenCardTextColor,size: 20),
                                            const SizedBox(width: 10),
                                            Text("Open",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                          ],
                                        ),
                                      ),
                              ),
                                PopupMenuItem(
                                  child: TextButton(onPressed: () async{
                                    if(context.mounted){
                                      final activeEditorForSave = tabController != null
                                          ? editorState.activeEditors[tabController!.index]
                                          : editorState.activeEditors.firstWhere((item) => item.isActive == true);
                                      final savedPlace = await selectDir(
                                        dialogeTitle: "Save file as...",
                                        initialDirectory: widget.rootDir,
                                        bytes: activeEditorForSave.filePath.readAsBytesSync()
                                      );
                                      if((savedPlace == null || savedPlace.isEmpty) && context.mounted){
                                        showDialog(context: context, builder: (context)=> AlertDialog(
                                          title: const Text("Failed to save file",
                                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300)),
                                          backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
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
                                          ),
                                        );
                                      }
                                    }
                                  }, child: Row(
                                    children: [
                                      const SizedBox(width: 5.5),
                                      Icon(FontAwesomeIcons.filePen, color: appTheme.selectScreenCardTextColor,size: 20),
                                      const SizedBox(width: 7),
                                      Text("SaveAs",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                    ],
                                  ),
                                )
                              ),
                              PopupMenuItem(
                                  child: TextButton(onPressed: () {
                                    showDialog(context: context, builder: (context)=>AlertDialog(
                                      title:  Text("Are you sure ?",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
                                      content: const Text("       The code will be cleared",style: TextStyle(color: Colors.grey)),
                                      backgroundColor: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
                                      icon: const Icon(Icons.error_outline,size: 35),
                                      iconColor: Colors.red[600],
                                      actionsAlignment: MainAxisAlignment.center,
                                        actions: [
                                          ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStatePropertyAll(Colors.red[600])
                                            ),
                                            onPressed: (){
                                              Navigator.of(context).pop();
                                            }, child: const Text("Cancel",style: TextStyle(color: Colors.white))),
                                          ElevatedButton(
                                            onPressed: () {
                                              final activeEditorForClear = tabController != null
                                                  ? editorState.activeEditors[tabController!.index]
                                                  : editorState.activeEditors.firstWhere((item) => item.isActive == true);
                                              activeEditorForClear.filePath.writeAsString('');
                                              Navigator.of(context).pop();
                                              setState(() {});
                                            },
                                            child: const Text("OK"))
                                        ],
                                    ));
                                  }, child: Row(
                                    children: [
                                      Icon(Icons.clear_sharp,color: appTheme.selectScreenCardTextColor,size: 25),
                                      const SizedBox(width: 7),
                                      Text("Clear",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 17)),
                                    ],
                                  ),
                                ),
                              )
                            ]),
                      IconButton(
                        onPressed: () async {
                          final Directory tempDir = Directory('/data/data/com.vsdroid/temps');
                            if(!tempDir.existsSync()){
                              tempDir.createSync(recursive: true);
                            }
                            final activeEditorForRun = tabController != null
                              ? editorState.activeEditors[tabController!.index]
                              : editorState.activeEditors.firstWhere((item) => item.isActive == true);
                            final File filePath = activeEditorForRun.filePath;
                          final String extention = path.extension(filePath.path);
                          switch (extention) {
                            case '.html':
                              if (context.mounted) {
                                Navigator.of(context).push(PageRouteBuilder(
                                  pageBuilder: (context, animation, scondaryAnimation) => WebViewScreen(htmlFile: filePath),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SizeTransition(sizeFactor: animation, child: child);
                                  },
                                ));
                              }
                              break;
                            case '.c':
                              final String compileCommand = "clang -fPIC -shared ${filePath.path} -o  ${tempDir.path}/libtemp.so";
                              final String runCommand = 'clangloader ${tempDir.path}/libtemp.so';
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.cpp':
                            case '.c++':
                            case '.cc':
                              final String compileCommand = "clang++ -fPIC -shared ${filePath.path} -o  ${tempDir.path}/libtemp.so";
                              final String runCommand = 'clangloader ${tempDir.path}/libtemp.so';
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.java':
                              final String compileCommand = "javac ${filePath.path} -d ${tempDir.path}";
                              final String runCommand = "cd ${tempDir.path} && java ${path.basenameWithoutExtension(filePath.path)}";
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.kt':
                              final String compileCommand = 'echo "Compiling..." && kotlinc ${filePath.path} -d ${tempDir.path}';
                              final String runCommand = "cd ${tempDir.path} && java ${path.basenameWithoutExtension(filePath.path)}";
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            case '.ts':
                              final String compileCommand = "tsc ${filePath.path} --outDir ${tempDir.path}";
                              final String runCommand = "node ${tempDir.path}/${path.basenameWithoutExtension(filePath.path)}.js";
                              runCode(context, compileCommand, runCommand, widget.rootDir);
                              break;
                            default:
                              final String command = languages.firstWhere((language) =>
                                language.extension.contains(path.extension(filePath.path).replaceFirst(".", "")),
                              ).command ?? '';
                              Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (context, animation, scondaryAnimation) =>
                                  SetupTerminal(
                                    projectDir: widget.rootDir,
                                    args: ["-c", "$command ${filePath.path}"]
                                  ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SizeTransition(sizeFactor: animation, child: child);
                                },
                              )
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow)),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (context, animation, scondaryAnimation) =>
                                SetupTerminal(
                                  projectDir: widget.rootDir,
                                ),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SizeTransition(sizeFactor: animation, child: child);
                              },
                            )
                          );
                          /* Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SetupTerminal(
                              projectDir: editorState.activeEditors.isNotEmpty
                                ? editorState.activeEditors[(tabController != null ? tabController!.index : editorState.activeEditors.indexWhere((item) => item.isActive == true))].filePath.parent.path
                                : widget.rootDir
                            ))); */
                        },
                        icon: const Icon(Icons.terminal))
                  ],
                ),
                body: TabBarView(
                  controller: tabController,
                  children: editorState.activeEditors.map((editor)=> EditorArea(
                    key: ValueKey(editor.filePath.path),
                    editor: editor,
                    appTheme: appTheme
                  )).toList()
                )
              );
            },
          ),
        );
      },
    );
  }
}