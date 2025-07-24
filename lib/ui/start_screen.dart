import 'dart:io';

import 'package:flutter/material.dart';
import '../ui/home.dart';
import '../utils/functions.dart';

const List<String> javaTools = [
  'jar','jarsigner','java','javac','javadoc','javap','jcmd','jconsole','jdb','jdeprscan','jdeps','jfr','jhsdb','jimage','jinfo','jlink','jmap','jmod','jpackage','jps','jrunscript','jstack','jstat','jstatd','keytool','rmiregistry','serialver'
];

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final runTimedir = Directory("/data/data/com.vsdroid/runtimes");
    final bin = "/data/data/com.vsdroid/bin";
    final binDir = Directory(bin);
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([
          (() async{
            if(!binDir.existsSync()){
              await binDir.create(recursive: true);
            }
            if (await runTimedir.exists()) {
              for (final file in runTimedir.listSync()) {
                if (file is File && file.path.endsWith('.zip')) {
                  await file.delete();
                }
              }
            }
          })(),
          (() async {
            final String sharedPath = await NativeChannel.getLibraryPath();
            final List<Map<String, dynamic>> symlinks = [
              {'src': '$sharedPath/libbash.so', 'dst': '$bin/bash'},
              {'src': '$sharedPath/libbash.so', 'dst': '$bin/sh'},
              {'src': '$sharedPath/libclanglauncher.so', 'dst': '$bin/clang'},
              {'src': '$sharedPath/libclang++launcher.so', 'dst': '$bin/clang++'},
              {'src': '$sharedPath/libclangloaderlauncher.so', 'dst': '$bin/clangloader'},
              {'src': '$sharedPath/libnodeloader.so', 'dst': '$bin/node', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
              {'src': '$sharedPath/libpythonloader.so', 'dst': '$bin/python', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
              {'src': '$sharedPath/libpythonloader.so', 'dst': '$bin/python3', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
              {'src': '$sharedPath/libnpmloader.so', 'dst': '$bin/npm'},
              {'src': '$sharedPath/libnpxloader.so', 'dst': '$bin/npx'},
              {'src': '$sharedPath/libpiploader.so', 'dst': '$bin/pip'},
              {'src': '$sharedPath/libpiploader.so', 'dst': '$bin/pip3'},
              for (final tool in javaTools)
                {'src': '$sharedPath/libjava_tool_loader.so', 'dst': '$bin/$tool'},
              {'src': '$sharedPath/libkotlinloader.so', 'dst': '$bin/kotlinc'},
            ];

            for (final link in symlinks) {
              await Process.run(
                "ln",
                ["-sf", link['src'], link['dst']],
                environment: link['env'] as Map<String, String>?,
              );
            }
          })(),
          getPermission()
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SelectType()));
            });
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
