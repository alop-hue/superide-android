import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/ui/start_screen.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await getSavedTheme();
  final savedFont = await getSavedFont();
  final recent = await getRecent();
  runApp(
    MainApp(
      savedTheme: savedTheme,
      savedFont: savedFont,
      recent: recent
    )
  );
}

class MainApp extends StatelessWidget {
  final String savedTheme,savedFont,recent;
  const MainApp({super.key, required this.savedTheme,required this.savedFont, required this.recent});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StackBloc()),
        BlocProvider(create: (_) => ThemeBloc(initialTheme: savedTheme,fontFamily: savedFont)),
        BlocProvider(create: (_) => MenuSearchBloc()),
        BlocProvider(create: (_) => FindWordBloc()),
        BlocProvider(create: (_) => WebViewBloc()),
        BlocProvider(create: (_) => FolderBloc()),
        BlocProvider(create: (_) => ApiBloc()),
        BlocProvider(create: (_) => RecentBloc(recent: jsonDecode(recent)))
      ],
      child: MaterialApp(
          theme: ThemeData(
            progressIndicatorTheme: progressTheme,
            popupMenuTheme: popupBtnTheme,
            scaffoldBackgroundColor: const Color(0xff181818),
            appBarTheme: appBarDark,
            listTileTheme: tileTheme,
            cardTheme: cardTheme),
          home: const StartScreen()),
    );
  }
}
