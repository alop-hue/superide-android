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
            final dir = Directory("/data/data/com.vsdroid/runtimes");
            if (await dir.exists()) {
              for (final file in dir.listSync()) {
                if (file is File && file.path.endsWith('.zip')) {
                  await file.delete();
                }
              }
            }
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
