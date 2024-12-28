import 'package:flutter/material.dart';
import 'package:vsdroid/ui/home.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:file_icon/file_icon.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 65,
            actions: [
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 55,right: 20),
                  child: TextField(
                    onChanged: (data){
                      //Todo: Search functionality
                    },
                  style: const TextStyle(color: Colors.grey),
                  cursorColor: const Color(0xff6d6d6d),
                  decoration: const InputDecoration(
                      hintText: "Search language",
                      prefixIcon: Icon(Icons.search),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0178b9)),
                          borderRadius: BorderRadius.all(Radius.circular(35))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(35))))),
                ),
              )
            ]
          ),
          SliverList(delegate: SliverChildBuilderDelegate(
            childCount: languages.length,
            (context,index){
              return Padding(
                  padding:const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Card(
                    child: ListTile(
                      leading: languages[index].icon ??FileIcon(".${languages[index].extension}", size: 35),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(languages[index].name),
                      ),
                      subtitle: Text(languages[index].details),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => HomeScreen(languageDetails: languages[index])),
                      ),
                    ),
                  ),
                );
            }))
        ],
      ),
    );
  }
}
