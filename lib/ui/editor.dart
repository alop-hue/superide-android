import 'dart:io';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';

// ignore: must_be_immutable
class CodeEditor extends StatelessWidget {
  final Language language;
  final Map<String, TextStyle>? theme;
  late CodeController codeController;
  final String? file;
  final File filePath;
  final bool isTemplate;
  CodeEditor(
    {super.key,
    required this.language,
    this.theme,
    this.file,
    required this.filePath,
    this.isTemplate = false
    }) {/**/}

  Future<String?> getData() async {
    if (filePath.existsSync()) {
      String source = await filePath.readAsString();
      if (source.isNotEmpty) {
        return source;
      } else {
        if(isTemplate) {
          return language.helloWorld;
        }else{
          return 'Your canvas is ready.\nWrite something amazing!';
        }
      }
    }
    return language.helloWorld;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FindWordBloc, FindWordState>(
      builder: (context, wordState) {
        return FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            codeController = CodeController(
              language: language.language,
              text: snapshot.hasData? (snapshot.data??language.helloWorld) : "Can't read filecontent",
              patternMap: {
                if (wordState.word.isNotEmpty) RegExp.escape(wordState.word): TextStyle(backgroundColor: Colors.yellow[600]!)
              });
            return BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return CodeTheme(
                  data: CodeThemeData(styles: highlightThemes[state.theme]),
                  child: CodeField(
                    textStyle: TextStyle(fontFamily: state.fontFamily, fontSize: 10),
                    smartQuotesType: SmartQuotesType.enabled,
                    textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Color(0xff23a9f2),
                    selectionColor:Color.fromARGB(112, 30, 134, 245)),
                    controller: codeController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  String code() {
    return codeController.text;
  }
}
