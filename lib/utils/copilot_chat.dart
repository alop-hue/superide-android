import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:vsdroid/utils/constants.dart';
import 'agentic_tools.dart';

class CopilotChat {
  final String authToken;
  static const String _preferredCopilotApiEndpoint =
      'https://api.githubcopilot.com';
  static const String _defaultCopilotApiEndpoint = 'https://api.individual.githubcopilot.com';
  static const String _graphqlEndpoint = 'https://api.github.com/graphql';

  AgenticTools? _agenticTools;
  http.Client? _currentClient;
  String? _apiEndpoint;
  List<Map<String, dynamic>>? _cachedModels;

  set agenticTools(AgenticTools tools) => _agenticTools = tools;
  final StreamController<Map<String, dynamic>> _conversationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get conversationStream =>
      _conversationController.stream;

  void cancelCurrentRequest() {
    _currentClient?.close();
    _currentClient = null;
  }

  static Future<String?> loadAuthToken({bool preferGithubToken = true}) async {
    try {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final all = await storage.readAll();

      final tokenFromCopilotConfig = await _loadCopilotOauthTokenFromConfigFiles(
        domain: 'github.com',
      );
      if (tokenFromCopilotConfig != null && tokenFromCopilotConfig.isNotEmpty) {
        return tokenFromCopilotConfig;
      }

      final explicitCopilotToken = all['copilot_chat_auth_token'];
      if (explicitCopilotToken != null && explicitCopilotToken.isNotEmpty) {
        return explicitCopilotToken;
      }

      final copilotEntry = all.entries.cast<MapEntry<String, String?>>().firstWhere(
        (entry) {
          final key = entry.key.toLowerCase();
          final value = entry.value;
          return key.contains('copilot') && value != null && value.isNotEmpty;
        },
        orElse: () => const MapEntry<String, String?>('', null),
      );

      if (copilotEntry.value != null && copilotEntry.value!.isNotEmpty) {
        return copilotEntry.value;
      }

      final githubToken = all['github_access_token'];
      if (githubToken != null && githubToken.isNotEmpty) {
        return githubToken;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  static Future<String?> _loadCopilotOauthTokenFromConfigFiles({
    required String domain,
  }) async {
    final candidates = <String>[
      '$filesDir/github-copilot/hosts.json',
      '$filesDir/github-copilot/apps.json',
      '$filesDir/.config/github-copilot/hosts.json',
      '$filesDir/.config/github-copilot/apps.json',
      '$homeDir/.config/github-copilot/hosts.json',
      '$homeDir/.config/github-copilot/apps.json',
    ];

    for (final filePath in candidates) {
      try {
        final file = File(filePath);
        if (!await file.exists()) continue;

        final content = await file.readAsString();
        final parsed = jsonDecode(content);
        if (parsed is! Map<String, dynamic>) continue;

        for (final entry in parsed.entries) {
          final key = entry.key.toLowerCase();
          final value = entry.value;
          if (value is! Map<String, dynamic>) continue;

          final oauthToken = value['oauth_token'] as String?;
          if (oauthToken == null || oauthToken.isEmpty) continue;

          if (key.startsWith(domain.toLowerCase()) || key.contains(domain.toLowerCase())) {
            return oauthToken;
          }
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  CopilotChat({required this.authToken});

  Map<String, String> _commonHeaders({
    bool isJsonBody = false,
    ChatMode? chatMode,
  }) {
    String? initiator;
    if (chatMode != null) {
      initiator = chatMode == ChatMode.agent ? 'agent' : 'user';
    }

    return {
      'Authorization': 'Bearer $authToken',
      'Accept': 'application/json',
      'Copilot-Integration-Id': 'vscode-chat',
      'User-Agent': 'VSdroid/1.0.0',
      'Editor-Version': 'VSdroid/1.0.0',
      'X-GitHub-Api-Version': '2025-10-01',
      if (initiator != null) 'X-Initiator': initiator,
      if (initiator != null) 'X-Interaction-Type': 'conversation-panel',
      if (initiator != null) 'OpenAI-Intent': 'conversation-panel',
      if (isJsonBody) 'Content-Type': 'application/json; charset=utf-8',
    };
  }

  Future<String> _resolveApiEndpoint() async {
    if (_apiEndpoint != null && _apiEndpoint!.isNotEmpty) {
      return _apiEndpoint!;
    }

    try {
      final preferredProbe = await http.get(
        Uri.parse('$_preferredCopilotApiEndpoint/models'),
        headers: _commonHeaders(),
      );
      if (preferredProbe.statusCode == 200) {
        _apiEndpoint = _preferredCopilotApiEndpoint;
        return _apiEndpoint!;
      }
    } catch (_) {
    }

    try {
      final response = await http.post(
        Uri.parse(_graphqlEndpoint),
        headers: _commonHeaders(isJsonBody: true),
        body: jsonEncode({
          'query': 'query { viewer { copilotEndpoints { api } } }',
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final api =
            ((decoded['data'] as Map<String, dynamic>?)?['viewer']
                as Map<String, dynamic>?)?['copilotEndpoints'];
        final endpoint = (api as Map<String, dynamic>?)?['api'] as String?;
        if (endpoint != null && endpoint.isNotEmpty) {
          _apiEndpoint = endpoint;
          return endpoint;
        }
      }
    } catch (_) {
    }

    _apiEndpoint = _defaultCopilotApiEndpoint;
    return _apiEndpoint!;
  }

  Set<String> _modelSupportedEndpoints(String model) {
    if (_cachedModels == null) return const {};

    final modelData = _cachedModels!.firstWhere(
      (item) => item['id'] == model,
      orElse: () => const {},
    );

    if (modelData.isEmpty) return const {};
    final endpoints = modelData['supported_endpoints'];
    if (endpoints is! List) return const {};
    return endpoints.whereType<String>().toSet();
  }

  String _selectChatPath(String model, {required bool hasTools}) {
    final supportedEndpoints = _modelSupportedEndpoints(model);

    if (supportedEndpoints.isEmpty ||
        supportedEndpoints.contains('/chat/completions')) {
      return '/chat/completions';
    }

    if (hasTools) {
      return '/chat/completions';
    }

    if (supportedEndpoints.contains('/responses')) {
      return '/responses';
    }

    if (supportedEndpoints.contains('/v1/messages')) {
      return '/v1/messages';
    }

    return '/chat/completions';
  }

  Map<String, dynamic> _buildRequestBodyForPath(
    String path,
    String model,
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
  ) {
    switch (path) {
      case '/responses':
        return {'model': model, 'input': messages, 'stream': true};
      case '/v1/messages':
        return {
          'model': model,
          'messages': messages,
          'max_tokens': 4096,
          'stream': true,
        };
      case '/chat/completions':
      default:
        return {
          'model': model,
          'messages': messages,
          'stream': true,
          if (tools.isNotEmpty) 'tools': tools,
        };
    }
  }

  String? _extractDeltaText(Map<String, dynamic> json, String path) {
    if (path == '/chat/completions') {
      return json['choices']?[0]?['delta']?['content'] as String?;
    }

    if (path == '/responses') {
      final type = json['type'] as String?;
      if (type == 'response.output_text.delta') {
        return json['delta'] as String?;
      }
      if (type == 'response.output_text.done') {
        return json['text'] as String?;
      }
      return null;
    }

    if (path == '/v1/messages') {
      final type = json['type'] as String?;
      if (type == 'content_block_delta') {
        return json['delta']?['text'] as String?;
      }
      return null;
    }

    return null;
  }

  int _lineCount(String? text) {
    if (text == null || text.isEmpty) return 0;
    return text.split('\n').length;
  }

  String _shellCommandPreview(String command, List<String> args) {
    final parts = [command, ...args].map(_shellEscape).toList();
    return parts.join(' ');
  }

  String _shellEscape(String value) {
    if (value.isEmpty) return "''";
    final safePattern = RegExp(r'^[A-Za-z0-9_./:-]+');
    final match = safePattern.firstMatch(value);
    if (match != null && match.start == 0 && match.end == value.length) {
      return value;
    }
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _toolEditMarker(String filePath, int added, int removed) {
    final fileEncoded = base64Encode(utf8.encode(filePath));
    return '[[VSDROID_EDIT:$fileEncoded|$added|$removed]]\n';
  }

  String _toolTerminalMarker(String command) {
    final encoded = base64Encode(utf8.encode(command));
    return '[[VSDROID_TERMINAL:$encoded]]\n';
  }

  Future<Map<String, dynamic>> getCopilotModels() async {
    final apiEndpoint = await _resolveApiEndpoint();
    final modelUrl = '$apiEndpoint/models';

    final response = await http.get(
      Uri.parse(modelUrl),
      headers: _commonHeaders(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final parsed = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{
              'data': decoded,
            };
      final data = parsed['data'];
      if (data is List) {
        _cachedModels = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
      }
      return parsed;
    } else {
      throw Exception(
        'Failed to fetch models: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String> chatWithModel({
    required String model,
    required List<Map<String, dynamic>> messages,
    ChatMode chatMode = ChatMode.ask,
    void Function(String)? onPartial,
  }) async {
    final tools = chatMode == ChatMode.agent
        ? _agenticTools?.getTools() ?? []
        : _agenticTools?.getTools(readAccessOnly: true) ?? [];
    final conversationMessages = List<Map<String, dynamic>>.from(messages);
    final apiEndpoint = await _resolveApiEndpoint();
    final chatPath = _selectChatPath(model, hasTools: tools.isNotEmpty);
    final streamedOutput = StringBuffer();

    void pushPartial(String text) {
      if (text.isEmpty) return;
      streamedOutput.write(text);
      onPartial?.call(text);
    }

    while (true) {
      final requestBody = _buildRequestBodyForPath(
        chatPath,
        model,
        conversationMessages,
        tools,
      );

      _currentClient = http.Client();
      final request = http.Request('POST', Uri.parse('$apiEndpoint$chatPath'));
      request.headers.addAll(
        _commonHeaders(isJsonBody: true, chatMode: chatMode),
      );
      request.body = jsonEncode(requestBody);

      final streamedResponse = await _currentClient!.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(body);
      }

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      Map<String, dynamic>? finalMessage;
      List<Map<String, dynamic>> toolCallDeltas = [];

      await for (var line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            if (chatPath == '/chat/completions') {
              final delta = json['choices']?[0]?['delta'];
              if (delta == null) continue;
              finalMessage ??= {
                'role': delta['role'] ?? 'assistant',
                'content': '',
              };

              final deltaText = _extractDeltaText(json, chatPath);
              if (deltaText != null && deltaText.isNotEmpty) {
                finalMessage['content'] += deltaText;
                pushPartial(deltaText);
              }

              if (delta['tool_calls'] != null) {
                for (var toolCallDelta in delta['tool_calls']) {
                  final index = toolCallDelta['index'];
                  if (index >= toolCallDeltas.length) {
                    toolCallDeltas.add({});
                  }
                  if (toolCallDelta['id'] != null) {
                    toolCallDeltas[index]['id'] = toolCallDelta['id'];
                  }
                  if (toolCallDelta['function'] != null) {
                    toolCallDeltas[index]['function'] ??= {};
                    if (toolCallDelta['function']['name'] != null) {
                      toolCallDeltas[index]['function']['name'] =
                          toolCallDelta['function']['name'];
                    }
                    if (toolCallDelta['function']['arguments'] != null) {
                      toolCallDeltas[index]['function']['arguments'] ??= '';
                      toolCallDeltas[index]['function']['arguments'] +=
                          toolCallDelta['function']['arguments'];
                    }
                  }
                }
              }
            } else {
              finalMessage ??= {'role': 'assistant', 'content': ''};
              final deltaText = _extractDeltaText(json, chatPath);
              if (deltaText != null && deltaText.isNotEmpty) {
                finalMessage['content'] += deltaText;
                pushPartial(deltaText);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      _currentClient?.close();
      _currentClient = null;

      if (finalMessage == null) {
        throw Exception('No message received from stream');
      }

      final message = finalMessage;
      if (toolCallDeltas.isNotEmpty) {
        message['tool_calls'] = toolCallDeltas;
      }

      conversationMessages.add(message);

      final toolCallsFromMessage = message['tool_calls'];
      if (chatPath != '/chat/completions' ||
          toolCallsFromMessage == null ||
          toolCallsFromMessage.isEmpty) {
        final output = streamedOutput.toString();
        if (output.isNotEmpty) return output;
        return message['content'] ?? '';
      }

      for (var call in toolCallsFromMessage) {
        final functionName = call['function']['name'];
        final args = jsonDecode(call['function']['arguments'] ?? '{}');
        String result;

        try {
          final errorMessage = "Failed to call $functionName";
          switch (functionName) {
            case 'activeEditorFile':
              final res =
                  await _agenticTools?.activeEditorFile() ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data ?? 'No active file')
                  : (res.error ?? 'Error getting active file');
              break;
            case 'currentlySelectedText':
              final res =
                  await _agenticTools?.currentlySelectedText() ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'Start Line: ${res.data?['startLine'] ?? 'Unknown'}, End Line: ${res.data?['endLine'] ?? 'Unknown'}, Text: ${res.data?['selectedText'] ?? ''}'
                  : (res.error ?? 'Error getting selected text');
              break;
            case 'readFile':
              final res =
                  await _agenticTools?.readFile(
                    args['filePath'],
                    args['startLine'],
                    args['endLine'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data ?? 'No content')
                  : (res.error ?? 'Error reading file');
              break;
            case 'writeFile':
              String? previousContent;
              final previousRead = await _agenticTools?.readFile(
                args['filePath'],
              );
              if (previousRead != null && previousRead.success) {
                previousContent = previousRead.data;
              }

              final res =
                  await _agenticTools?.writeFile(
                    args['filePath'],
                    args['content'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'File written successfully'
                  : (res.error ?? 'Error writing file');
              if (res.success) {
                final added = _lineCount(args['content']?.toString());
                final removed = _lineCount(previousContent);
                pushPartial(
                  _toolEditMarker(
                    args['filePath']?.toString() ?? 'unknown',
                    added,
                    removed,
                  ),
                );
              }
              break;
            case 'deleteFile':
              final previousRead = await _agenticTools?.readFile(args['filePath']);
              final res =
                  await _agenticTools?.deleteFile(args['filePath']) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'File deleted successfully'
                  : (res.error ?? 'Error deleting file');
              if (res.success) {
                pushPartial(
                  _toolEditMarker(
                    args['filePath']?.toString() ?? 'unknown',
                    0,
                    _lineCount(previousRead?.data),
                  ),
                );
              }
              break;
            case 'renamePath':
              final res =
                  await _agenticTools?.renamePath(
                    args['oldPath'],
                    args['newPath'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'Path renamed successfully'
                  : (res.error ?? 'Error renaming path');
              break;
            case 'rename':
              final res =
                  await _agenticTools?.rename(
                    args['oldPath'],
                    args['newPath'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'Path renamed successfully'
                  : (res.error ?? 'Error renaming path');
              break;
            case 'insertAtLine':
              final res =
                  await _agenticTools?.insertAtLine(
                    args['filePath'],
                    args['line'],
                    args['text'],
                    position: args['position'] ?? 'before',
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'Text inserted successfully'
                  : (res.error ?? 'Error inserting text');
              if (res.success) {
                pushPartial(
                  _toolEditMarker(
                    args['filePath']?.toString() ?? 'unknown',
                    _lineCount(args['text']?.toString()),
                    0,
                  ),
                );
              }
              break;
            case 'replaceAllInFile':
              final res =
                  await _agenticTools?.replaceAllInFile(
                    args['filePath'],
                    args['oldText'],
                    args['newText'],
                    useRegex: args['useRegex'] ?? false,
                    maxReplacements: args['maxReplacements'],
                    caseSensitive: args['caseSensitive'] ?? true,
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? jsonEncode(res.data)
                  : (res.error ?? 'Error replacing text');
              if (res.success) {
                pushPartial(
                  _toolEditMarker(
                    args['filePath']?.toString() ?? 'unknown',
                    _lineCount(args['newText']?.toString()),
                    _lineCount(args['oldText']?.toString()),
                  ),
                );
              }
              break;
            case 'listFiles':
              final res =
                  await _agenticTools?.listFiles(
                    args['directoryPath'],
                    pattern: args['pattern'],
                    recursive: args['recursive'] ?? false,
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data?.join('\n') ?? 'No files')
                  : (res.error ?? 'Error listing files');
              break;
            case 'readFilesBatch':
              final parsedFiles = (args['files'] as List?) ?? const [];
              final res =
                  await _agenticTools?.readFilesBatch(parsedFiles) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? jsonEncode(res.data)
                  : (res.error ?? 'Error reading files batch');
              break;
            case 'globSearchFiles':
              final parsedExcludePatterns =
                  (args['excludePatterns'] as List?)
                      ?.map((item) => item.toString())
                      .toList();
              final res =
                  await _agenticTools?.globSearchFiles(
                    args['pattern'],
                    directoryPath: args['directoryPath'] ?? '.',
                    excludePatterns: parsedExcludePatterns,
                    recursive: args['recursive'] ?? true,
                    maxResults: args['maxResults'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data?.join('\n') ?? 'No matches')
                  : (res.error ?? 'Error searching files by glob');
              break;
            case 'searchInFiles':
              final res =
                  await _agenticTools?.searchInFiles(
                    args['query'],
                    filePattern: args['filePattern'],
                    caseSensitive: args['caseSensitive'] ?? false,
                    matchWholeWord: args['matchWholeWord'] ?? false,
                    useRegex: args['useRegex'] ?? false,
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data
                            ?.map(
                              (s) =>
                                  '${s.filePath}:${s.lineNumber}: ${s.lineContent}',
                            )
                            .join('\n') ??
                        'No results')
                  : (res.error ?? 'Error searching files');
              break;
            case 'grepInFiles':
              final res =
                  await _agenticTools?.grepInFiles(
                    args['query'],
                    filePattern: args['filePattern'],
                    caseSensitive: args['caseSensitive'] ?? false,
                    matchWholeWord: args['matchWholeWord'] ?? false,
                    useRegex: args['useRegex'] ?? false,
                    before: args['before'] ?? 2,
                    after: args['after'] ?? 2,
                    maxResults: args['maxResults'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data?.map((r) => r.toString()).join('\n') ?? 'No results')
                  : (res.error ?? 'Error grepping files');
              break;
            case 'editFile':
              final res =
                  await _agenticTools?.editFile(
                    args['filePath'],
                    args['oldText'],
                    args['newText'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'File edited successfully'
                  : (res.error ?? 'Error editing file');
              if (res.success) {
                final added = _lineCount(args['newText']?.toString());
                final removed = _lineCount(args['oldText']?.toString());
                pushPartial(
                  _toolEditMarker(
                    args['filePath']?.toString() ?? 'unknown',
                    added,
                    removed,
                  ),
                );
              }
              break;
            case 'getPendingEditsForFile':
              final res =
                  await _agenticTools?.getPendingEditsForFile(
                    args['filePath'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data == null
                        ? 'No pending edits'
                        : jsonEncode(res.data!.toJson()))
                  : (res.error ?? 'Error getting pending edits');
              break;
            case 'getFileInfo':
              final res =
                  await _agenticTools?.getFileInfo(args['filePath']) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? 'Path: ${res.data?.path ?? 'Unknown'}, Size: ${res.data?.size ?? 0}, Modified: ${res.data?.modified ?? 'Unknown'}, IsDirectory: ${res.data?.isDirectory ?? false}'
                  : (res.error ?? 'Error getting file info');
              break;
            case 'openLinks':
              final res =
                  await _agenticTools?.openLinks(args['url']) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data?.toString() ?? 'No content')
                  : (res.error ?? 'Error fetching web page');
              break;
            case 'searchInWeb':
              final res =
                  await _agenticTools?.searchInWeb(args['searchQuery']) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data
                            ?.map((w) => '${w.title}\n${w.url}\n${w.snippet}')
                            .join('\n---\n') ??
                        'No results')
                  : (res.error ?? 'Error searching web');
              break;
            case 'runShellCommand':
              final parsedArgs =
                  (args['args'] as List?)
                      ?.map((item) => item.toString())
                      .toList() ??
                  <String>[];
              final parsedEnvs =
                  (args['envs'] as Map?)?.map(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  ) ??
                  <String, String>{};
              final preview = _shellCommandPreview(
                args['command']?.toString() ?? '',
                parsedArgs,
              );
              pushPartial(_toolTerminalMarker(preview));
              final res =
                  await _agenticTools?.runShellCommand(
                    args['command'],
                    parsedArgs,
                    parsedEnvs,
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? jsonEncode(res.data)
                  : (res.error ?? 'Error running shell command');
              break;
            case 'gitStatus':
              final res =
                  await _agenticTools?.gitStatus() ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? jsonEncode(res.data?.toJson())
                  : (res.error ?? 'Error getting git status');
              break;
            case 'gitDiff':
              final res =
                  await _agenticTools?.gitDiff(
                    filePath: args['filePath'],
                    staged: args['staged'] ?? false,
                    contextLines: args['contextLines'] ?? 3,
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? (res.data ?? '')
                  : (res.error ?? 'Error getting git diff');
              break;
            case 'gitLog':
              final res =
                  await _agenticTools?.gitLog(
                    limit: args['limit'] ?? 20,
                    filePath: args['filePath'],
                  ) ??
                  ToolResult.error(errorMessage);
              result = res.success
                  ? jsonEncode(res.data?.map((c) => c.toJson()).toList() ?? [])
                  : (res.error ?? 'Error getting git log');
              break;
            default:
              result = 'Unknown tool: $functionName';
          }
        } catch (e) {
          result = 'Error executing tool $functionName: $e';
        }

        conversationMessages.add({
          'role': 'tool',
          'content': result,
          'tool_call_id': call['id'],
        });
      }
    }
  }

  void dispose() {
    _currentClient?.close();
    _conversationController.close();
  }
}

enum ChatMode { agent, ask }
