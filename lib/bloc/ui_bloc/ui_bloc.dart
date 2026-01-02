import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:code_forge/code_forge.dart';
import '../../utils/functions.dart';
import '../../utils/themes.dart';

part 'ui_event.dart';
part 'ui_state.dart';

class StackBloc extends Bloc<StackIndexChange, StackState> {
  StackBloc() : super(const StackState(stackIndex: 0)) {
    on<StackIndexChange>((event, emit)=>emit(StackState(stackIndex: event.stackValue)));
  }
}

class ThemeBloc extends Bloc<UiEvent, ThemeState>{
  final Map<String, dynamic> codeForgeConfig;
  ThemeBloc({
    required this.codeForgeConfig
  })
    :super(
      ThemeState(
        fontSize: 15,
        codeForgeConfig: codeForgeConfig
      )
    ){
    on<SetFontSize>((event, emit)=>emit(state.copyWith(fontSize: event.fontSize)));
    on<ChangeConfigEvent>((event, emit) => emit(state.copyWith(codeForgeConfig: event.codeForgeConfig)));
  }
}

class GeneralBloc extends Bloc<GeneralEvent, GeneralState> {
  final Map<String, dynamic> generalSettings;
  GeneralBloc(this.generalSettings) : super(GeneralState(generalSettings: generalSettings)) {
    on<GeneralEvent>((event, emit) => emit(GeneralState(generalSettings: event.generalSettings)));
  }
}

class MenuSearchBloc extends Bloc<Search, MenuSearchState>{
  MenuSearchBloc():super(const MenuSearchState(searchedLangs: <Card>[])){
    on<Search>((event, emit)=>emit(MenuSearchState(searchedLangs: event.searchedLangs)));
  }
}

class FindWordBloc extends Bloc<FindWord, FindWordState>{
  FindWordBloc():super(
    const FindWordState(
      word: '',
      matchCase: false,
      matchWholeWord: false,
      isRegex: false
    )
  ){
    on<FindWord>((event, emit)=>emit(
      FindWordState(
        word: event.word,
        matchCase: event.matchCase,
        matchWholeWord: event.matchWholeWord,
        isRegex: event.isRegex
      )
    ));
  }
}

class WebViewBloc extends Bloc<UiEvent, WebViewState>{
  WebViewBloc():super(const WebViewState(isMobile: true,isConsole: true)){
    on<SetViewPort>((event, emit)=>emit(state.copyWith(isMobile: event.isMobile)));
    on<EnableConsole>((event, emit)=>emit(state.copyWith(isConsole: event.isConsole)));
  }
}

class ApiBloc extends Bloc<RestEvent, ApiState>{
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

  void setAllFoldersExpanded(List<String> dirPaths, bool expanded) {
    final currentState = state.folderStates;
    final newStates = Map<String, bool>.from(currentState);
    for (final path in dirPaths) {
      newStates[path] = expanded;
    }
    emit(FolderState(newStates));
  }
}

class RecentBloc extends Bloc<RecentEvent, RecentState>{
  final List<dynamic> recent;
  RecentBloc({required this.recent}) : super(RecentState(recent: recent)){
    on<RecentEvent>((event, emit) => emit(RecentState(recent: event.recent)));
  }
}

class AppThemeBloc extends Bloc<AppThemeEvent, AppThemeState>{
  final AppTheme appTheme;
  AppThemeBloc({required this.appTheme}):super(AppThemeState(appTheme: appTheme)){
    on<AppThemeEvent>((event, emit) => emit(AppThemeState(appTheme: event.appTheme)));
  }
}

class ActiveEditorsBloc extends Bloc<ActiveEditorsEvent, ActiveEditorsState>{
  final ActiveEditors activeEditor;
  ActiveEditorsBloc(this.activeEditor):super(ActiveEditorsState([activeEditor])){
    on<ActiveEditorsEvent>((event, emit) => emit(ActiveEditorsState(event.activeEditors)));
  }
}

