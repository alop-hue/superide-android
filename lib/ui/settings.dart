import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/bloc/ui_bloc/ui_bloc.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Settings extends StatelessWidget {
   const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    UiBloc uiBloc = BlocProvider.of<UiBloc>(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 45, 45, 45),
      appBar: AppBar(
        backgroundColor: const Color(0xff181818),
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          settingsTile(() {
            showDialog(context: context, builder: (context)=>
            BlocProvider<UiBloc>.value(
              value: uiBloc,
              child: BlocBuilder<UiBloc, UiState>(
                builder: (context, state) {
                  final String currentTheme = state.theme;
                  return SimpleDialog(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    insetPadding: const EdgeInsets.only(bottom: 120,top: 190,left: 25,right: 25),
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
                    children: highlightThemes.keys.toList().map((e)=>Card(
                      elevation: 0,
                      color: e==currentTheme?const Color.fromARGB(160, 82, 82, 82):Colors.transparent,
                      child: ListTile(
                        iconColor: Colors.grey,
                        leading: e==currentTheme?Icon(Icons.radio_button_checked_sharp,color: Colors.blue[700]):const Icon(Icons.radio_button_off_sharp),
                        onTap: () async{
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selectedTheme', e);
                          if (context.mounted) {
                            context.read<UiBloc>().add(SetTheme(theme: e));
                            Navigator.of(context).pop();
                          }
                        },
                        title: Text(e.capitalize())),
                    )).toList(),
                  );
                },
              ),
            )
            );
          }, 'Themes',
              const Icon(Icons.color_lens, size: 24, color: Colors.grey)),
          settingsTile(() {}, "Font Size",
              const Icon(Icons.font_download, color: Colors.grey))
        ],
      ),
    );
  }
}

Widget settingsTile(VoidCallback onPressed, String title, dynamic icon) {
  return Column(
    children: [
      ListTile(
        dense: true,
        onTap: onPressed,
        leading: icon,
        title: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
      ),
    ],
  );
}
