import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vsdroid/ui/folder_page.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/widgets.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectNameController = TextEditingController();
    return Scaffold(
      body: FutureBuilder(
        future: setupProjectDir(),
        builder: (context,snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError){
            return AlertDialog(
              title:  Text("Permission denied",style: TextStyle(color: Colors.grey[400],fontSize: 20)),
              backgroundColor: const Color(0xff2b2b2b),
              icon: const Icon(Icons.error_outline,size: 35),
              iconColor: Colors.red[600],
              actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text("OK"))
                ],
            );
          }
          return Column(
            children: [
              const SizedBox(height: 75),
              projectTile(
                "New Project",
                "Create a new custom project with version control (Git)",
                const Icon(Icons.folder_special_rounded,color: Color(0xffffc928),size: 28),
                (){
                  showDialog(context: context, builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xff2b2b2b),
                    title: const Text("New Project",style: TextStyle(color: Colors.grey)),
                    icon: const Icon(Icons.folder_special_rounded,size: 28),
                    iconColor: const Color(0xffffc928),
                    content: TextField(
                      controller: projectNameController,
                      cursorColor: Colors.grey,
                      style: const TextStyle(color: Colors.grey),
                      decoration: const InputDecoration(
                        hintText: "Project name",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff5090c8)),
                          borderRadius: BorderRadius.all(Radius.circular(25))
                        )
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red[600])),
                          onPressed: (){
                            Navigator.of(context).pop();
                          },
                          child: const Text("Cancel",style: TextStyle(color: Colors.white)))
                      ),
                      SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          onPressed: () async{
                            final actualProjectDir = Directory("/storage/emulated/0/VSdroid/Projects/${projectNameController.text}");
                            if(!actualProjectDir.existsSync()){
                              await actualProjectDir.create(recursive: true);
                            }
                            if(context.mounted){
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context ,animation, secondaryAnimation) => FolderPage(dir: actualProjectDir),
                                  transitionsBuilder: (context ,animation, secondaryAnimation, child){
                                    return SizeTransition(sizeFactor: animation,child: child);
                                  }
                                )
                              );
                            }
                          },
                          child: const Text("OK"))
                      )
                    ],
                  ));
                }
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 15),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text("Project templates",style: TextStyle(color: Colors.white,fontSize: 20))),
              ),
              const SizedBox(height: 20),
              projectTile(
                "Web",
                "Simple web project with an HTML, CSS and a JavaScript file",
                SvgPicture.asset("assets/material_icons/web.svg",width: 30,height: 30),
                (){}
              ),
              projectTile(
                "Android",
                "An android project with neccessary files",
                SvgPicture.asset("assets/material_icons/folder-android-open.svg",width: 30,height: 30),
                (){}
              ),
              projectTile(
                "React",
                "Create a react app",
                SvgPicture.asset("assets/material_icons/folder-react-components-open.svg",width: 30,height: 30),
                (){}
              ),
            ],
          );
        }
      ),
    );
  }
}