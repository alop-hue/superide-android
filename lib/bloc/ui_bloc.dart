import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'ui_event.dart';
part 'ui_state.dart';

class StackBloc extends Bloc<UiEvent, StackState> {
  StackBloc() : super(const StackState(stackIndex: 0)) {
    on<StackIndexChange>((event, emit)=>emit(StackState(stackIndex: event.stackValue)));
  }
}

class ThemeBloc extends Bloc<UiEvent, ThemeState>{
  final String initialTheme,fontFamily;
  ThemeBloc({required this.initialTheme,required this.fontFamily}):super(ThemeState(theme: initialTheme,fontFamily: fontFamily)){
    on<SetTheme>((event, emit)=>emit(state.copyWith(theme: event.theme)));
    on<SetFont>((event, emit)=>emit(state.copyWith(fontFamily: event.font)));

  }
}

class MenuSearchBloc extends Bloc<UiEvent, MenuSearchState>{
  MenuSearchBloc():super(const MenuSearchState(searchedLangs: <Card>[])){
    on<Search>((event, emit)=>emit(MenuSearchState(searchedLangs: event.searchedLangs)));
  }
}

class FindWordBloc extends Bloc<UiEvent, FindWordState>{
  FindWordBloc():super(const FindWordState(word: '')){
    on<FindWord>((event, emit)=>emit(FindWordState(word: event.word)));
  }
}

class WebViewBloc extends Bloc<UiEvent, WebViewState>{
  WebViewBloc():super(const WebViewState(isMobile: true,isConsole: true)){
    on<SetViewPort>((event, emit)=>emit(state.copyWith(isMobile: event.isMobile)));
    on<EnableConsole>((event, emit)=>emit(state.copyWith(isConsole: event.isConsole)));
  }
}

class ApiBloc extends Bloc<UiEvent, ApiState>{
  ApiBloc():super(const ApiState(method: "GET",data: null, url: null, params: {}, headers: {}, body: {})){
    on<ApiEvent>((event, emit)=>emit(state.copyWith(method: event.method)));
    on<GetParams>((event, emit)=>emit(state.copyWith(params: event.params)));
    on<GetHeaders>((event, emit)=>emit(state.copyWith(headers: event.headers)));
    on<GetBody>((event, emit)=>emit(state.copyWith(body: event.body)));
    on<GetUrl>((event, emit)=>emit(state.copyWith(url: event.url)));
    on<GotApiData>((event, emit)=>emit(state.copyWith(data: event.data)));
  }
}

class FolderBloc extends Cubit<FolderState> {
  FolderBloc() : super(FolderState({}));

  void toggleFolder(String dirPath) {
    final currentState = state.folderStates;
    final isUnfolded = currentState[dirPath] ?? false;
    emit(state.copyWith(folderStates: {...currentState, dirPath: !isUnfolded}));
  }
}