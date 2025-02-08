part of 'ui_bloc.dart';

@immutable
sealed class UiEvent {}

class StackIndexChange extends UiEvent {
  final int stackValue;
  StackIndexChange({required this.stackValue});
}

class SetTheme extends UiEvent {
  final String theme;
  SetTheme({required this.theme});
}

class Search extends UiEvent {
  final List<Card> searchedLangs;
  Search({required this.searchedLangs});
}

class SetFont extends UiEvent {
  final String font;
  SetFont({required this.font});
}

class FindWord extends UiEvent {
  final String word;
  FindWord({required this.word});
}

class SetViewPort extends UiEvent{
  final bool isMobile;
  SetViewPort({required this.isMobile});
}

class EnableConsole extends UiEvent{
  final bool isConsole;
  EnableConsole({required this.isConsole});
}

class ApiEvent extends UiEvent{
  final String method;
  ApiEvent({required this.method});
}

class GetParams extends UiEvent{
  final Map<String,String> params;
  GetParams({required this.params});
}

class GetHeaders extends UiEvent{
  final Map<String,String> headers;
  GetHeaders({required this.headers});
}

class GetBody extends UiEvent{
  final Map<String,String> body;
  GetBody({required this.body});
}

class GetUrl extends UiEvent{
  final String url;
  GetUrl({required this.url});
}

class GotApiData extends UiEvent{
  final Map<String,dynamic> data;
  GotApiData({required this.data});
}

class FileTreeEvent extends UiEvent{
  final Map<String, bool> folderStates;
  FileTreeEvent({required this.folderStates});
}