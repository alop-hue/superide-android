import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import '../utils/languages.dart';

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
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text("${runtimes[index].name} - ${runtimes[index].version}"),
                ),
                subtitle: Text(runtimes[index].details),
                trailing: SizedBox(
                  height: 50,
                  width: 100,
                  child: GestureDetector(
                    onTap: () async{
                      //TODO: Download
                      final String? taskId = await FlutterDownloader.enqueue(
                        url: runtimes[index].url,
                        savedDir: "/data/data/com.vsdroid/files",
                        showNotification: true,
                        openFileFromNotification: false,
                      );
                      // FlutterDownloader.registerCallback((){});
                      if(context.mounted){
                        // context.read<DownloadProgressBloc>().add(DownloadProgressEvent());
                      }
                    },
                    child: BlocBuilder<DownloadProgressBloc, DownloadProgressState>(
                      builder: (context, downloadState) {
                        return LinearPercentIndicator(
                          lineHeight: 30,
                          width: 85,
                          percent: 0,
                          center: Text("0%"),
                          progressColor: Colors.green,
                          barRadius: Radius.circular(20),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          itemCount: runtimes.length,
        ),
      ),
    );
  }
}