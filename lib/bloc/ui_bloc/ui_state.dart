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

class ActiveEditorsState{
  final List<ActiveEditors> activeEditors;

  ActiveEditorsState(this.activeEditors);
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

class GitCommitState {
  final String commitMessage;

  GitCommitState({required this.commitMessage});
}

class DownloadManagerState {
  final Map<int, double> downloadProgress;
  final Map<int, double> extractionProgress;
  final Set<int> extractingItems; // Items currently being extracted
  final Set<int> fullyCompleted; // Items with extraction complete

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