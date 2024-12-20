import 'package:flutter/material.dart';
import 'package:vsdroid/ui/menu_screen.dart';
import 'package:vsdroid/utils/functions.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getPermission(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MenuScreen()));
          });
          return AlertDialog(
            title: const Text('Permission required',style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.warning_amber),
            iconColor: Colors.red[600],
            backgroundColor: const Color(0xff181818),
          );
        },
      ),
    );
  }
}
