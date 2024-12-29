import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc/ui_bloc.dart';
import 'package:vsdroid/ui/start_screen.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await getSavedTheme();
  runApp(MainApp(savedTheme: savedTheme));
}

class MainApp extends StatelessWidget {
  final String savedTheme;
  const MainApp({super.key,required this.savedTheme});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UiBloc(initialTheme: savedTheme),
      child: MaterialApp(
          theme: ThemeData(
              popupMenuTheme: popupBtnTheme,
              scaffoldBackgroundColor: const Color(0xff181818),
              appBarTheme: appBarDark,
              listTileTheme: tileTheme,
              cardTheme: cardTheme),
          home: const StartScreen()),
    );
  }
}
