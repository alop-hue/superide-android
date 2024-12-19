import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vsdroid/Terminal/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/ui/languages.dart';
import 'package:vsdroid/ui/themes.dart';
import 'package:vsdroid/utils/functions.dart';

class HomeScreen extends StatelessWidget {
  final Language language;
  const HomeScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: setTempFile(language.extension),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          const Center(child: CircularProgressIndicator());
        }
        final target = snapshot.data;
        final codeEditor = CodeEditor(language: language, theme: highlightThemes['atom-one-dark']);
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
              IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SetupTerminal()));
                  },
                  icon: const Icon(Icons.terminal, color: Color(0xff717171))),
              IconButton(
                  onPressed: () async {
                    await target!.writeAsString(codeEditor.code());
                  },
                  icon: const Icon(Icons.play_arrow))
            ],
          ),
          body: codeEditor,
        );
      },
    );
  }
}
