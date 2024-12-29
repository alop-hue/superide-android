part of 'ui_bloc.dart';

class UiEvent {}

class StackIndexChange extends UiEvent {
  final int stackValue;
  StackIndexChange({required this.stackValue});
}

class SetTheme extends UiEvent {
  final String theme;
  SetTheme({required this.theme});
}
