import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import '../bloc/ui_bloc.dart';
import '../ui/editor_page.dart';
import '../utils/functions.dart';
import '../utils/languages.dart';
import '../utils/themes.dart';
import '../utils/widgets.dart';

class FolderPage extends StatelessWidget {
  final Directory dir;
  const FolderPage({required this.dir,super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.read<AppThemeBloc>().state.appTheme;
    final gitRepo = searchForRepo(dir.path, dir.path);
    final isRepoThere = gitRepo != "No git repo found.";
    return  Scaffold(
      appBar: AppBar(
        title: Text(path.basename(dir.path),style: const TextStyle(color: Colors.grey)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("Open a file to Edit",style: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 20)),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Text(
                    isRepoThere 
                      ? "Version control (.git) found \u2713"
                      : "No version control (.git) found on this folder/project",
                      style: TextStyle(color: Colors.grey[appTheme.isDark ? 500 : 600]),
                  ),
                  Card(
                    child: Wrap(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
                          child: Text(
                            "Note: This is a clone of the selected folder in VSDroid's private directory. Modifications here will not affect the original folder.",
                            style: TextStyle(color: Colors.grey[appTheme.isDark ? 500 : 600]),
                          ),
                        )
                      ]
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: DirectoryTreeViewerCustom(
                appTheme: appTheme,
                isUnfoldedFirst: false,
                rootPath: dir.path,
                enableCreateFileOption: true,
                enableCreateFolderOption: true,
                enableDeleteFileOption: true,
                enableDeleteFolderOption: true,
                enableRenameFileOption: true,
                enableRenameFolderOption: true,
                editingFieldStyle: EditingFieldStyle(
                  textStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  cursorColor: Colors.grey,
                  cursorHeight: 18,
                  verticalTextAlign: TextAlignVertical.top,
                  textfieldDecoration: const InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      borderSide: BorderSide(color: Colors.grey)
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      borderSide: BorderSide(color: Colors.grey)
                    ),
                  ),
                  folderIcon: const Icon(Icons.folder, color: Colors.grey,size: 25),
                  fileIcon: const Icon(Icons.edit_document, color: Colors.grey,size: 25),
                  doneIcon: const Icon(Icons.check, color: Colors.grey,size: 25),
                  cancelIcon: const Icon(Icons.close, color: Colors.grey,size: 25),
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
                  folderClosedicon: SvgPicture.asset('assets/icons/folder.svg',height: 34,width: 34),
                  folderOpenedicon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 34,width: 34),
                  iconForCreateFolder: const Icon(Icons.create_new_folder,color: Colors.grey),
                  iconForCreateFile: const Icon(FontAwesomeIcons.fileCirclePlus, size: 20,color: Colors.grey),
                  rootFolderClosedIcon: SvgPicture.asset('assets/icons/folder.svg',height: 34,width: 34),
                  rootFolderOpenedIcon: SvgPicture.asset('assets/icons/open-file-folder.svg',height: 34,width: 34),
                  folderNameStyle: TextStyle(color: appTheme.selectScreenCardTextColor,fontSize: 20),
                ),
                fileStyle: FileStyle(
                  iconForDeleteFile: Icon(Icons.delete, size: 25, color: Colors.red[300]),
                  fileNameStyle: TextStyle(
                    color: appTheme.selectScreenCardTextColor,
                    fontSize: 20,
                    fontWeight: appTheme.isDark ? FontWeight.w400 : FontWeight.w500,
                    height: 2,
                  ),
                ),
                onFileTap: (f) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => EditorPage(languageDetails: (() =>languages.firstWhere(
                      (language) =>language.extension.contains(path.extension(f.path).replaceFirst(".", "")),
                      orElse: () =>languages[0]))(),filePath: f,rootDir: dir.path)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
