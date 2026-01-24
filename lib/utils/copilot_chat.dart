import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:vsdroid/utils/copilot_lsp.dart';
import 'agentic_tools.dart';

class CopilotChat {
  final String authToken;
  final AgenticTools agenticTools;
  
  String? _conversationId;
  final CopilotAccountStatus _accountStatus = CopilotAccountStatus.signedIn;
  List<Map<String, dynamic>> _conversationMessages = [];
  final StreamController<Map<String, dynamic>> _conversationController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get conversationStream => _conversationController.stream;
  
  static Future<String?> loadAuthToken({bool preferGithubToken = true}) async {
    // First try to get GitHub OAuth token (gho_ prefix) for REST API
    try {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final githubToken = await storage.read(key: 'github_access_token');
      if (githubToken != null && githubToken.isNotEmpty && githubToken.startsWith('gho_')) {
        return githubToken;
      }
    } catch (e) {
      debugPrint('Failed to read GitHub token from secure storage: $e');
    }

    // Fall back to Copilot SDK token (ghu_ prefix) for LSP suggestions
    try {
      final file = File('/data/data/com.vsdroid/files/github-copilot/apps.json');
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final key = json.keys.firstWhere((k) => k.startsWith('github.com:'), orElse: () => '');
      if (key.isEmpty) {
        return null;
      }
      return json[key]['oauth_token'];
    } catch (e) {
      debugPrint('Failed to read token from apps.json: $e');
      return null;
    }
  }
  
  CopilotChat({required this.authToken, required this.agenticTools});

  Future<Map<String, dynamic>> getCopilotModels() async {
    final response = await http.get(
      Uri.parse('https://api.individual.githubcopilot.com/models'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
        'User-Agent': 'VSdroid/1.0.0',
      },
    );

    if (response.statusCode == 200) {
      return await jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch models: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> chatWithModel({
    required String model,
    required List<Map<String, dynamic>> messages,
    ChatMode chatMode = ChatMode.ask,
  }) async {
    final tools = chatMode == ChatMode.agent ? agenticTools.getTools() : [];
    final conversationMessages = List<Map<String, dynamic>>.from(messages);

    while (true) {
      final requestBody = {
        'model': model,
        'messages': conversationMessages,
        'stream': true,
      };

      if (tools.isNotEmpty) {
        requestBody['tools'] = tools;
      }

      final client = http.Client();
      final request = http.Request('POST', Uri.parse('https://api.individual.githubcopilot.com/chat/completions'));
      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'User-Agent': 'VSdroid/1.0.0',
      });
      request.body = jsonEncode(requestBody);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(body);
      }

      final lines = streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter());
      Map<String, dynamic>? finalMessage;
      List<Map<String, dynamic>> toolCallDeltas = [];

      await for (var line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];

            finalMessage ??= {'role': delta['role'] ?? 'assistant', 'content': ''};

