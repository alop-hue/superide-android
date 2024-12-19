import 'package:flutter/material.dart';
import 'package:vsdroid/ui/menu_screen.dart';
import 'package:vsdroid/ui/themes.dart';

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
            scaffoldBackgroundColor: const Color(0xff181818),
            appBarTheme: appBarDark,
            listTileTheme: tileTheme,
            cardTheme: cardTheme),
        home: const MenuScreen());
  }
}
