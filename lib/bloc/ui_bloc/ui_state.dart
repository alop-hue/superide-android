part of 'ui_bloc.dart';

class UiState {
  final int stackIndex;
  final String theme;
  const UiState({required this.stackIndex, required this.theme});
  UiState copyWith({int? stackIndex, String? theme}) {
    return UiState(
        stackIndex: stackIndex ?? this.stackIndex,
        theme: theme ?? this.theme
    );
  }
}
