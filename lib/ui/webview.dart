import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';

InAppLocalhostServer? localServer;

class WebView extends StatefulWidget {
  final Directory dirPath;
  const WebView({super.key, required this.dirPath});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  late  InAppWebViewController controller;
  bool isLoaded = false;

  Future<void> startServer() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 5285);

    await for (HttpRequest request in server) {
      String requestedPath =
          request.uri.path.isEmpty ? '/index.html' : request.uri.path;
      File fileToServe = File('${widget.dirPath.path}$requestedPath');

      if (await fileToServe.exists()) {
        if (requestedPath.endsWith('.html')) {
          request.response.headers.contentType =
              ContentType('text', 'html', charset: 'utf-8');
        } else if (requestedPath.endsWith('.css')) {
          request.response.headers.contentType =
              ContentType('text', 'css', charset: 'utf-8');
        } else if (requestedPath.endsWith('.js')) {
          request.response.headers.contentType =
              ContentType('application', 'javascript', charset: 'utf-8');
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
  Widget build(BuildContext context) {
    return BlocBuilder<WebViewBloc, WebViewState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton(
                tooltip: "Options",
                popUpAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 100)),
                itemBuilder:(context) => [
                  PopupMenuItem(
                    child: ListTile(
                      splashColor: Colors.transparent,
                      onTap: ()async{
                        if(isLoaded) {
                          context.read<WebViewBloc>().add(SetViewPort(isMobile: !state.isMobile));
                          await controller.callAsyncJavaScript(
                            functionBody: """
                              if (window.setViewport) {
                                window.setViewport(isMobile);
                              } else {
                                console.error('setViewport is not defined');
                              }
                            """,
                            arguments: {"isMobile":!state.isMobile},
                          );
                          if(context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      contentPadding: const EdgeInsets.all(0),
                      title: const Text("Desktop"),
                      titleTextStyle: const TextStyle(color: Colors.grey,fontSize: 18),
                      leading: const Icon(Icons.desktop_mac_sharp,color: Colors.grey,size: 30),
                      trailing: Checkbox(
                        fillColor:  WidgetStatePropertyAll(!state.isMobile? const Color(0xff0e639c):Colors.transparent),
                        side: const BorderSide(color: Colors.grey),
                        value: !state.isMobile,
                        onChanged:null),
                    ),
                   ),
                   PopupMenuItem(
                    child: ListTile(
                      splashColor: Colors.transparent,
                      contentPadding: const EdgeInsets.all(0),
                      onTap: ()async {
                        if (isLoaded) {
                          context.read<WebViewBloc>().add(EnableConsole(isConsole: !state.isConsole));
                          await controller.evaluateJavascript(source:
                            """
                          if (window.setEruda) {
                            window.setEruda(${!state.isConsole});
                            } else {
                              console.error('setEruda is not defined');
                            }
                            """);
                          if(context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      title: const Text("Dev Tools"),
                      titleTextStyle: const TextStyle(color: Colors.grey,fontSize: 18),
                      leading: const Icon(Icons.construction_outlined,color: Colors.grey,size: 30),
                      trailing: Checkbox(
                        fillColor:  WidgetStatePropertyAll(state.isConsole? const Color(0xff0e639c):Colors.transparent),
                        side: const BorderSide(color: Colors.grey),
                        value: state.isConsole,
                        onChanged:null),
                    ),
                   ),
                   PopupMenuItem(
                    child: ListTile(
                      onTap: () async{
                        if(isLoaded){
                          await controller.reload();
                        }
                      },
                      leading: const Icon(Icons.replay_outlined,color: Colors.grey,size: 30),
                      title: const Text("Reload"),
                      titleTextStyle: const TextStyle(color: Colors.grey,fontSize: 18)
                    )
                   )
                ], 
              )
            ],
            title:isLoaded ? FutureBuilder(
              future: (() async{
                  return await controller.getTitle();
                })(),
              builder: (context,snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting){
                  return const Center(child: CircularProgressIndicator());
                }
                return Text(snapshot.data??"WebView", style: const TextStyle(color: Colors.white));
              }
            ):const Text("WebView"),
          ),
          body: InAppWebView(
            initialSettings: InAppWebViewSettings(
                allowFileAccess: true,
                allowContentAccess: true,
                cacheEnabled: false,
                clearCache: true,
                clearSessionCache: true),
            initialUrlRequest:
                URLRequest(url: WebUri("http://localhost:5285/index.html")),
            onWebViewCreated: (InAppWebViewController webViewController) {
              controller = webViewController;
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoaded = true;
              });
            },
            onLoadStart: (controller, url) async {
              await controller.injectJavascriptFileFromAsset(assetFilePath: "assets/webview/eruda.js");
              await controller.evaluateJavascript(source:
                  """
                  window.flutter_inappwebview.callHandler = window.flutter_inappwebview.callHandler || function() {};
                  window.setViewport = function(isMobile) {
                    let viewportMetaTag = document.querySelector('meta[name="viewport"]');
                    if (!viewportMetaTag) {
                      viewportMetaTag = document.createElement('meta');
                      viewportMetaTag.setAttribute('name', 'viewport');
                      document.head.appendChild(viewportMetaTag);
                    }
                    if (isMobile) {
                      viewportMetaTag.setAttribute('content', 'width=device-width, initial-scale=1.0');
                    } else {
                      viewportMetaTag.setAttribute('content', 'width=1200');
                    }
                  };

                  if (window.setViewport) {
                    window.setViewport(${state.isMobile});
                  } else {
                    console.error('setViewport is not defined');
                  }
                  """);
              await controller.evaluateJavascript(source: """
                window.setEruda = function(val) {
                  if (val) {
                      eruda.init();
                  } else {
                    if (window.eruda) {
                      eruda.destroy();
                    }
                  }
                };
              if (window.setEruda) {
                window.setEruda(${state.isConsole});
              } else {
                console.error('setEruda is not defined');
              }
              """);
            },
          ),
        );
      },
    );
  }
}
