import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vsdroid/Terminal/terminal.dart';
import 'package:vsdroid/ui/editor.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:vsdroid/utils/functions.dart';

class HomeScreen extends StatelessWidget {
  final Language language;
  const HomeScreen({super.key, required this.language});
  static const platform = MethodChannel("com.vsdroid");

  @override
  Widget build(BuildContext context) {
    final codeEditor =
        CodeEditor(language: language, theme: highlightThemes['atom-one-dark']);
    return FutureBuilder(
      future: setTempFile(language.extension),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          const Center(child: CircularProgressIndicator());
        }
        final target = snapshot.data;
        return Scaffold(
          drawer: Drawer(
            backgroundColor: const Color(0xff181818),
            child: Row(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 25),
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
                  onPressed: () async {
                    await target!.writeAsString(codeEditor.code());
                    if (context.mounted) {
                      await NativeChannel.sendCommand(language, target.path, context);
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
          body: codeEditor,
        );
      },
    );
  }
}
