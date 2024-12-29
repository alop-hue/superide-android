import 'package:bloc/bloc.dart';

part 'ui_event.dart';
part 'ui_state.dart';

class UiBloc extends Bloc<UiEvent, UiState> {
  final String initialTheme;
  UiBloc({required this.initialTheme}) : super(UiState(stackIndex: 0,theme: initialTheme)) {
    on<StackIndexChange>((event, emit)=>emit(state.copyWith(stackIndex: event.stackValue)));
    on<SetTheme>((event, emit)=>emit(state.copyWith(theme: event.theme)));
  }
}


