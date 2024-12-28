import 'package:bloc/bloc.dart';

part 'ui_event.dart';
part 'ui_state.dart';

class UiBloc extends Bloc<UiEvent, UiState> {
  UiBloc() : super(const UiState(stackIndex: 0)) {
    on<StackIndexChange>((event, emit) {
      emit(UiState(stackIndex: event.stackValue));
    });
  }
}
