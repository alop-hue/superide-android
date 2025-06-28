import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/ui/start_screen.dart';
import 'package:vsdroid/utils/functions.dart';
import 'package:vsdroid/utils/themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recent = await getRecent();
  final appTheme = await getAppTheme();
  final codeCrafterConfig = await getCodeCrafterConfig();
  final aiConfig = await getAiConfig();
  runApp(MainApp(
    recent: recent,
    appTheme: appTheme,
    codeCrafterConfig: codeCrafterConfig,
    aiConfig: aiConfig,
  ));
}

class MainApp extends StatelessWidget {
  final String recent, appTheme, codeCrafterConfig;
  final String aiConfig;
  const MainApp({
      super.key,
      required this.recent,
      required this.appTheme,
      required this.codeCrafterConfig,
      required this.aiConfig
    });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc(
          codeCrafterConfig: jsonDecode(codeCrafterConfig)
        )),
        BlocProvider(create: (_) => RecentBloc(recent: jsonDecode(recent))),
        BlocProvider(create: (_) => AppThemeBloc(appTheme: themeMap[appTheme]!)),
        BlocProvider(create: (_) => WebViewBloc()),
        BlocProvider(create: (_) => MenuSearchBloc()),
        BlocProvider(create: (_) => AIBloc(
          jsonDecode(aiConfig),
        )),
      ],
      child: BlocBuilder<AppThemeBloc, AppThemeState>(
        builder: (context, appThemeState) {
          return MaterialApp(
              theme: ThemeData(
                progressIndicatorTheme: progressTheme,
                popupMenuTheme: appThemeState.appTheme.popupBtnTheme,
                scaffoldBackgroundColor: appThemeState.appTheme.scaffoldBg,
                appBarTheme: appThemeState.appTheme.appBarTheme,
                listTileTheme: appThemeState.appTheme.tileTheme,
                cardTheme: appThemeState.appTheme.cardTheme.data
              ),
              home: const StartScreen());
        },
      ),
    );
  }
}
