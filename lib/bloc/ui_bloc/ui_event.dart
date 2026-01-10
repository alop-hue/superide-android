part of 'ui_bloc.dart';

@immutable
sealed class UiEvent {}
sealed class RestEvent extends UiEvent {}
sealed class AIEvent extends UiEvent{}

class StackIndexChange extends UiEvent {
  final int stackValue;
  StackIndexChange({required this.stackValue});
}

class SetFontSize extends UiEvent{
  final double fontSize;
  SetFontSize({required this.fontSize});
}

class ChangeConfigEvent extends UiEvent{
  final Map<String, dynamic> codeForgeConfig;
  ChangeConfigEvent(this.codeForgeConfig);
}

class Search extends UiEvent {
  final List<Card> searchedLangs;
  Search({required this.searchedLangs});
}

class FindWord extends UiEvent {
  final String word;
  final bool matchCase, matchWholeWord, isRegex;
  FindWord({
    required this.word,
    required this.matchCase,
    required this.matchWholeWord,
    required this.isRegex
  });
}

class SetViewPort extends UiEvent{
  final bool isMobile;
  SetViewPort({required this.isMobile});
}

class EnableConsole extends UiEvent{
  final bool isConsole;
  EnableConsole({required this.isConsole});
}


class ApiEvent extends RestEvent{
  final String method;
  ApiEvent({required this.method});
}

class GetParams extends RestEvent{
  final Map<String,String> params;
  GetParams({required this.params});
}

class GetHeaders extends RestEvent{
  final Map<String,String> headers;
  GetHeaders({required this.headers});
}

class GetBody extends RestEvent{
  final Map<String,String> body;
  GetBody({required this.body});
}

class GetUrl extends RestEvent{
  final String url;
  GetUrl({required this.url});
}

class GotApiData extends RestEvent{
  final Map<String,dynamic> data;
  GotApiData({required this.data});
}

class FileTreeEvent extends UiEvent{
  final Map<String, bool> folderStates;
  FileTreeEvent({required this.folderStates});
}

class RecentEvent extends UiEvent{
  final List<dynamic> recent;
  RecentEvent({required this.recent});
}

class AppThemeEvent extends UiEvent{
  final AppTheme appTheme;
  AppThemeEvent({required this.appTheme});
}

class ActiveEditorsEvent extends UiEvent{
  final List<ActiveEditors> activeEditors;

  ActiveEditorsEvent(this.activeEditors);
}


class AIConfigEvent extends AIEvent{
  final Map<String, dynamic> config;

  AIConfigEvent(this.config);
}

class AIEnableEvent extends AIEvent {
  final bool isEnabled;

  AIEnableEvent(this.isEnabled);
}

class ModelSelectEvent extends AIEvent {
  final Map<String, dynamic> modelSelected;

  ModelSelectEvent(this.modelSelected);
}

class AIModeEvent extends AIEvent {
  final bool showSuggestionOntap;

  AIModeEvent(this.showSuggestionOntap);
}

class DownloadProgressEvent extends UiEvent{
  final Map<String, double>? downloadProgress;

  DownloadProgressEvent(this.downloadProgress);
}

class GeneralEvent extends UiEvent {
  final Map<String, dynamic> generalSettings; 

  GeneralEvent({required this.generalSettings});
}

class AIChatEvent extends UiEvent {
  final List<AIConversation> aiConversation;

  AIChatEvent(this.aiConversation);
}

// Chat Session Events
sealed class ChatSessionEvent extends UiEvent {}

class LoadChatSessions extends ChatSessionEvent {}

class CreateNewSession extends ChatSessionEvent {}

class SelectSession extends ChatSessionEvent {
  final String sessionId;
  SelectSession(this.sessionId);
}

class UpdateCurrentSession extends ChatSessionEvent {
  final List<AIConversation> conversations;
  final String? title;
  UpdateCurrentSession({required this.conversations, this.title});
}

class DeleteSession extends ChatSessionEvent {
  final String sessionId;
  DeleteSession(this.sessionId);
}

class UpdateSessionTitle extends ChatSessionEvent {
  final String sessionId;
  final String title;
  UpdateSessionTitle({required this.sessionId, required this.title});
}

class GitCommitEvent extends UiEvent {
  final String commitMessage;

  GitCommitEvent({required this.commitMessage});
}

// Workspace Search Events
sealed class WorkspaceSearchEvent extends UiEvent {}

class UpdateSearchResults extends WorkspaceSearchEvent {
  final List<SearchResultData> results;
  final String query;

  UpdateSearchResults({required this.results, required this.query});
}

class SetSearching extends WorkspaceSearchEvent {
  final bool isSearching;

  SetSearching({required this.isSearching});
}

class UpdateSearchOptions extends WorkspaceSearchEvent {
  final bool matchCase;
  final bool matchWholeWord;
  final bool isRegex;

  UpdateSearchOptions({
    required this.matchCase,
    required this.matchWholeWord,
    required this.isRegex,
  });
}

class ClearSearchResults extends WorkspaceSearchEvent {}