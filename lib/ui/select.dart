import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vsdroid/ui/menu_screen.dart';
import 'package:vsdroid/ui/settings.dart';
import 'package:vsdroid/utils/functions.dart';

class SelectType extends StatelessWidget {
  SelectType({super.key});

  final createFileController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 34, 34, 34),
        child: ListView(
          children: [
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
      appBar: AppBar(backgroundColor: Colors.transparent),
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
                builder: (context) => Dialog(
                      child: Card(
                        child: Column(
                          children: [
                            const Text("Create New File"),
                            const Icon(FontAwesomeIcons.fileCirclePlus),
                            TextField(
                              controller:createFileController,
                              decoration: const InputDecoration(
                              hintText: "Filename.extension",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(25))
                          )
                        ),
                      ),
                            Row(
                              children: [
                                ElevatedButton(onPressed: ()async{

                                }, child: const Text("OK"))
                              ],
                            )
                          ],
                        ),
                      ),
                    ));
          }, "New File...", const Icon(FontAwesomeIcons.fileCirclePlus)),
          fileTiles(
              () {}, "Open File...", const Icon(FontAwesomeIcons.fileImport)),
          fileTiles(
              () {}, "Open Folder...", const Icon(FontAwesomeIcons.folderOpen)),
          fileTiles(
              () {},
              val: 4,
              "Open Repository...",
              SvgPicture.asset(
                'assets/icons/code-branch-solid.svg',
                height: 28,
                width: 28,
                colorFilter:
                    const ColorFilter.mode(Color(0xff4783b7), BlendMode.srcIn),
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
                            Icon(FontAwesomeIcons.folderTree,
                                color: Color.fromARGB(255, 193, 193, 193)),
                            SizedBox(width: 12.5),
                            Text("New Project",
                                style: TextStyle(
                                    fontSize: 16.5,
                                    color: Color.fromARGB(255, 193, 193, 193))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const MenuScreen()));
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
                            Icon(FontAwesomeIcons.fileCode,
                                color: Color.fromARGB(255, 193, 193, 193)),
                            SizedBox(width: 5),
                            Text(
                              "Open Template",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 193, 193, 193),
                                  fontSize: 16.5),
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
