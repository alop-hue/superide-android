part of 'ui_bloc.dart';

class StackState {
  final int stackIndex;
  const StackState({required this.stackIndex});
}

class ThemeState {
  final String theme;
  final String fontFamily;
  const ThemeState({required this.theme,required this.fontFamily});
  ThemeState copyWith({String? theme, String? fontFamily}){
    return ThemeState(theme: theme ?? this.theme, fontFamily: fontFamily ?? this.fontFamily);
  }
}

class MenuSearchState {
  final List<Card> searchedLangs;
  const MenuSearchState({required this.searchedLangs});
}

class FindWordState {
  final String word;
  const FindWordState({required this.word});
}

class WebViewState{
  final bool isMobile;
  final bool isConsole;
  const WebViewState({required this.isMobile,required this.isConsole});
  WebViewState copyWith({bool? isMobile,bool? isConsole}){
    return WebViewState(isMobile: isMobile ?? this.isMobile, isConsole: isConsole ?? this.isConsole);
  } 
}