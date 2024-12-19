import 'package:flutter/material.dart';
import 'package:vsdroid/ui/home.dart';
import 'package:vsdroid/ui/languages.dart';
import 'package:file_icon/file_icon.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 57),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
                cursorColor: Color(0xff6d6d6d),
                decoration: InputDecoration(
                    hintText: "Search language",
                    prefixIcon: Icon(Icons.search),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xff0178b9)),
                        borderRadius: BorderRadius.all(Radius.circular(35))),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(35))))),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Card(
                    child: ListTile(
                      leading:
                          FileIcon(".${languages[index].extension}", size: 45),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(languages[index].name),
                      ),
                      subtitle: Text(languages[index].details),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                              language: languages[index].language,
                              helloWorld: languages[index].helloWorld),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
