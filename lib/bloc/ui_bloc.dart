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