import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart';

class CodeEditor extends StatelessWidget {
  final Mode language;
  final Map<String, TextStyle> theme;
  final String helloWorld;
  late final CodeController _codeController;
  CodeEditor({super.key, required this.language, required this.theme,required this.helloWorld}) {
    _codeController = CodeController(language: language, text: helloWorld);
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
        controller: _codeController,
        expands: true,
        maxLines: null,
        minLines: null,
      ),
    );
  }
}
