import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../ui/home.dart';
import '../utils/functions.dart';

const List<String> javaTools = [
  'jar','jarsigner','java','javac','javadoc','javap','jcmd','jconsole','jdb','jdeprscan','jdeps','jfr','jhsdb','jimage','jinfo','jlink','jmap','jmod','jpackage','jps','jrunscript','jstack','jstat','jstatd','keytool','rmiregistry','serialver'
];

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  double progress = 0.0;
  bool isDone = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
   final runTimedir = Directory("/data/data/com.vsdroid/runtimes");
    final bin = "/data/data/com.vsdroid/bin";
    final binDir = Directory(bin);

    // Step 1: Cleanup zip files and create bin dir if needed
    if (!binDir.existsSync()) {
      await binDir.create(recursive: true);
    }
    if (await runTimedir.exists()) {
      for (final file in runTimedir.listSync()) {
        if (file is File && file.path.endsWith('.zip')) {
          await file.delete();
        }
      }
    }

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
      {'src': '$sharedPath/libnpmloader.so', 'dst': '$bin/npm', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
      {'src': '$sharedPath/libnpxloader.so', 'dst': '$bin/npx', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
      {'src': '$sharedPath/libpiploader.so', 'dst': '$bin/pip', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
      {'src': '$sharedPath/libpiploader.so', 'dst': '$bin/pip3', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
      {'src': '$sharedPath/libtsloader.so', 'dst': '$bin/tsc'},
      {'src': '$sharedPath/libclangd.so', 'dst': '$bin/clangd', 'env': {'LD_LIBRARY_PATH': "$sharedPath:$runTimedir/clang"}},
      {'src': '$sharedPath/libruby.so', 'dst': '$bin/ruby', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
      {'src': '$sharedPath/libmono.so', 'dst': '$bin/mono', 'env': {'VSDROID_SHARED_PATH': sharedPath}},
      for (final tool in javaTools)
        {'src': '$sharedPath/libjava_tool_loader.so', 'dst': '$bin/$tool'},
      {'src': '$sharedPath/libkotlinloader.so', 'dst': '$bin/kotlinc'},
    ];

    final totalLinks = symlinks.length;
    int completedLinks = 0;

    for (final link in symlinks) {
      await Process.run(
        "ln",
        ["-sf", link['src'], link['dst']],
        environment: link['env'] as Map<String, String>?,
      );

      completedLinks++;
      setState(() {
        progress = completedLinks / totalLinks;
      });
    }

    await getPermission();

    setState(() {
      isDone = true;
    });

    Future.delayed(Duration(milliseconds: 0), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SelectType(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ));
      }
    });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isDone
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Setting things up..."),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 60),
                    child: LinearPercentIndicator(
                      progressColor: Colors.blue,
                      percent: progress,
                      width: 300,
                      lineHeight: 10,
                      barRadius: Radius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("${(progress * 100).toStringAsFixed(0)}%"),
                ],
              ),
      ),
    );
  }
}
