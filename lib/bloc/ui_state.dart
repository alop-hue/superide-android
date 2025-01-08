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

class ApiState{
  final String method;
  final String? url;
  final Map<String,dynamic>? data;
  final Map<String,String> params, headers, body;
  const ApiState({required this.method, this.data, this.url, required this.params, required this.headers, required this.body});
  ApiState copyWith({
    String? method,
    String? url,
    Map<String,dynamic>? data,
    Map<String,String>? params,
    Map<String,String>? headers,
    Map<String,String>? body
  }){
    return ApiState(
      method: method ?? this.method,
      url: url ?? this.url,
      data: data ?? this.data,
      params: params ?? this.params,
      headers: headers ?? this.headers,
      body: body ?? this.body
    );
  }
}