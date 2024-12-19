import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:highlight/highlight.dart';
import 'package:vsdroid/Termux/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/ui/themes.dart';

class HomeScreen extends StatelessWidget {
  final Mode language;
  final String helloWorld;
  const HomeScreen({super.key, required this.language,required this.helloWorld});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xff181818),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                drawerButtons(() {}, Icons.file_copy_outlined),
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
            const IndexedStack(
              children: [],
            )
          ],
        ),
      ),
      appBar: AppBar(
        actions: [
          appBarButtons(() {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => SetupTerminal()));
          }, Icons.terminal),
          appBarButtons(() {}, Icons.play_arrow),
        ],
      ),
      body: CodeEditor(
        language: language,
        helloWorld: helloWorld,
        theme: highlightThemes['atom-one-dark'],
      ),
    );
  }
}

Widget appBarButtons(VoidCallback onPressed, IconData icon,
    {Color color = const Color(0xff717171)}) {
  return IconButton(onPressed: onPressed, icon: Icon(icon, color: color));
}

Widget drawerButtons(VoidCallback onPressed, dynamic icon,
    {Color color = const Color(0xff6d6d6d)}) {
  if (icon.runtimeType == IconData) {
    return IconButton(
        onPressed: onPressed, icon: Icon(icon, color: color, size: 38));
  }
  return IconButton(onPressed: onPressed, icon: icon);
}
