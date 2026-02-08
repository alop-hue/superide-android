import 'dart:async';
import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:vsdroid/bloc/ui_bloc/ui_bloc.dart';
import 'package:vsdroid/utils/functions.dart';


class AgenticTools {
  final BuildContext context;
  final String workspacePath;

  AgenticTools({
    required this.workspacePath,
    required this.context,
  }): _activeEditor = context.read<ActiveEditorBloc>().state.activeEditors.singleWhere((editor) => editor.isActive);

  late final ActiveEditor _activeEditor;
  
  Future<ToolResult<String>> activeEditorFile() async{
    try {
      return ToolResult.success(_activeEditor.file.path);
    } catch (e) {
        return ToolResult.error("An error occured: ${e.toString()}");
    }
  }

  Future<ToolResult<Map<String, dynamic>>> currentlySelectedText() async{
    try {
      final controller = _activeEditor.controller;
      final selStart = controller.getLineAtOffset(controller.selection.baseOffset);
      final selEnd = controller.getLineAtOffset(controller.selection.extentOffset);
      return ToolResult.success({
        "startLine": selStart,
        "endLine": selEnd,
        "selectedText": controller.text.substring(controller.selection.baseOffset, controller.selection.extentOffset)
      });
    } catch (e) {
      return ToolResult.error("An error occured: ${e.toString()}");
    }
  }

  Future<ToolResult<String>> readFile(String filePath, [int? startLine, int? endLine]) async {
    try {
      String resolvedPath = filePath;
      if (!path.isAbsolute(filePath)) {
        resolvedPath = path.join(workspacePath, filePath);
      }
      
      final file = File(resolvedPath);
      final canonicalPath = file.absolute.path;
      final canonicalWorkspace = Directory(workspacePath).absolute.path;
      
      if (!path.isWithin(canonicalWorkspace, canonicalPath)) {
        return ToolResult.error(
          'Permission denied: File is outside the workspace\n'
          'Workspace: $workspacePath\n'
          'Requested file: $filePath\n'
        );
      }

      if (!await file.exists()) {
        return ToolResult.error('File not found: $filePath');
      }

      if(startLine == null && endLine == null){
        final content = await file.readAsString();
        return ToolResult.success(content);
      }

      final controller = CodeForgeController()..text = await file.readAsString();
      final startLineIndex = controller.getLineStartOffset(startLine ?? 0);
      final endLineIndex = controller.getLineStartOffset(endLine ?? controller.lineCount - 1);
      return ToolResult.success(controller.text.substring(startLineIndex, endLineIndex));

    } catch (e) {
      return ToolResult.error('Error reading file: $e');
    }
  }

  
  Future<ToolResult<void>> writeFile(String filePath, String content) async {
    try {
      String resolvedPath = filePath;
      if (!path.isAbsolute(filePath)) {
        resolvedPath = path.join(workspacePath, filePath);
      }
      
      final file = File(resolvedPath);
      final canonicalPath = file.absolute.path;
      final canonicalWorkspace = Directory(workspacePath).absolute.path;
      
      if (!path.isWithin(canonicalWorkspace, canonicalPath)) {
        return ToolResult.error(
          'Permission denied: File is outside the workspace\n'
          'Workspace: $workspacePath\n'
          'Requested file: $filePath\n'
        );
      }
        await file.parent.create(recursive: true);
        await file.writeAsString(content);

        if (filePath == _activeEditor.file.path){
          _activeEditor.controller.refetchFile();
        }
      
      return ToolResult.success(null);
    } catch (e) {
      return ToolResult.error('Error writing file: $e');
    }
  }

  
  Future<ToolResult<List<String>>> listFiles(
    String directoryPath, {
    String? pattern,
    bool recursive = false,
  }) async {
    try {
      String resolvedPath = directoryPath;
      if (!path.isAbsolute(directoryPath)) {
        resolvedPath = path.join(workspacePath, directoryPath);
      }
      
      final dir = Directory(resolvedPath);
      final canonicalPath = dir.absolute.path;
      final canonicalWorkspace = Directory(workspacePath).absolute.path;
      
      if (!path.isWithin(canonicalWorkspace, canonicalPath) &&
          canonicalPath != canonicalWorkspace) {
        return ToolResult.error(
          'Permission denied: File is outside the workspace\n'
          'Workspace: $canonicalWorkspace\n'
          'Path tried to access: $canonicalPath\n'
        );
      }

      if (!await dir.exists()) {
        return ToolResult.error('Directory not found: $directoryPath');
      }

      final entities = await dir.list(recursive: recursive).toList();
      final files = entities
          .whereType<File>()
          .map((f) => path.relative(f.path, from: workspacePath))
          .toList();

      
      if (pattern != null) {
        final regex = _globToRegex(pattern);
        return ToolResult.success(
          files.where((f) => regex.hasMatch(f)).toList(),
        );
      }

      return ToolResult.success(files);
    } catch (e) {
      return ToolResult.error('Error listing files: $e');
    }
  }

