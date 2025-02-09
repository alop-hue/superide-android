import 'dart:io';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/themes.dart';

class CodeEditor extends StatefulWidget {
  final Language language;
  final Map<String, TextStyle>? theme;
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

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late  CodeController codeController;
  double _initialFontSize = 10.0;
  double _currentScale = 1.0;

  Future<String?> getData() async {
    if (widget.filePath.existsSync()) {
      String source = await widget.filePath.readAsString();
      if (source.isNotEmpty) {
        return source;
      } else {
        if(widget.isTemplate) {
          return widget.language.helloWorld;
        }else{
          return 'Your canvas is ready.\nWrite something amazing!';
        }
      }
    }
    return widget.language.helloWorld;
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
              language: widget.language.language,
              text: snapshot.hasData? (snapshot.data??widget.language.helloWorld) : "Can't read filecontent",
              patternMap: {
                if (wordState.word.isNotEmpty) RegExp.escape(wordState.word): TextStyle(backgroundColor: Colors.yellow[600]!)
              });
            return BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return CodeTheme(
                  data: CodeThemeData(styles: highlightThemes[state.theme]),
                  child: GestureDetector(
                    onScaleStart: (details) {
                      if(details.pointerCount == 2){
                        _initialFontSize = state.fontSize;
                      }
                    },
                    onScaleUpdate: (details) {
                      if (details.pointerCount == 2) {
                        _currentScale = details.scale;
                        double newFontSize = _initialFontSize * _currentScale;
                        newFontSize = newFontSize.clamp(8.0, 48.0);
                        context.read<ThemeBloc>().add(SetFontSize(fontSize: newFontSize));
                      }
                    },
                    child: CodeField(
                      onChanged: (word) async{
                        await widget.filePath.writeAsString(word);
                      },
                      textStyle: TextStyle(fontFamily: state.fontFamily, fontSize: state.fontSize),
                      textSelectionTheme: const TextSelectionThemeData(
                      cursorColor: Color(0xff23a9f2),
                      selectionColor:Color.fromARGB(112, 30, 134, 245)),
                      controller: codeController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }
}