            if (delta['content'] != null) {
              finalMessage['content'] += delta['content'];
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
                    toolCallDeltas[index]['function']['name'] = toolCallDelta['function']['name'];
                  }
                  if (toolCallDelta['function']['arguments'] != null) {
                    toolCallDeltas[index]['function']['arguments'] ??= '';
                    toolCallDeltas[index]['function']['arguments'] += toolCallDelta['function']['arguments'];
                  }
                }
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      client.close();

      if (finalMessage == null) {
        throw Exception('No message received from stream');
      }

      final message = finalMessage;
      if (toolCallDeltas.isNotEmpty) {
        message['tool_calls'] = toolCallDeltas;
      }

      conversationMessages.add(message);

      final toolCallsFromMessage = message['tool_calls'];
      if (toolCallsFromMessage == null || toolCallsFromMessage.isEmpty) {
        return message['content'] ?? '';
      }

      for (var call in toolCallsFromMessage) {
        final functionName = call['function']['name'];
        final args = jsonDecode(call['function']['arguments'] ?? '{}');
        String result;

        try {
          switch (functionName) {
            case 'readFile':
              final res = await agenticTools.readFile(args['filePath']);
              result = res.success ? (res.data ?? 'No content') : (res.error ?? 'Error reading file');
              break;
            case 'writeFile':
              final res = await agenticTools.writeFile(args['filePath'], args['content']);
              result = res.success ? 'File written successfully' : (res.error ?? 'Error writing file');
              break;
            case 'listFiles':
              final res = await agenticTools.listFiles(
                args['directoryPath'],
                pattern: args['pattern'],
                recursive: args['recursive'] ?? false,
              );
              result = res.success ? (res.data?.join('\n') ?? 'No files') : (res.error ?? 'Error listing files');
              break;
            case 'searchInFiles':
              final res = await agenticTools.searchInFiles(
                args['query'],
                filePattern: args['filePattern'],
                caseSensitive: args['caseSensitive'] ?? false,
              );
              result = res.success
                  ? (res.data?.map((s) => '${s.filePath}:${s.lineNumber}: ${s.lineContent}').join('\n') ?? 'No results')
                  : (res.error ?? 'Error searching files');
              break;
            case 'editFile':
              final res = await agenticTools.editFile(args['filePath'], args['oldText'], args['newText']);
              result = res.success ? 'File edited successfully' : (res.error ?? 'Error editing file');
              break;
            case 'getFileInfo':
              final res = await agenticTools.getFileInfo(args['filePath']);
              result = res.success
                  ? 'Path: ${res.data?.path ?? 'Unknown'}, Size: ${res.data?.size ?? 0}, Modified: ${res.data?.modified ?? 'Unknown'}, IsDirectory: ${res.data?.isDirectory ?? false}'
                  : (res.error ?? 'Error getting file info');
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

  Future<String?> createConversation({
    required String initialMessage,
    String? filePath,
    String? content,
    String? languageId,
    int? line,
    int? character,
  }) async {
    if (_accountStatus != CopilotAccountStatus.signedIn) {
      return null;
    }
    
    _conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    _conversationMessages = [{'role': 'user', 'content': initialMessage}];
    
    Future(() async {
      try {
        final response = await chatWithModel(
          model: 'gpt-4o', 
          messages: _conversationMessages,
          chatMode: ChatMode.agent,
        );
        _conversationMessages.add({'role': 'assistant', 'content': response});
        _conversationController.add({
          'type': 'conversationEntry',
          'data': {
            'conversationId': _conversationId,
            'reply': response,
            'references': [],
            'hideText': false,
          }
        });
      } catch (e) {
        _conversationController.add({
          'type': 'error',
          'data': {'message': e.toString()}
        });
      }
    });
    
    return _conversationId;
  }

  Future<void> conversationTurn({
    required String message,
    String? filePath,
    String? content,
    String? languageId,
    int? line,
    int? character,
  }) async {
    if (_conversationId == null || _accountStatus != CopilotAccountStatus.signedIn) {
      return;
    }
    
    _conversationMessages.add({'role': 'user', 'content': message});
    
    // Continue the conversation
    Future(() async {
      try {
        final response = await chatWithModel(
          model: 'gpt-4o',
          messages: _conversationMessages,
          chatMode: ChatMode.agent,
        );
        _conversationMessages.add({'role': 'assistant', 'content': response});
        _conversationController.add({
          'type': 'conversationEntry',
          'data': {
            'conversationId': _conversationId,
            'reply': response,
            'references': [],
            'hideText': false,
          }
        });
      } catch (e) {
        _conversationController.add({
          'type': 'error',
          'data': {'message': e.toString()}
        });
      }
    });
  }

  Future<void> destroyConversation() async {
    if (_conversationId == null) return;
    
    _conversationId = null;
    _conversationMessages.clear();
  }

  Future<void> rateConversation({
    required String turnId,
    required int rating,
  }) async {
  }

  void dispose() {
    _conversationController.close();
  }
}

enum ChatMode {
  agent,
  ask
}