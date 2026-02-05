part of 'ui_bloc.dart';

class StackState {
  final int stackIndex;
  const StackState({required this.stackIndex});
}

class ConfigState {
  final double fontSize;
  final Map<String, dynamic> codeForgeConfig;
  const ConfigState({
    required this.fontSize,
    required this.codeForgeConfig
  });
  ConfigState copyWith({
    double? fontSize,
    Map<String, dynamic>? codeForgeConfig
  }){
    return ConfigState(
      fontSize: fontSize ?? this.fontSize,
      codeForgeConfig: codeForgeConfig ?? this.codeForgeConfig
    );
  }
}

class GeneralState{
  final Map<String, dynamic> generalSettings;
  GeneralState({required this.generalSettings});
}

class MenuSearchState {
  final List<Card> searchedLangs;
  const MenuSearchState({required this.searchedLangs});
}

class FindWordState {
  final String word;
  final bool matchCase, matchWholeWord, isRegex;
  const FindWordState({
    required this.word,
    required this.matchCase,
    required this.matchWholeWord,
    required this.isRegex
  });
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
  const ApiState({
    required this.method,
    required this.params,
    required this.headers,
    required this.body,
    this.data,
    this.url
  });
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

class FolderState {
  final Map<String, bool> folderStates;

  FolderState(this.folderStates);

  FolderState copyWith({Map<String, bool>? folderStates}) {
    return FolderState(folderStates ?? this.folderStates);
  }
}

class RecentState{
  final List<dynamic> recent;
  RecentState({required this.recent});
}

class AppThemeState{
  final AppTheme appTheme;
  const AppThemeState({required this.appTheme});
}

class ActiveEditorState{
  final List<ActiveEditor> activeEditors;

  ActiveEditorState(this.activeEditors);
}

class AIState {
  final Map<String, dynamic> config, modelSelected;
  final bool isEnabled, showSuggestionOntap;
  final Models? completionModel, chatModel;

  AIState(this.config, this.isEnabled, this.modelSelected, this.showSuggestionOntap)
    : completionModel = (() {
        if (config.isEmpty || modelSelected.isEmpty || modelSelected['code'] == null || config[modelSelected['code']] == null) {
          return null;
        }
        final String provider = config[modelSelected['code']]['provider'];
        final String apiKey = config[modelSelected['code']]['apiKey'];
        final String modelName = config[modelSelected['code']]['modelName'];
        switch (provider) {
          case 'Gemini': return Gemini(apiKey: apiKey, model: modelName);
          case 'Claude': return Claude(apiKey: apiKey, model: modelName);
          case 'OpenAI': return OpenAI(apiKey: apiKey, model: modelName);
          case 'Grok': return Grok(apiKey: apiKey, model: modelName);
          case 'DeepSeek': return DeepSeek(apiKey: apiKey, model: modelName);
          case 'Gorq': return Gorq(apiKey: apiKey, model: modelName);
          case 'TogetherAI': return TogetherAi(apiKey: apiKey, model: modelName);
          case 'Sonar': return Sonar(apiKey: apiKey, model: modelName);
          case 'OpenRouter': return OpenRouter(apiKey: apiKey, model: modelName);
          case 'FireWorks': return FireWorks(apiKey: apiKey, model: modelName);
        }
      })(),
      chatModel = (() {
        if (config.isEmpty || modelSelected.isEmpty || modelSelected['chat'] == null || config[modelSelected['chat']] == null) {
          return null;
        }
        final String provider = config[modelSelected['chat']]['provider'];
        final String apiKey = config[modelSelected['chat']]['apiKey'];
        final String modelName = config[modelSelected['chat']]['modelName'];
        switch (provider) {
          case 'Gemini': return Gemini(apiKey: apiKey, model: modelName);
          case 'Claude': return Claude(apiKey: apiKey, model: modelName);
          case 'OpenAI': return OpenAI(apiKey: apiKey, model: modelName);
          case 'Grok': return Grok(apiKey: apiKey, model: modelName);
          case 'DeepSeek': return DeepSeek(apiKey: apiKey, model: modelName);
          case 'Gorq': return Gorq(apiKey: apiKey, model: modelName);
          case 'TogetherAI': return TogetherAi(apiKey: apiKey, model: modelName);
          case 'Sonar': return Sonar(apiKey: apiKey, model: modelName);
          case 'OpenRouter': return OpenRouter(apiKey: apiKey, model: modelName);
          case 'FireWorks': return FireWorks(apiKey: apiKey, model: modelName);
        }
      })();

  AIState copyWith({
    Map<String, dynamic>? config,
    Map<String, dynamic>? modelSelected,
    bool? isEnabled,
    bool? showSuggestionOntap,
  }) {
    return AIState(
      config ?? this.config,
      isEnabled ?? this.isEnabled,
      modelSelected ?? this.modelSelected,
      showSuggestionOntap ?? this.showSuggestionOntap 
    );
  }
}

class DownloadProgressState {
  final Map<String, double>? downloadProgress;

  DownloadProgressState(this.downloadProgress);
}

class AIChatState {
  final List<AIConversation> aiConversation;

  AIChatState(this.aiConversation);
}

class ChatSessionState {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final bool isLoading;

  ChatSessionState({
    required this.sessions,
    this.currentSession,
    this.isLoading = false,
  });

