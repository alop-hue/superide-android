import 'package:flutter/material.dart';
import 'package:vsdroid/ui/select.dart';
import 'package:vsdroid/utils/functions.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getPermission() ,
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
