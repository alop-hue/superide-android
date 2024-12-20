import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:vsdroid/utils/languages.dart';

class CodeEditor extends StatelessWidget {
  final Language language;
  final Map<String, TextStyle> theme;
  late final CodeController codeController;
  CodeEditor({super.key, required this.language, required this.theme}) {
    //
  }

  Future<String?> checkTempFile() async {
    final tempFile =
        File("/sdcard/VSdroid/Temps/tempCode.${language.extension}");
    if (tempFile.existsSync()) {
      String source = await tempFile.readAsString();
      return source;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: checkTempFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          codeController = CodeController(language: language.language, text:snapshot.data??language.helloWorld);
          return CodeTheme(
            data: CodeThemeData(styles: theme),
            child: CodeField(
              textStyle: const TextStyle(fontFamily: 'monospace'),
              smartQuotesType: SmartQuotesType.enabled,
              textSelectionTheme: const TextSelectionThemeData(
                  cursorColor: Color(0xff23a9f2),
                  selectionColor: Color.fromARGB(112, 30, 134, 245)),
              controller: codeController,
              expands: true,
              maxLines: null,
              minLines: null,
            ),
          );
        });
  }

  String code() {
    return codeController.text;
  }
}