class AIBloc extends Bloc<AIEvent, AIState> {
  final Map<String, dynamic> config, modelSelected;
  final bool isEnabled, showSuggestionOntap;
  AIBloc(
      this.config,
      this.isEnabled,
      this.modelSelected,
      this.showSuggestionOntap
    ) : super(AIState(config, isEnabled, modelSelected, showSuggestionOntap)) {
    on<AIConfigEvent>((event, emit) => emit(state.copyWith(config: event.config)));
    on<AIEnableEvent>((event, emit) => emit(state.copyWith(isEnabled: event.isEnabled)));
    on<ModelSelectEvent>((event, emit) => emit(state.copyWith(modelSelected: event.modelSelected)));
    on<AIModeEvent>((event, emit) => emit(state.copyWith(showSuggestionOntap: event.showSuggestionOntap)));
  }
}

class DownloadProgressBloc extends Bloc<DownloadProgressEvent, DownloadProgressState>{
  DownloadProgressBloc():super(DownloadProgressState(null)){
    on<DownloadProgressEvent>((event, emit) => emit(DownloadProgressState(event.downloadProgress)));
  }
}

class AIChatBloc extends Bloc<AIChatEvent, AIChatState>{
  AIChatBloc():super(AIChatState([])){
    on<AIChatEvent>((event, emit) => emit(AIChatState(event.aiConversation)));
  }
}

class DownloadPortBloc extends Cubit<ReceivePort?> {
  static const String portName = 'downloader_send_port';
  late final Stream<dynamic> broadcastStream;

  DownloadPortBloc() : super(null) {
    final rp = ReceivePort();
    IsolateNameServer.registerPortWithName(rp.sendPort, portName);
    broadcastStream = rp.asBroadcastStream();
    emit(rp);
  }

  ReceivePort? get port => state;

  Stream<dynamic> get downloadStream => broadcastStream;

  @override
  Future<void> close() {
    if (state != null) {
      IsolateNameServer.removePortNameMapping(portName);
      state!.close();
    }
    return super.close();
  }
}

class GitCommitBloc extends Bloc<GitCommitEvent, GitCommitState>{
  GitCommitBloc(): super(GitCommitState(commitMessage: '')){
    on<GitCommitEvent>((event, emit) => emit(GitCommitState(commitMessage: event.commitMessage)));
  }
}

class DownloadManagerBloc extends Cubit<DownloadManagerState> {
  DownloadManagerBloc() : super(DownloadManagerState(
    downloadProgress: {}, 
    extractionProgress: {},
    extractingItems: {},
    fullyCompleted: {}
  ));

  void updateProgress(int index, double progress) {
    final newProgress = Map<int, double>.from(state.downloadProgress);
    newProgress[index] = progress;
    emit(state.copyWith(downloadProgress: newProgress));
  }

  void updateExtractionProgress(int index, double progress) {
    final newProgress = Map<int, double>.from(state.extractionProgress);
    newProgress[index] = progress;
    emit(state.copyWith(extractionProgress: newProgress));
  }

  void startExtracting(int index) {
    final newExtracting = Set<int>.from(state.extractingItems);
    newExtracting.add(index);
    emit(state.copyWith(extractingItems: newExtracting));
  }

  void markFullyCompleted(int index) {
    final newExtracting = Set<int>.from(state.extractingItems);
    final newFullyCompleted = Set<int>.from(state.fullyCompleted);
    newExtracting.remove(index);
    newFullyCompleted.add(index);
    emit(state.copyWith(
      extractingItems: newExtracting,
      fullyCompleted: newFullyCompleted
    ));
  }

  void removeDownload(int index) {
    final newProgress = Map<int, double>.from(state.downloadProgress);
    final newExtractionProgress = Map<int, double>.from(state.extractionProgress);
    final newExtracting = Set<int>.from(state.extractingItems);
    final newFullyCompleted = Set<int>.from(state.fullyCompleted);
    newProgress.remove(index);
    newExtractionProgress.remove(index);
    newExtracting.remove(index);
    newFullyCompleted.remove(index);
    emit(state.copyWith(
      downloadProgress: newProgress, 
      extractionProgress: newExtractionProgress,
      extractingItems: newExtracting,
      fullyCompleted: newFullyCompleted
    ));
  }

  void clearProgress(int index) {
    final newProgress = Map<int, double>.from(state.downloadProgress);
    final newExtractionProgress = Map<int, double>.from(state.extractionProgress);
    newProgress.remove(index);
    newExtractionProgress.remove(index);
    emit(state.copyWith(
      downloadProgress: newProgress,
      extractionProgress: newExtractionProgress
    ));
  }
}