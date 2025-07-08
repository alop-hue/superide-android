import 'package:flutter/material.dart';
import 'package:vsdroid/utils/languages.dart';
import 'package:vsdroid/utils/widgets.dart';

class RuntimeManager extends StatelessWidget {
  const RuntimeManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ListView.builder(
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            child: Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: runtimes[index].icon
                ),
                title: Text(runtimes[index].name),
                subtitle: Text(runtimes[index].details),
                trailing: DownloadButton(progress: 0),
              ),
            ),
          ),
          itemCount: runtimes.length,
        ),
      ),
    );
  }
}