  ChatSessionState copyWith({
    List<ChatSession>? sessions,
    ChatSession? currentSession,
    bool? isLoading,
    bool clearCurrentSession = false,
  }) => ChatSessionState(
    sessions: sessions ?? this.sessions,
    currentSession: clearCurrentSession ? null : (currentSession ?? this.currentSession),
    isLoading: isLoading ?? this.isLoading,
  );
}

class GitCommitState {
  final String commitMessage;

  GitCommitState({required this.commitMessage});
}

class SearchResultData {
  final String filePath;
  final int lineNumber;
  final String lineContent;
  final String relativePath;

  SearchResultData({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
    required this.relativePath,
  });
}

class WorkspaceSearchState {
  final List<SearchResultData> results;
  final String query;
  final bool isSearching;
  final bool matchCase;
  final bool matchWholeWord;
  final bool isRegex;

  WorkspaceSearchState({
    required this.results,
    required this.query,
    required this.isSearching,
    required this.matchCase,
    required this.matchWholeWord,
    required this.isRegex,
  });

  factory WorkspaceSearchState.initial() => WorkspaceSearchState(
    results: [],
    query: '',
    isSearching: false,
    matchCase: false,
    matchWholeWord: false,
    isRegex: false,
  );

  WorkspaceSearchState copyWith({
    List<SearchResultData>? results,
    String? query,
    bool? isSearching,
    bool? matchCase,
    bool? matchWholeWord,
    bool? isRegex,
  }) {
    return WorkspaceSearchState(
      results: results ?? this.results,
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      matchCase: matchCase ?? this.matchCase,
      matchWholeWord: matchWholeWord ?? this.matchWholeWord,
      isRegex: isRegex ?? this.isRegex,
    );
  }
}

class DownloadManagerState {
  final Map<int, double> downloadProgress;
  final Map<int, double> extractionProgress;
  final Set<int> extractingItems;
  final Set<int> fullyCompleted;

  DownloadManagerState({
    required this.downloadProgress,
    required this.extractionProgress,
    required this.extractingItems,
    required this.fullyCompleted,
  });

  DownloadManagerState copyWith({
    Map<int, double>? downloadProgress,
    Map<int, double>? extractionProgress,
    Set<int>? extractingItems,
    Set<int>? fullyCompleted,
  }) {
    return DownloadManagerState(
      downloadProgress: downloadProgress ?? this.downloadProgress,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      extractingItems: extractingItems ?? this.extractingItems,
      fullyCompleted: fullyCompleted ?? this.fullyCompleted,
    );
  }

  bool isDownloading(int index) {
    return downloadProgress.containsKey(index) && 
           (downloadProgress[index] ?? 0) < 100.0;
  }

  bool isDownloadComplete(int index) {
    return (downloadProgress[index] ?? 0) >= 100.0;
  }

  bool isExtracting(int index) {
    return extractingItems.contains(index);
  }

  bool isFullyCompleted(int index) {
    return fullyCompleted.contains(index);
  }
}

// ================== Copilot State ==================

enum CopilotStatus {
  notInitialized,
  initializing,
  notSignedIn,
  signingIn,
  signedIn,
  notAuthorized,
  error,
}

class CopilotCompletionData {
  final String text;
  final String displayText;
  final String uuid;

  CopilotCompletionData({
    required this.text,
    required this.displayText,
    required this.uuid,
  });
}

class CopilotChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  CopilotChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CopilotChatMessage.fromJson(Map<String, dynamic> json) => CopilotChatMessage(
    role: json['role'],
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  CopilotChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return CopilotChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class CopilotState {
  final CopilotStatus status;
  final String? user;
  final String? error;
  final bool isInitialized;
  final bool isEnabled;
  final CopilotSignInPayload? signInPayload;
  final CopilotCompletionData? currentCompletion;

  CopilotState({
    required this.status,
    this.user,
    this.error,
    this.isInitialized = false,
    this.isEnabled = true,
    this.signInPayload,
    this.currentCompletion,
  });

  factory CopilotState.initial() => CopilotState(
    status: CopilotStatus.notInitialized,
  );

  bool get isSignedIn => status == CopilotStatus.signedIn;
  bool get canUseCompletion => isSignedIn && isEnabled;

  CopilotState copyWith({
    CopilotStatus? status,
    String? user,
    String? error,
    bool? isInitialized,
    bool? isEnabled,
    CopilotSignInPayload? signInPayload,
    CopilotCompletionData? currentCompletion,
    bool clearCompletion = false,
  }) {
    return CopilotState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      isEnabled: isEnabled ?? this.isEnabled,
      signInPayload: signInPayload ?? this.signInPayload,
      currentCompletion: clearCompletion ? null : (currentCompletion ?? this.currentCompletion),
    );
  }
}

// ================== Copilot Chat State ==================

class CopilotChatState {
  final List<CopilotChatMessage> chatMessages;
  final bool isChatStreaming;
  final List<Map<String, dynamic>> models;
  final String? error;

  CopilotChatState({
    this.chatMessages = const [],
    this.isChatStreaming = false,
    this.models = const [],
    this.error,
  });

  factory CopilotChatState.initial() => CopilotChatState();

  CopilotChatState copyWith({
    List<CopilotChatMessage>? chatMessages,
    bool? isChatStreaming,
    List<Map<String, dynamic>>? models,
    String? error,
  }) {
    return CopilotChatState(
      chatMessages: chatMessages ?? this.chatMessages,
      isChatStreaming: isChatStreaming ?? this.isChatStreaming,
      models: models ?? this.models,
      error: error,
    );
  }
}