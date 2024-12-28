part of 'ui_bloc.dart';

class UiEvent {}

class StackIndexChange extends UiEvent {
  final int stackValue;
  StackIndexChange({required this.stackValue});
}
