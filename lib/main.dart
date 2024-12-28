import 'package:flutter/material.dart';
import 'package:vsdroid/ui/start_screen.dart';
import 'package:vsdroid/utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          popupMenuTheme: popupBtnTheme,
          scaffoldBackgroundColor: const Color(0xff181818),
          appBarTheme: appBarDark,
          listTileTheme: tileTheme,
          cardTheme: cardTheme),
        home: const StartScreen());
  }
}
