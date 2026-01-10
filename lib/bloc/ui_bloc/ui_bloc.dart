import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:code_forge/code_forge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/functions.dart';
import '../../utils/themes.dart';

part 'ui_event.dart';
part 'ui_state.dart';

class StackBloc extends Bloc<StackIndexChange, StackState> {
  StackBloc() : super(const StackState(stackIndex: 0)) {
    on<StackIndexChange>((event, emit)=>emit(StackState(stackIndex: event.stackValue)));
  }
}

class ConfigBloc extends Bloc<UiEvent, ConfigState>{
  final Map<String, dynamic> codeForgeConfig;
  ConfigBloc({
    required this.codeForgeConfig
  })
    :super(
      ConfigState(
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

class ChatSessionBloc extends Bloc<ChatSessionEvent, ChatSessionState> {
  static const String _storageKey = 'chat_sessions';

  ChatSessionBloc() : super(ChatSessionState(sessions: [])) {
    on<LoadChatSessions>(_onLoadSessions);
    on<CreateNewSession>(_onCreateNewSession);
    on<SelectSession>(_onSelectSession);
    on<UpdateCurrentSession>(_onUpdateCurrentSession);
    on<DeleteSession>(_onDeleteSession);
    on<UpdateSessionTitle>(_onUpdateSessionTitle);
  }

  Future<void> _onLoadSessions(LoadChatSessions event, Emitter<ChatSessionState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_storageKey);
      if (sessionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        final sessions = decoded.map((s) => ChatSession.fromJson(s)).toList();
        // Sort by createdAt descending (newest first)
        sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(state.copyWith(sessions: sessions, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onCreateNewSession(CreateNewSession event, Emitter<ChatSessionState> emit) async {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      conversations: [],
    );
    final updatedSessions = [newSession, ...state.sessions];
    emit(state.copyWith(sessions: updatedSessions, currentSession: newSession));
    await _saveSessions(updatedSessions);
  }

  Future<void> _onSelectSession(SelectSession event, Emitter<ChatSessionState> emit) async {
    final session = state.sessions.firstWhere((s) => s.id == event.sessionId);
    emit(state.copyWith(currentSession: session));
  }

  Future<void> _onUpdateCurrentSession(UpdateCurrentSession event, Emitter<ChatSessionState> emit) async {
    if (state.currentSession == null) {
      // Create new session if none exists
      final newSession = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title ?? 'New Chat',
        createdAt: DateTime.now(),
        conversations: event.conversations,
      );
      final updatedSessions = [newSession, ...state.sessions];
      emit(state.copyWith(sessions: updatedSessions, currentSession: newSession));
      await _saveSessions(updatedSessions);
      return;
    }

    final updatedSession = state.currentSession!.copyWith(
      conversations: event.conversations,
      title: event.title,
    );
    final updatedSessions = state.sessions.map((s) {
      if (s.id == updatedSession.id) return updatedSession;
      return s;
    }).toList();
    emit(state.copyWith(sessions: updatedSessions, currentSession: updatedSession));
    await _saveSessions(updatedSessions);
  }

  Future<void> _onDeleteSession(DeleteSession event, Emitter<ChatSessionState> emit) async {
    final updatedSessions = state.sessions.where((s) => s.id != event.sessionId).toList();
    final shouldClearCurrent = state.currentSession?.id == event.sessionId;
    emit(state.copyWith(
      sessions: updatedSessions,
      clearCurrentSession: shouldClearCurrent,
    ));
    await _saveSessions(updatedSessions);
  }

  Future<void> _onUpdateSessionTitle(UpdateSessionTitle event, Emitter<ChatSessionState> emit) async {
    final updatedSessions = state.sessions.map((s) {
      if (s.id == event.sessionId) {
        return s.copyWith(title: event.title);
      }
      return s;
    }).toList();
    
    ChatSession? updatedCurrentSession;
    if (state.currentSession?.id == event.sessionId) {
      updatedCurrentSession = state.currentSession!.copyWith(title: event.title);
    }
    
    emit(state.copyWith(
      sessions: updatedSessions,
      currentSession: updatedCurrentSession ?? state.currentSession,
    ));
    await _saveSessions(updatedSessions);
  }

  Future<void> _saveSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, json);
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

class WorkspaceSearchBloc extends Bloc<WorkspaceSearchEvent, WorkspaceSearchState> {
  WorkspaceSearchBloc() : super(WorkspaceSearchState.initial()) {
    on<UpdateSearchResults>((event, emit) => emit(state.copyWith(
      results: event.results,
      query: event.query,
      isSearching: false,
    )));
    on<SetSearching>((event, emit) => emit(state.copyWith(isSearching: event.isSearching)));
    on<UpdateSearchOptions>((event, emit) => emit(state.copyWith(
      matchCase: event.matchCase,
      matchWholeWord: event.matchWholeWord,
      isRegex: event.isRegex,
    )));
    on<ClearSearchResults>((event, emit) => emit(WorkspaceSearchState.initial()));
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