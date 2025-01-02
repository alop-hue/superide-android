import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 5285);

  await for (HttpRequest request in server) {
    String requestedPath = request.uri.path.isEmpty ? '/index.html' : request.uri.path;
    File fileToServe = File('${widget.dirPath.path}$requestedPath');

    if (await fileToServe.exists()) {
      if (requestedPath.endsWith('.html')) {
        /* String htmlContent = await fileToServe.readAsString();
        final appDir = await getApplicationSupportDirectory();
        int bodyEndIndex = htmlContent.indexOf('</body>');
        if (bodyEndIndex != -1) {
          htmlContent = '${htmlContent.substring(0, bodyEndIndex)}<script src="https://cdn.jsdelivr.net/npm/eruda"></script><script>eruda.init();</script>${htmlContent.substring(bodyEndIndex)}';
        } */
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
              allowFileAccess: true,
              allowContentAccess: true,
              cacheEnabled: false,
              clearCache: true,
              clearSessionCache: true
            ),
            initialUrlRequest: URLRequest(url: WebUri("http://localhost:5285/index.html")),
            onWebViewCreated: (InAppWebViewController webViewController) {
              controller = webViewController;
            },
            onLoadStart: (controller, url) async{
              await controller.injectJavascriptFileFromAsset(assetFilePath: "assets/webview/eruda.js");
              await controller.evaluateJavascript(source: "eruda.init();");
            },
          ),
        );
  }
}