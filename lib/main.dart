import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/ui/start_screen.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startTermuxActivity();
  final savedTheme = await getSavedTheme();
  final savedFont = await getSavedFont();
  runApp(MainApp(savedTheme: savedTheme,savedFont: savedFont));
}

class MainApp extends StatelessWidget {
  final String savedTheme,savedFont;
  const MainApp({super.key, required this.savedTheme,required this.savedFont});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => StackBloc()),
        BlocProvider(create: (context) => ThemeBloc(initialTheme: savedTheme,fontFamily: savedFont)),
        BlocProvider(create: (context) => MenuSearchBloc()),
        BlocProvider(create: (context) => FindWordBloc())
      ],
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
