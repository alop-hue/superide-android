import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsdroid/utils/constants.dart';
import '../../utils/ai.dart';
import '../../utils/copilot_chat.dart';
import '../../utils/copilot_lsp.dart';
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
  final CopilotBloc? copilotBloc;
  AIBloc(
      this.config,
      this.isEnabled,
      Map<String, dynamic> modelSelectedInput,
      this.showSuggestionOntap,
      {this.copilotBloc}
    ) : modelSelected = (() {
          if (copilotBloc != null && copilotBloc.state.status == CopilotStatus.signedIn) {
            final ms = Map<String, dynamic>.from(modelSelectedInput);
            if (ms['code'] == null || ms['code'] == '') {
              ms['code'] = 'copilot';
            }
            return ms;
          }
          return Map<String, dynamic>.from(modelSelectedInput);
        })(),
        super(AIState(
          config,
          isEnabled,
          (() {
            final ms = Map<String, dynamic>.from(modelSelectedInput);
            if (copilotBloc != null && copilotBloc.state.status == CopilotStatus.signedIn) {
              if (ms['code'] == null || ms['code'] == '') ms['code'] = 'copilot';
            }
            return ms;
          })(),
          showSuggestionOntap,
        )) {
    on<AIConfigEvent>((event, emit) => emit(state.copyWith(config: event.config)));
    on<AIEnableEvent>((event, emit) => emit(state.copyWith(isEnabled: event.isEnabled)));
    on<ModelSelectEvent>((event, emit) => emit(state.copyWith(modelSelected: event.modelSelected)));
    on<AIModeEvent>((event, emit) => emit(state.copyWith(showSuggestionOntap: event.showSuggestionOntap)));

    copilotBloc?.stream.listen((copilotState) {
      try {
        final status = copilotState.status;
        if (status == CopilotStatus.signedIn) {
          final ms = Map<String, dynamic>.from(state.modelSelected);
          if (ms['code'] == null || ms['code'] == '') {
            ms['code'] = 'copilot';
            add(ModelSelectEvent(ms));
          }
        } else {
          final ms = Map<String, dynamic>.from(state.modelSelected);
          if (ms['code'] == 'copilot') {
            ms.remove('code');
            add(ModelSelectEvent(ms));
          }
        }
      } catch (_) {}
    });
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

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  CopilotLsp? _client;
  CopilotCompletionManager? _completionManager;
  StreamSubscription? _notificationSubscription;
  bool _expectingSignIn = false;
  
  static const String _storageKey = 'copilot_config';

  CopilotBloc() : super(CopilotState.initial()) {
    on<CopilotAutoInit>(_onAutoInit);
    on<CopilotInitialize>(_onInitialize);
    on<CopilotSignInInitiate>(_onSignInInitiate);
    on<CopilotSignInConfirm>(_onSignInConfirm);
    on<CopilotSignOut>(_onSignOut);
    on<CopilotCheckStatus>(_onCheckStatus);
    on<CopilotUpdateStatus>(_onUpdateStatus);
    on<CopilotSetEnabled>(_onSetEnabled);
    on<CopilotSetCompletion>(_onSetCompletion);
    on<CopilotClearCompletion>(_onClearCompletion);
    on<CopilotAcceptCompletion>(_onAcceptCompletion);
    on<CopilotRejectCompletion>(_onRejectCompletion);
    on<CopilotRequestCompletion>(_onRequestCompletion);
    on<CopilotDispose>(_onDispose);
  }

  CopilotLsp? get client => _client;
  CopilotCompletionManager? get completionManager => _completionManager;

  void _onAutoInit(CopilotAutoInit event, Emitter<CopilotState> emit) {
    final configPath = '/data/data/com.vsdroid/files';
    final copilotPath = '$extensionDir/copilot-language-server';
    
    if (!Directory(copilotPath).existsSync()) {
      debugPrint('Copilot extension not installed, skipping auto-init');
      return;
    }
    add(CopilotInitialize(configPath: configPath));
  }

  Future<void> _onInitialize(CopilotInitialize event, Emitter<CopilotState> emit) async {
    if (state.status == CopilotStatus.initializing) return;
    
    emit(state.copyWith(status: CopilotStatus.initializing));
    
    try {
      await _loadConfig(emit);
      
      _client = await CopilotLsp.start(
        configPath: event.configPath,
        workspacePath: event.workspacePath ?? '',
      );

      await _client!.initialize();

      _client!.notificationStream.listen((response) {
        if (_expectingSignIn && (response['type'] == 'statusNotification' || response['type'] == 'didChangeStatus')) {
          _expectingSignIn = false;
          add(CopilotCheckStatus());
        }
      });
      
      _completionManager = CopilotCompletionManager(
        client: _client!,
        debounceDelay: Duration(milliseconds: event.debounceMs),
        onCompletionReady: (completion) {
          if (completion != null) {
            add(CopilotSetCompletion(
              text: completion.text,
              displayText: completion.displayText,
              uuid: completion.uuid,
            ));
          } else {
            add(CopilotClearCompletion());
          }
        },
        onCompletionCleared: () {
          add(CopilotClearCompletion());
        },
      );
      
      final statusPayload = await _client!.checkStatus();
      
      CopilotStatus newStatus;
      if (statusPayload.isOk || statusPayload.isAlreadySignedIn) {
        newStatus = CopilotStatus.signedIn;
      } else if (statusPayload.isNotAuthorized) {
        newStatus = CopilotStatus.notAuthorized;
      } else {
        newStatus = CopilotStatus.notSignedIn;
      }
      
      emit(state.copyWith(
        status: newStatus,
        user: statusPayload.user,
        isInitialized: true,
      ));
      
      await _saveConfig(true);
    } catch (e) {
      debugPrint('Copilot initialization error: $e');
      if (e is TimeoutException) {
        emit(state.copyWith(
          status: CopilotStatus.notSignedIn,
          isInitialized: true,
        ));
      } else {
        emit(state.copyWith(
          status: CopilotStatus.error,
          error: e.toString(),
        ));
      }
    }
  }

  Future<void> _onSignInInitiate(CopilotSignInInitiate event, Emitter<CopilotState> emit) async {
    if (_client == null) return;
    
    emit(state.copyWith(status: CopilotStatus.signingIn));
    
    try {
      final payload = await _client!.signIn();
      
      if (payload.isAlreadySignedIn) {
        emit(state.copyWith(
          status: CopilotStatus.signedIn,
          user: payload.user,
        ));
        return;
      }
      
      emit(state.copyWith(
        signInPayload: payload,
      ));
      
      _expectingSignIn = true;
    } catch (e) {
      emit(state.copyWith(
        status: CopilotStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSignInConfirm(CopilotSignInConfirm event, Emitter<CopilotState> emit) async {
    if (_client == null) return;
    
    try {
      final payload = await _client!.signInConfirm(event.userCode);
      
      if (payload.isOk || payload.isAlreadySignedIn) {
        _expectingSignIn = false;
        emit(state.copyWith(
          status: CopilotStatus.signedIn,
          user: payload.user,
          signInPayload: null,
        ));
        await _saveConfig(true);
      } else if (payload.isNotAuthorized) {
        emit(state.copyWith(
          status: CopilotStatus.notAuthorized,
          signInPayload: null,
        ));
      } else {        _expectingSignIn = false;        emit(state.copyWith(
          status: CopilotStatus.notSignedIn,
          signInPayload: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CopilotStatus.error,
        error: e.toString(),
        signInPayload: null,
      ));
    }
  }

  Future<void> _onSignOut(CopilotSignOut event, Emitter<CopilotState> emit) async {
    if (_client == null) return;
    
    try {
      await _client!.signOut();
      emit(state.copyWith(
        status: CopilotStatus.notSignedIn,
        user: null,
        signInPayload: null,
      ));
      await _saveConfig(false);
    } catch (e) {
      emit(state.copyWith(
        status: CopilotStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCheckStatus(CopilotCheckStatus event, Emitter<CopilotState> emit) async {
    if (_client == null) return;
    
    try {
      final payload = await _client!.checkStatus();
      
      CopilotStatus newStatus;
      if (payload.isOk || payload.isAlreadySignedIn) {
        newStatus = CopilotStatus.signedIn;
      } else if (payload.isNotAuthorized) {
        newStatus = CopilotStatus.notAuthorized;
      } else {
        newStatus = CopilotStatus.notSignedIn;
      }
      
      emit(state.copyWith(
        status: newStatus,
        user: payload.user,
      ));
    } catch (e) {
      debugPrint('Check status error: $e');
    }
  }

  void _onUpdateStatus(CopilotUpdateStatus event, Emitter<CopilotState> emit) {
    emit(state.copyWith(status: event.status));
  }

  Future<void> _onSetEnabled(CopilotSetEnabled event, Emitter<CopilotState> emit) async {
    emit(state.copyWith(isEnabled: event.isEnabled));
    
    if (!event.isEnabled) {
      _completionManager?.cancel();
    }
  }

  void _onSetCompletion(CopilotSetCompletion event, Emitter<CopilotState> emit) {
    emit(state.copyWith(
      currentCompletion: CopilotCompletionData(
        text: event.text,
        displayText: event.displayText,
        uuid: event.uuid,
      ),
    ));
  }

  void _onClearCompletion(CopilotClearCompletion event, Emitter<CopilotState> emit) {
    emit(state.copyWith(clearCompletion: true));
  }

  Future<void> _onAcceptCompletion(CopilotAcceptCompletion event, Emitter<CopilotState> emit) async {
    await _completionManager?.acceptCompletion();
    emit(state.copyWith(clearCompletion: true));
  }

  Future<void> _onRejectCompletion(CopilotRejectCompletion event, Emitter<CopilotState> emit) async {
    await _completionManager?.rejectCompletions();
    emit(state.copyWith(clearCompletion: true));
  }

  void _onRequestCompletion(CopilotRequestCompletion event, Emitter<CopilotState> emit) {
    if (!state.isEnabled || state.status != CopilotStatus.signedIn) return;
    
    if (event.immediate) {
      _completionManager?.fetchCompletionsNow(
        filePath: event.filePath,
        content: event.content,
        line: event.line,
        character: event.character,
        languageId: event.languageId,
      );
    } else {
      _completionManager?.requestCompletions(
        filePath: event.filePath,
        content: event.content,
        line: event.line,
        character: event.character,
        languageId: event.languageId,
      );
    }
  }

  Future<void> _onDispose(CopilotDispose event, Emitter<CopilotState> emit) async {
    _notificationSubscription?.cancel();
    _completionManager?.dispose();
    _client?.dispose();
    _client = null;
    _completionManager = null;
    
    emit(CopilotState.initial());
  }

  Future<void> _saveConfig(bool isSignedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode({
      'isSignedIn': isSignedIn,
      'isEnabled': state.isEnabled,
    }));
  }

  Future<void> _loadConfig(Emitter<CopilotState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configStr = prefs.getString(_storageKey);
      if (configStr != null) {
        final config = jsonDecode(configStr) as Map<String, dynamic>;
        final wasSignedIn = config['isSignedIn'] as bool? ?? false;
        final isEnabled = config['isEnabled'] as bool? ?? true;
        
        emit(state.copyWith(
          isEnabled: isEnabled,
        ));
        
        debugPrint('Loaded Copilot config: signedIn=$wasSignedIn, enabled=$isEnabled');
      }
    } catch (e) {
      debugPrint('Failed to load Copilot config: $e');
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _completionManager?.dispose();
    _client?.dispose();
    return super.close();
  }
}

class CopilotChatBloc extends Bloc<CopilotChatEvent, CopilotChatState> {
  CopilotChat? _chatClient;
  StreamSubscription? _conversationSubscription;

  CopilotChatBloc() : super(CopilotChatState.initial()) {
    on<CopilotChatFetchModels>(_onChatFetchModels);
    on<_CopilotChatInternalUpdateMessages>(_onInternalUpdateMessages);

    _initializeChatClient();
  }

  CopilotChat? get chatClient => _chatClient;

  Future<void> _initializeChatClient() async {
    final authToken = await CopilotChat.loadAuthToken();
    if (authToken != null) {
      _chatClient = CopilotChat(
        authToken: authToken,
      );
    }
  }

  Future<void> _onChatFetchModels(CopilotChatFetchModels event, Emitter<CopilotChatState> emit) async {
    if (_chatClient == null) {
      await _initializeChatClient();
    }

    if (_chatClient != null) {
      try {
        final models = await _chatClient!.getCopilotModels();
        final data = models['data'] as List<dynamic>? ?? [];
        final filteredModels = data.where((model) {
          final policy = model['policy'] as Map<String, dynamic>?;
          return policy != null && policy['state'] == 'enabled';
        }).toList().cast<Map<String, dynamic>>();
        emit(state.copyWith(models: filteredModels));
      } catch (e) {
        debugPrint('Failed to fetch Copilot models: $e');
      }
    }
  }

  void _onInternalUpdateMessages(_CopilotChatInternalUpdateMessages event, Emitter<CopilotChatState> emit) {
    emit(state.copyWith(chatMessages: event.messages));
  }

  @override
  Future<void> close() {
    _conversationSubscription?.cancel();
    _chatClient?.dispose();
    return super.close();
  }
}