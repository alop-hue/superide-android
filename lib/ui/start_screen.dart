import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vsdroid/utils/constants.dart';
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
    final downdir = Directory(downloadsDir);
    final gitCore = "$binDir/git-core";
    final binDirectory = Directory(binDir);
    final libDirectory = Directory(libDir);
    final gitCoreDir = Directory(gitCore);

    if (!binDirectory.existsSync()) {
      await binDirectory.create(recursive: true);
    }

    if (!libDirectory.existsSync()) {
      await libDirectory.create(recursive: true);
    }

    if(!gitCoreDir.existsSync()){
      await gitCoreDir.create(recursive: true);
    }

    if (await downdir.exists()) {
      for (final file in downdir.listSync()) {
        if (file is File && file.path.endsWith('.zip')) {
          await file.delete();
        }
      }
    }
    
    await setupFilesDir();

    final String sharedPath = await NativeChannel.getLibraryPath();

    Map<String, dynamic> loader(String name, {String? loader, Map<String, String>? env}) => {
      'src': '$sharedPath/${loader ?? "libloader.so"}',
      'dst': '$binDir/$name',
      if (env != null) 'env': env,
    };

    final loaderTools = [
      'clang', 'clang++', 'clangloader', 'node', 'python', 'python3',
      'npm', 'npx', 'pip', 'pip3', 'tsc', 'ruby', 'mono', 'csc', 'kotlinc',
      'git'
    ];

    final symlinks = [
      {'src': '$sharedPath/libbash.so', 'dst': '$binDir/bash'},
      {'src': '$sharedPath/libbash.so', 'dst': '$binDir/sh'},
      {'src': '$sharedPath/libgit-remote-https.so', 'dst': '$gitCore/git-remote-https'},
      {'src': '$sharedPath/libgit-remote-https.so', 'dst': '$gitCore/git-remote-http'},
      {'src': '$sharedPath/libccls.so', 'dst': '$binDir/ccls'},
      ...loaderTools.map((tool) => loader(tool, env: {'VSDROID_SHARED_PATH': sharedPath})),
      ...javaTools.map((tool) => loader(tool, env: {'VSDROID_SHARED_PATH': sharedPath})),
    ];

    final totalLinks = symlinks.length;
    int completedLinks = 0;

    for (final link in symlinks) {
      final dst = link['dst'] as String;
      final src = link['src'] as String;
      final linkFile = Link(dst);
      
      bool needsCreation = true;
      if (linkFile.existsSync()) {
        try {
          final target = linkFile.targetSync();
          if (target == src) {
            needsCreation = false;
          }
        } catch (_) {
        }
      }
      
      if (needsCreation) {
        await Process.run(
          "ln",
          ["-sf", src, dst],
          environment: link['env'] as Map<String, String>?,
        );
      }
      completedLinks++;
      setState(() {
        progress = completedLinks / totalLinks;
      });
    }

    if (!File('$certDir/cacert.pem').existsSync()) {
      Directory(certDir).createSync(recursive: true);
      final certBytes = await rootBundle.load('assets/certificates/cacert.pem');
      File('$certDir/cacert.pem').writeAsBytesSync(certBytes.buffer.asUint8List());
    }

    if (!File('$libDir/libcrypto.so.3').existsSync()) {
      libDirectory.createSync(recursive: true);
      final bytes = await rootBundle.load('assets/lib/libcrypto.so.3');
      File('$libDir/libcrypto.so.3').writeAsBytesSync(bytes.buffer.asUint8List());
    }
    
    if (!File('$libDir/libz.so.1').existsSync()) {
      libDirectory.createSync(recursive: true);
      final bytes = await rootBundle.load('assets/lib/libz.so.1');
      File('$libDir/libz.so.1').writeAsBytesSync(bytes.buffer.asUint8List());
    }
    
    if (!File('$libDir/libpcre2-8.so').existsSync()) {
      libDirectory.createSync(recursive: true);
      final bytes = await rootBundle.load('assets/lib/libpcre2-8.so');
      File('$libDir/libpcre2-8.so').writeAsBytesSync(bytes.buffer.asUint8List());
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
