import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:vsdroid/ui/languages.dart';

class CodeEditor extends StatelessWidget {
  final Language language;
  final Map<String, TextStyle> theme;
  late final CodeController codeController;
  CodeEditor({super.key, required this.language, required this.theme}) {
    codeController =
        CodeController(language: language.language, text: language.helloWorld);
  }

  @override
  Widget build(BuildContext context) {
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
  }

  String code() {
    return codeController.text;
  }
}
