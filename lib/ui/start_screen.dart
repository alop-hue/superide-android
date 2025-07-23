import 'dart:io';

import 'package:flutter/material.dart';
import '../ui/home.dart';
import '../utils/functions.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([
          (() async{
            final runTimedir = Directory("/data/data/com.vsdroid/runtimes");
            final binDir = Directory("/data/data/com.vsdroid/bin");
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
          (() async{
            final String sharedPath = await NativeChannel.getLibraryPath();
            await Process.run("ln", ["-sf", "$sharedPath/libbash.so", "/data/data/com.vsdroid/bin/bash"]);
            await Process.run("ln", ["-sf", "$sharedPath/libbash.so", "/data/data/com.vsdroid/bin/sh"]);
            await Process.run("ln", ["-sf", "$sharedPath/libnodelauncher.so", "/data/data/com.vsdroid/bin/node"]);
          })(),
          getPermission()
        ]) ,
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