  Future<ToolResult<List<SearchResult>>> searchInFiles(
    String query, {
    String? filePattern,
    bool caseSensitive = false,
    bool matchWholeWord = false,
    bool useRegex = false,
  }) async {
    try {
      final results = <SearchResult>[];
      final dir = Directory(workspacePath);
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: workspacePath);
          
          if (filePattern != null) {
            final regex = _globToRegex(filePattern);
            if (!regex.hasMatch(relativePath)) continue;
          }

          try {
            final content = await entity.readAsString();
            
            final controller = CodeForgeController()..text = content;

            String pattern;
            if (useRegex) {
              pattern = query;
            } else {
              pattern = RegExp.escape(query);
            }
            if (matchWholeWord) {
              pattern = r'\b' + pattern + r'\b';
            }

            final regex = RegExp(pattern, caseSensitive: caseSensitive);
            final matches = regex.allMatches(content);

            if (matches.isNotEmpty) {
              final lines = content.split('\n');
              final processedLines = <int>{};
              
              for (final match in matches) {
                final lineNumber = controller.getLineAtOffset(match.start);
                
                if (!processedLines.contains(lineNumber)) {
                  processedLines.add(lineNumber);
                  
                  if (lineNumber < lines.length) {
                    results.add(SearchResult(
                      filePath: relativePath,
                      lineNumber: lineNumber + 1,
                      lineContent: lines[lineNumber].trim(),
                    ));
                  }
                }
              }
            }
            
            controller.dispose();
          } catch (e) {
            continue;
          }
        }
      }
      
      return ToolResult.success(results);
    } catch (e) {
      return ToolResult.error('Error searching files: $e');
    }
  }

  
  Future<ToolResult<void>> editFile(
    String filePath,
    String oldText,
    String newText,
  ) async {
    try {
      final readResult = await readFile(filePath);
      if (!readResult.success) {
        return ToolResult.error(readResult.error ?? 'Error reading file');
      }

      final content = readResult.data ?? '';
      if (!content.contains(oldText)) {
        return ToolResult.error(
          'Old text not found in file. This may be due to the file being modified.',
        );
      }

      final newContent = content.replaceFirst(oldText, newText);
      return await writeFile(filePath, newContent);
    } catch (e) {
      return ToolResult.error('Error editing file: $e');
    }
  }

  
  Future<ToolResult<FileInfo>> getFileInfo(String filePath) async {
    try {
      String resolvedPath = filePath;
      if (!path.isAbsolute(filePath)) {
        resolvedPath = path.join(workspacePath, filePath);
      }
      
      final file = File(resolvedPath);
      final canonicalPath = file.absolute.path;
      final canonicalWorkspace = Directory(workspacePath).absolute.path;
      
      if (!path.isWithin(canonicalWorkspace, canonicalPath)) {
        return ToolResult.error('Permission denied: Path is outside workspace');
      }

      final stat = await file.stat();
      
      return ToolResult.success(FileInfo(
        path: path.relative(resolvedPath, from: workspacePath),
        size: stat.size,
        modified: stat.modified,
        isDirectory: stat.type == FileSystemEntityType.directory,
      ));
    } catch (e) {
      return ToolResult.error('Error getting file info: $e');
    }
  }

  Future<ToolResult<WebPageContent>> openLinks(String url) async {
    final completer = Completer<String>();
    late HeadlessInAppWebView headless;
    Timer? timeoutTimer;
    bool isProcessing = false;
    bool isDisposed = false;

    timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        completer.complete("");
        if (!isDisposed) {
          isDisposed = true;
          headless.dispose();
        }
      }
    });

    headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        cacheEnabled: false,
        clearCache: true,
        userAgent:
            "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120 Safari/537.36",
      ),
      onLoadStop: (controller, _) async {
        if (isProcessing || completer.isCompleted || isDisposed) {
          return;
        }
        
        isProcessing = true;

        try {
          await controller.evaluateJavascript(source: """
            (async () => {
              const start = Date.now();
              const timeout = 10000;
              while (Date.now() - start < timeout) {
                if (
                  document.querySelector("main") ||
                  document.querySelector("article") ||
                  document.readyState === 'complete' && document.body.innerText.length > 1000
                ) {
                  return true;
                }
                await new Promise(r => setTimeout(r, 200));
              }
              return false;
            })();
          """);

          if (isDisposed) return;
          await Future.delayed(const Duration(milliseconds: 500));
          if (isDisposed) return;

          final html = await controller.evaluateJavascript(
            source: "document.documentElement.outerHTML;",
          );

          if (!completer.isCompleted && !isDisposed) {
            completer.complete(html?.toString() ?? "");
            timeoutTimer?.cancel();
            isDisposed = true;
            await headless.dispose();
          }
        } catch (e) {
          if (!completer.isCompleted && !isDisposed) {
            completer.complete("");
            timeoutTimer?.cancel();
            isDisposed = true;
            await headless.dispose();
          }
        } finally {
          isProcessing = false;
        }
      },
    );

    await headless.run();
    
    try {
      final htmlString = await completer.future;
      
      if (htmlString.isEmpty) {
        return ToolResult.error("Failed to fetch content");
      }

      final parsed = _parseWebContent(htmlString, url);
      return ToolResult.success(parsed);
    } finally {
      timeoutTimer.cancel();
      if (!isDisposed) {
        isDisposed = true;
        await headless.dispose();
      }
    }
  }

  WebPageContent _parseWebContent(String htmlString, String url) {
    final document = html.parse(htmlString);
    final title = _extractTitle(document);
    final description = _extractDescription(document);
    final metadata = _extractMetadata(document);
    final headings = _extractHeadings(document);
    final mainContent = _extractMainContent(document);
    final links = _extractLinks(document, url);
    
    return WebPageContent(
      url: url,
      title: title,
      description: description,
      mainContent: mainContent,
      headings: headings,
      links: links,
      metadata: metadata,
    );
  }

  String _extractTitle(dom.Document document) {
    return document.querySelector('title')?.text.trim() ?? 
      document.querySelector('meta[property="og:title"]')?.attributes['content']?.trim() ??
      document.querySelector('h1')?.text.trim() ?? 
      'Untitled Page';
  }

  String? _extractDescription(dom.Document document) {
    return document.querySelector('meta[name="description"]')?.attributes['content']?.trim() ??
      document.querySelector('meta[property="og:description"]')?.attributes['content']?.trim() ??
      document.querySelector('meta[name="twitter:description"]')?.attributes['content']?.trim();
  }

  Map<String, String> _extractMetadata(dom.Document document) {
    final metadata = <String, String>{};
    final author = document.querySelector('meta[name="author"]')?.attributes['content']?.trim() ??
      document.querySelector('meta[property="article:author"]')?.attributes['content']?.trim() ??
      document.querySelector('[rel="author"]')?.text.trim();
    if (author != null && author.isNotEmpty) metadata['author'] = author;
    
    final publishedTime = document.querySelector('meta[property="article:published_time"]')?.attributes['content']?.trim() ??
      document.querySelector('time[datetime]')?.attributes['datetime']?.trim();
    if (publishedTime != null && publishedTime.isNotEmpty) metadata['published'] = publishedTime;
    
    final siteName = document.querySelector('meta[property="og:site_name"]')?.attributes['content']?.trim();
    if (siteName != null && siteName.isNotEmpty) metadata['site_name'] = siteName;
    
    final type = document.querySelector('meta[property="og:type"]')?.attributes['content']?.trim();
    if (type != null && type.isNotEmpty) metadata['type'] = type;
    
    final lang = document.documentElement?.attributes['lang']?.trim();
    if (lang != null && lang.isNotEmpty) metadata['language'] = lang;
    
    return metadata;
  }

  List<String> _extractHeadings(dom.Document document) {
    final headings = <String>[];
    
    for (final tag in ['h1', 'h2', 'h3']) {
      final elements = document.querySelectorAll(tag);
      for (final el in elements) {
        final text = _cleanText(el.text);
        if (text.isNotEmpty && text.length < 200 && !text.contains('\n')) {
          headings.add(text);
        }
      }
    }
    
    return headings;
  }

  String _extractMainContent(dom.Document document) {
    dom.Element? mainContent;
    
    final semanticSelectors = [
      'main',
      'article',
      '[role="main"]',
      '[role="article"]',
    ];
    
    for (final selector in semanticSelectors) {
      mainContent = document.querySelector(selector);
      if (mainContent != null) break;
    }
    
    if (mainContent == null) {
      final commonSelectors = [
        '.post-content',
        '.article-content',
        '.entry-content',
        '.content',
        '#content',
        '.main-content',
        '#main-content',
        '.post-body',
        '.article-body',
      ];
      
      for (final selector in commonSelectors) {
        mainContent = document.querySelector(selector);
        if (mainContent != null && mainContent.text.trim().length > 100) break;
      }
    }
    
    if (mainContent == null) {
      final candidates = document.querySelectorAll('div, section, article');
      dom.Element? bestCandidate;
      int maxLength = 0;
      
      for (final candidate in candidates) {
        final clone = candidate.clone(true);
        _removeUnwantedElements(clone);
        
        final textLength = clone.text.trim().length;
        if (textLength > maxLength && textLength > 200) {
          maxLength = textLength;
          bestCandidate = candidate;
        }
      }
      
      mainContent = bestCandidate;
    }
    
    mainContent ??= document.body;
    
    if (mainContent != null) {
      final clone = mainContent.clone(true);
      _removeUnwantedElements(clone);
      return _cleanText(clone.text);
    }
    
    return '';
  }

  void _removeUnwantedElements(dom.Element element) {
    final unwantedSelectors = [
      'script',
      'style',
      'noscript',
      'iframe',
      'nav',
      'header',
      'footer',
      'aside',
      '.advertisement',
      '.ad',
      '.ads',
      '.social-share',
      '.comments',
      '.comment-section',
      '[role="navigation"]',
      '[role="banner"]',
      '[role="contentinfo"]',
      '[role="complementary"]',
      '.sidebar',
      '.menu',
      '.nav',
      '.navigation',
    ];
    
    for (final selector in unwantedSelectors) {
      element.querySelectorAll(selector).forEach((el) => el.remove());
    }
  }

  List<LinkInfo> _extractLinks(dom.Document document, String baseUrl) {
    final links = <LinkInfo>[];
    final seenUrls = <String>{};
    
    dom.Element? contentArea;
    for (final selector in ['main', 'article', '.content', '#content']) {
      contentArea = document.querySelector(selector);
      if (contentArea != null) break;
    }
    
    final searchArea = contentArea ?? document.body;
    if (searchArea == null) return links;
    
    final anchorElements = searchArea.querySelectorAll('a[href]');
    
    for (final anchor in anchorElements) {
      final href = anchor.attributes['href'];
      final text = _cleanText(anchor.text);
      
      if (href == null || href.isEmpty || text.isEmpty) continue;
      if (text.length > 100) continue;
      
      final absoluteUrl = _resolveUrl(href, baseUrl);
      
      if (seenUrls.contains(absoluteUrl)) continue;
      if (absoluteUrl.startsWith('#')) continue;
      if (absoluteUrl.startsWith('javascript:')) continue;
      if (absoluteUrl.startsWith('mailto:')) continue;
      
      seenUrls.add(absoluteUrl);
      links.add(LinkInfo(text: text, url: absoluteUrl));
      
      if (links.length >= 50) break;
    }
    
    return links;
  }

  String _resolveUrl(String href, String baseUrl) {
    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(href);
      return resolved.toString();
    } catch (e) {
      return href;
    }
  }

  String _cleanText(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }

  Future<ToolResult<List<WebResult>>> searchInWeb(String searchQuery) async {
    final url = "https://duckduckgo.com/html/?q=$searchQuery";
    final response = await http.get(Uri.parse(url));  
    final document = html.parse(response.body);
    final results = <WebResult>[];
    final resultDivs = document.querySelectorAll('.result');

    for (final div in resultDivs) {
      final titleAnchor = div.querySelector('.result__a');
      final snippetEl = div.querySelector('.result__snippet');
      final urlAnchor = div.querySelector('.result__url');

      if (titleAnchor == null || urlAnchor == null) continue;

      final title = titleAnchor.text.trim();
      final snippet = snippetEl?.text.trim() ?? '';
      final rawHref = urlAnchor.attributes['href'];
      final realUrl = ((){
        if (rawHref == null) return null;
        final fullUrl = rawHref.startsWith('//')
            ? 'https:$rawHref'
            : rawHref;

        final uri = Uri.parse(fullUrl);

        final uddg = uri.queryParameters['uddg'];
        if (uddg == null) return null;

        return Uri.decodeComponent(uddg);
      })();

      if (realUrl == null) continue;

      results.add(WebResult(
        title: title,
        url: realUrl,
        snippet: snippet,
      ));
    }

    return ToolResult.success(results);
  }
  
  List<Map<String, dynamic>> getTools({bool readAccessOnly = false}) {
    return [
      {
        "type": "function",
        "function": {
          "name": "activeEditorFile",
          "description": "Gets the path of the currently active/opened editor file",
          "parameters": {
            "type": "object",
            "properties": {}
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "currentlySelectedText",
          "description": "Gets the currently selected text in the active/opened editor",
          "parameters": {
            "type": "object",
            "properties": {}
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "readFile",
          "description": "Reads the contents of a file",
          "parameters": {
            "type": "object",
            "properties": {
              "filePath": {
                "type": "string",
                "description": "The path to the file to read"
              },
              "startLine": {
                "type": "integer",
                "description": "Optional start line number (1-indexed)"
              },
              "endLine": {
                "type": "integer",
                "description": "Optional end line number (1-indexed)"
              }
            },
            "required": ["filePath"]
          }
        }
      },
      if(!readAccessOnly) {
        "type": "function",
        "function": {
          "name": "writeFile",
          "description": "Writes content to a file, creating it if it doesn't exist",
          "parameters": {
            "type": "object",
            "properties": {
              "filePath": {
                "type": "string",
                "description": "The path to the file to write"
              },
              "content": {
                "type": "string",
                "description": "The content to write to the file"
              }
            },
            "required": ["filePath", "content"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "listFiles",
          "description": "Lists files in a directory with optional glob pattern",
          "parameters": {
            "type": "object",
            "properties": {
              "directoryPath": {
                "type": "string",
                "description": "The path to the directory to list"
              },
              "pattern": {
                "type": "string",
                "description": "Optional glob pattern to filter files"
              },
              "recursive": {
                "type": "boolean",
                "description": "Whether to list files recursively"
              }
            },
            "required": ["directoryPath"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "searchInFiles",
          "description": "Searches for text content across files in workspace with advanced search options",
          "parameters": {
            "type": "object",
            "properties": {
              "query": {
                "type": "string",
                "description": "The text to search for (can be a regex pattern if useRegex is true)"
              },
              "filePattern": {
                "type": "string",
                "description": "Optional glob pattern to filter files"
              },
              "caseSensitive": {
                "type": "boolean",
                "description": "Whether the search is case sensitive"
              },
              "matchWholeWord": {
                "type": "boolean",
                "description": "Whether to match whole words only"
              },
              "useRegex": {
                "type": "boolean",
                "description": "Whether to treat the query as a regular expression"
              }
            },
            "required": ["query"]
          }
        }
      },
      if(!readAccessOnly){
        "type": "function",
        "function": {
          "name": "editFile",
          "description": "Applies a diff/patch to a file",
          "parameters": {
            "type": "object",
            "properties": {
              "filePath": {
                "type": "string",
                "description": "The path to the file to edit"
              },
              "oldText": {
                "type": "string",
                "description": "The text to replace"
              },
              "newText": {
                "type": "string",
                "description": "The new text to insert"
              }
            },
            "required": ["filePath", "oldText", "newText"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "getFileInfo",
          "description": "Gets file/directory information including size and modification time",
          "parameters": {
            "type": "object",
            "properties": {
              "filePath": {
                "type": "string",
                "description": "The path to the file or directory"
              }
            },
            "required": ["filePath"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "openLinks",
          "description": "Fetches and parses web page content with structured information extraction",
          "parameters": {
            "type": "object",
            "properties": {
              "url": {
                "type": "string",
                "description": "The URL to fetch and parse"
              }
            },
            "required": ["url"]
          }
        }
      },
      {
        "type": "function",
        "function": {
          "name": "searchInWeb",
          "description": "Searches the web using DuckDuckGo and returns results with title, URL, and snippet",
          "parameters": {
            "type": "object",
            "properties": {
              "searchQuery": {
                "type": "string",
                "description": "The search query to use"
              }
            },
            "required": ["searchQuery"]
          }
        }
      }
    ];
  }
  
  RegExp _globToRegex(String glob) {
    String pattern = glob
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');
    return RegExp('^$pattern\$');
  }
}

class ToolResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ToolResult.success(this.data)
      : success = true,
        error = null;

  ToolResult.error(this.error)
      : success = false,
        data = null;
}


class SearchResult {
  final String filePath;
  final int lineNumber;
  final String lineContent;

  SearchResult({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
  });

  Map<String, dynamic> toJson() => {
    "filePath": filePath,
    "lineNumber": lineNumber,
    "lineContent": lineContent,
  };

  @override
  String toString() {
    return toJson().toString();
  }
}

class WebResult {
  final String title;
  final String url;
  final String snippet;

  WebResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  Map<String, dynamic> toJson() => {
    "title": title,
    "url": url,
    "snippet": snippet,
  };

  @override
  String toString() {
    return toJson().toString();
  }
}

class FileInfo {
  final String path;
  final int size;
  final DateTime modified;
  final bool isDirectory;

  FileInfo({
    required this.path,
    required this.size,
    required this.modified,
    required this.isDirectory,
  });
}

class WebPageContent {
  final String url;
  final String title;
  final String? description;
  final String mainContent;
  final List<String> headings;
  final List<LinkInfo> links;
  final Map<String, String> metadata;
  
  WebPageContent({
    required this.url,
    required this.title,
    this.description,
    required this.mainContent,
    required this.headings,
    required this.links,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    if (description != null) 'description': description,
    'content': mainContent,
    'headings': headings,
    'links': links.map((l) => l.toJson()).toList(),
    'metadata': metadata,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Title: $title');
    buffer.writeln('URL: $url');
    if (description != null) buffer.writeln('Description: $description');
    
    if (metadata.isNotEmpty) {
      buffer.writeln('\nMetadata:');
      metadata.forEach((key, value) {
        if (value.isNotEmpty) buffer.writeln('  $key: $value');
      });
    }
    
    if (headings.isNotEmpty) {
      buffer.writeln('\nHeadings:');
      for (final heading in headings.take(10)) {
        buffer.writeln('  - $heading');
      }
    }
    
    if (links.isNotEmpty) {
      buffer.writeln('\nImportant Links (${links.length}):');
      for (final link in links.take(10)) {
        buffer.writeln('  - ${link.text}: ${link.url}');
      }
    }
    
    buffer.writeln('\nContent:');
    buffer.writeln(mainContent);
    
    return buffer.toString();
  }
}

class LinkInfo {
  final String text;
  final String url;
  
  LinkInfo({required this.text, required this.url});
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'url': url,
  };
}