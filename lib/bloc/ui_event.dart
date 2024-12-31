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
