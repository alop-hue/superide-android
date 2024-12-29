import 'dart:io';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc/ui_bloc.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';

class CodeEditor extends StatelessWidget {
  final Language language;
  final Map<String, TextStyle>? theme;
  late final CodeController codeController;
  final bool isTemplate;
  final String? file;
  final File? filePath;
  CodeEditor(
      {super.key,
      required this.language,
      this.theme,
      required this.isTemplate,
      this.file,
      this.filePath}) {
    //
  }

  Future<String?> checkTempFile() async {
    final tempFile = File("/sdcard/VSdroid/Temps/tempCode.${language.extension}");
    if (tempFile.existsSync()) {
      String source = await tempFile.readAsString();
      if (source.isNotEmpty) {
        return source;
      } else {
        return language.helloWorld;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return isTemplate
        ? FutureBuilder(
            future: checkTempFile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              codeController = CodeController(language: language.language,text: snapshot.data ?? language.helloWorld);
              return BlocBuilder<UiBloc, UiState>(
                builder: (context, state) {
                  return CodeTheme(
                    data: CodeThemeData(styles: highlightThemes[state.theme]),
                    child: CodeField(
                      textStyle: const TextStyle(fontFamily: 'monospace',fontSize: 10),
                      smartQuotesType: SmartQuotesType.enabled,
                      textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xff23a9f2),selectionColor: Color.fromARGB(112, 30, 134, 245)),
                      controller: codeController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                    ),
                  );
                },
              );
            })
        : FutureBuilder(
          future: (() async {
            return filePath!.readAsString();
          })(), builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            codeController = CodeController(language: language.language,text: snapshot.hasData? snapshot.data: "Can't read file content");
            return BlocBuilder<UiBloc, UiState>(
              builder: (context, state) {
                return CodeTheme(
                  data: CodeThemeData(styles: highlightThemes[state.theme]),
                  child: CodeField(
                    textStyle: const TextStyle(fontFamily: 'monospace',fontSize: 10),
                    smartQuotesType: SmartQuotesType.enabled,
                    textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xff23a9f2),selectionColor: Color.fromARGB(112, 30, 134, 245)),
                    controller: codeController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                  ),
                );
              },
            );
          });
  }

  String code() {
    return codeController.text;
  }
}
