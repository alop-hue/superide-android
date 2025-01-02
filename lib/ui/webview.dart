import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
/* import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart'; */

InAppLocalhostServer? localServer;

class WebView extends StatefulWidget {
  final Directory dirPath;
  const WebView({super.key, required this.dirPath});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  late InAppWebViewController controller;

Future<void> startServer() async {
  /* final content = widget.dirPath.listSync();
  List<File> htmlFiles = [];
  List<File> cssFiles = [];
  List<File> jsFiles = [];

  // Iterate through files and categorize them
  for (var file in content) {
    if (file is File) {
      final filePath = file.path;
      if (filePath.endsWith('.html')) {
        htmlFiles.add(file);
      } else if (filePath.endsWith('.css')) {
        cssFiles.add(file);
      } else if (filePath.endsWith('.js')) {
        jsFiles.add(file);
      }
    }
  }

  final cacheDir = await getApplicationCacheDirectory();
  await cacheDir.create(recursive: true);

  for (var htmlFile in htmlFiles) {
    String htmlContent = await htmlFile.readAsString();

    String cssLinks = '';
    for (var cssFile in cssFiles) {
      if (cssFile.existsSync()) {
        String fileName = basename(cssFile.path);
        cssLinks += '<link rel="stylesheet" href="$fileName">\n';
      }
    }

    int headEndIndex = htmlContent.indexOf('</head>');
    if (headEndIndex != -1) {
      htmlContent = htmlContent.substring(0, headEndIndex) + cssLinks + htmlContent.substring(headEndIndex);
    }

    String jsScripts = '';
    for (var jsFile in jsFiles) {
      if (jsFile.existsSync()) {
        String fileName = basename(jsFile.path);
        jsScripts += '<script src="$fileName"></script>\n';
      }
    }

    int bodyEndIndex = htmlContent.indexOf('</body>');
    if (bodyEndIndex != -1) {
      htmlContent = htmlContent.substring(0, bodyEndIndex) + jsScripts + htmlContent.substring(bodyEndIndex);
    }

    String targetHtmlPath = '${cacheDir.path}/${basename(htmlFile.path)}';
    File targetHtml = File(targetHtmlPath);
    await targetHtml.create(recursive: true);
    await targetHtml.writeAsString(htmlContent);
  }

  for (var cssFile in cssFiles) {
    if (cssFile.existsSync()) {
      String fileName = basename(cssFile.path);
      await cssFile.copy('${cacheDir.path}/$fileName');
    }
  }

  for (var jsFile in jsFiles) {
    if (jsFile.existsSync()) {
      String fileName = basename(jsFile.path);
      await jsFile.copy('${cacheDir.path}/$fileName');
    }
  }
 */
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 5285);

  await for (HttpRequest request in server) {
    String requestedPath = request.uri.path.isEmpty ? '/index.html' : request.uri.path;
    File fileToServe = File('${widget.dirPath.path}$requestedPath');

    if (await fileToServe.exists()) {
      if (requestedPath.endsWith('.html')) {
        request.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
      } else if (requestedPath.endsWith('.css')) {
        request.response.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
      } else if (requestedPath.endsWith('.js')) {
        request.response.headers.contentType = ContentType('application', 'javascript', charset: 'utf-8');
      }

      await request.response.addStream(fileToServe.openRead());
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 Not Found');
    }
    await request.response.close();
  }
}


  @override
  void initState() {
    super.initState();
    startServer();
  }

  @override
  void dispose() {
    controller.clearHistory();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView',style: TextStyle(color: Colors.white)),
      ),
      body: InAppWebView(
        initialSettings: InAppWebViewSettings(
          cacheEnabled: false,
          clearCache: true,
          clearSessionCache: true
        ),
        initialUrlRequest: URLRequest(url: WebUri("http://localhost:5285/index.html")),
        onWebViewCreated: (InAppWebViewController webViewController) {
          controller = webViewController;
        },
        onLoadStart: (controller, url) {
          
        },
      ),
    );
  }
}