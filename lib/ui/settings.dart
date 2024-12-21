import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 45, 45, 45),
      appBar: AppBar(
        backgroundColor: const Color(0xff181818),
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          settingsTile(() {}, 'Themes',
              const Icon(Icons.color_lens, size: 24, color: Colors.grey)),
          settingsTile(() {}, "Font Size",
              const Icon(Icons.font_download, color: Colors.grey))
        ],
      ),
    );
  }
}

Widget settingsTile(VoidCallback onPressed, String title, dynamic icon) {
  return Column(
    children: [
      ListTile(
        onTap: onPressed,
        leading: icon,
        title: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
      ),
      const Divider(thickness: 0.2, indent: 10, endIndent: 10)
    ],
  );
}
