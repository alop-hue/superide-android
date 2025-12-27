import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../ui/home.dart';
import '../utils/functions.dart';

const List<String> javaTools = [
  'jar',
  'jarsigner',
  'java',
  'javac',
  'javadoc',
  'javap',
  'jcmd',
  'jconsole',
  'jdb',
  'jdeprscan',
  'jdeps',
  'jfr',
  'jhsdb',
  'jimage',
  'jinfo',
  'jlink',
  'jmap',
  'jmod',
  'jpackage',
  'jps',
  'jrunscript',
  'jstack',
  'jstat',
  'jstatd',
  'keytool',
  'rmiregistry',
  'serialver'
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
    
    await setupFilesDir();

    final String sharedPath = await NativeChannel.getLibraryPath();

    Map<String, dynamic> loader(String name, {String? loader, Map<String, String>? env}) => {
      'src': '$sharedPath/${loader ?? "libloader.so"}',
      'dst': '$bin/$name',
      if (env != null) 'env': env,
    };

    final loaderTools = [
      'clang', 'clang++', 'clangloader', 'node', 'python', 'python3',
      'npm', 'npx', 'pip', 'pip3', 'tsc', 'ruby', 'mono', 'csc', 'kotlinc'
    ];

    final symlinks = [
      {'src': '$sharedPath/libbash.so', 'dst': '$bin/bash'},
      {'src': '$sharedPath/libbash.so', 'dst': '$bin/sh'},
      ...loaderTools.map((tool) => loader(tool, env: {'VSDROID_SHARED_PATH': sharedPath})),
      ...javaTools.map((tool) => loader(tool, env: {'VSDROID_SHARED_PATH': sharedPath})),
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
