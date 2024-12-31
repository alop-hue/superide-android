import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});
   
  @override
  Widget build(BuildContext context) {
    final ThemeBloc uiBloc = BlocProvider.of<ThemeBloc>(context);
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
                          leading: e==currentTheme?const Icon(Icons.radio_button_checked_sharp,color:Color(0xff39a2f2)):const Icon(Icons.radio_button_off_sharp),
                          onTap: () async{
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('selectedTheme', e);
                            if (context.mounted) {
                              context.read<ThemeBloc>().add(SetTheme(theme: e));
                              Navigator.of(context).pop();
                            }
                          },
                          title: Text(e.capitalize())),
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
                          title: Text(e.capitalize())
                          ))).toList()
                      ),
                    ),
                  )));
              }),
            ));
          }, "Font Style", const Icon(FontAwesomeIcons.font,color: Colors.grey,size: 21))
        ],
      ),
    );
  }
}

