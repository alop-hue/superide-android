import 'dart:io';
import 'package:file_icon/file_icon.dart';
import 'package:file_tree_view/file_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vsdroid/ui/home.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:path/path.dart' as path;

class FolderPage extends StatelessWidget {
  final Directory dir;
  const FolderPage({required this.dir,super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text(path.basename(dir.path),style: const TextStyle(color: Colors.grey)),
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 34, 34, 34),
        child: Padding(
          padding: const EdgeInsets.only(top: 50,left: 20),
          child: DirectoryTreeViewer(
            rootPath: dir.path,
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
      body: const Center(
        child: Column(
          children: [
            SizedBox(height: 15),
            Text("Open a file to Edit",style: TextStyle(color: Colors.grey,fontSize: 20)),
            Expanded(child: SizedBox()),
            Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text("No version control (.git) found on this folder/project",style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}
