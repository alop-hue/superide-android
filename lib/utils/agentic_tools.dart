import 'dart:io';
import 'package:path/path.dart' as path;


class AgenticTools {
  final String workspacePath;

  AgenticTools({required this.workspacePath});
  
  Future<ToolResult<String>> readFile(String filePath) async {
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

      final content = await file.readAsString();
      return ToolResult.success(content);
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
            final lines = content.split('\n');
            
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i];
              final matches = caseSensitive
                  ? line.contains(query)
                  : line.toLowerCase().contains(query.toLowerCase());
              
              if (matches) {
                results.add(SearchResult(
                  filePath: relativePath,
                  lineNumber: i + 1,
                  lineContent: line.trim(),
                ));
              }
            }
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
      // Resolve relative paths relative to workspace
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

  
  List<Map<String, dynamic>> getTools({bool readAccessOnly = false}) {
    return [
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
          "description": "Searches for text content across files in workspace",
          "parameters": {
            "type": "object",
            "properties": {
              "query": {
                "type": "string",
                "description": "The text to search for"
              },
              "filePattern": {
                "type": "string",
                "description": "Optional glob pattern to filter files"
              },
              "caseSensitive": {
                "type": "boolean",
                "description": "Whether the search is case sensitive"
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
          "description": "Gets file/directory information",
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