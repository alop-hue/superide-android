import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';
import 'package:vsdroid/utils/functions.dart';
import '../utils/languages.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class DownloadManager extends StatefulWidget {
  const DownloadManager({super.key});

  @override
  State<DownloadManager> createState() => _DownloadManagerState();
}

class _DownloadManagerState extends State<DownloadManager> {
  StreamSubscription<dynamic>? _portSubscription;
  final Map<String, String> archiveNameMap = {};
  final Map<int, String> taskIdMap = {};
  final Set<int> loadingIndexes = {};
  final Set<String> loadingTaskIds = {};
  late final AppThemeState appThemeState;

  @override
  void initState() {
    FlutterDownloader.registerCallback(downloadCallback);
    appThemeState = context.read<AppThemeBloc>().state;
    const String runTimesdir = "/data/data/com.vsdroid/runtimes";
    const String extensionDir = "/data/data/com.vsdroid/extensions";
    final stream = context.read<DownloadPortBloc>().downloadStream;
    _portSubscription = stream.listen((data) async {
      final id = data[0] as String;
      final progress = data[2] as int;
      final status = DownloadTaskStatus.fromInt(data[1]);
      if (status.name == 'complete' && mounted) {
        final archiveName = archiveNameMap[id];
        final isExtension = extensions.any((ext) => ext.archiveName == archiveName);
        final extractDir = isExtension ? extensionDir : runTimesdir;
        final archivePath = isExtension
            ? "$extensionDir/$archiveName"
            : "$runTimesdir/$archiveName";
        await Extractor.extractZip(
          context,
          archivePath,
          extractDir,
          archiveName: archiveName,
        );
        await File(archivePath).delete(recursive: true);
      }
      setState(() {
        loadingTaskIds.remove(id);
      });
      if (mounted) {
        final bloc = context.read<DownloadProgressBloc>();
        final current = Map<String, double>.from(bloc.state.downloadProgress ?? {});
        current[id] = progress.toDouble();
        bloc.add(DownloadProgressEvent(current));
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _portSubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Downloads",
            style: TextStyle(
              color: appThemeState.appTheme.selectScreenCardTextColor
            )
          ),
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            labelColor: Color.fromARGB(255, 17, 120, 189),
            indicatorColor: Color.fromARGB(255, 17, 120, 189),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                icon:Icon(FontAwesomeIcons.gears, size: 26),
                text: "Runtimes",
              ),
              Tab(
                icon: Icon(Icons.extension),
                text: "Extensions",
              )
            ]
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ListView.builder(
                itemCount: runtimes.length,
                itemBuilder: (_, index) {
                  final runtime = runtimes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    child: Card(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: runtime.icon,
                        ),
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text("${runtime.name} - ${runtime.version}"),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: Text(
                                "Size: ${runtime.archiveSize} MB",
                                style: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            Text(runtime.details)
                          ],
                        ),
                        trailing: SizedBox(
                          height: 50,
                          width: 100,
                          child: BlocBuilder<DownloadProgressBloc, DownloadProgressState>(
                            builder: (context, downloadState) {
                              double? percent = downloadState.downloadProgress?[taskIdMap[index]] ?? 0;
                              final File archiveFile = File("/data/data/com.vsdroid/runtimes/${runtimes[index].archiveName}");
                              final Directory parentDir = Directory("/data/data/com.vsdroid/runtimes/${runtimes[index].parentName}");
                              if((
                                percent / 100).clamp(0.0, 1.0) == 1.0 ||
                                (archiveFile.existsSync() && ((archiveFile.lengthSync() / (1024 * 1024)).toInt() == (runtimes[index].archiveSize).toInt())) ||
                                parentDir.existsSync()
                              ){
                                return IconButton(
                                  onPressed: (){
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: appThemeState.appTheme.isDark ? appThemeState.appTheme.scaffoldBg : null,
                                        title: Text(
                                          'Delete ${runtime.name} - ${runtime.version}?',
                                          style: TextStyle(
                                            color: appThemeState.appTheme.selectScreenCardTextColor,
                                            fontSize: 20
                                          ),
                                        ),
                                        content: Text(
                                          "Are you sure you want to delete this runtime?",
                                          style: TextStyle(
                                            color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                            fontSize: 16
                                          )
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: ()=> Navigator.of(context).pop(),
                                            child: Text('Cancel')
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              if(archiveFile.existsSync()){
                                                archiveFile.deleteSync(recursive: true);
                                              }
                                              if(parentDir.existsSync()){
                                                parentDir.deleteSync(recursive: true);
                                              }
                                              setState(() {
                                                final taskId = taskIdMap[index];
                                                if (taskId != null) {
                                                  loadingTaskIds.remove(taskId);
                                                  taskIdMap.remove(index);
                                                }
                                                loadingIndexes.remove(index);
                                              });
                                              context.read<DownloadProgressBloc>().add(DownloadProgressEvent(null));
                                              Navigator.of(context).pop(true);
                                            },
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                                            ),
                                            child: Text('Delete', style: TextStyle(color: Colors.white))
                                          )
                                        ],
                                      )
                                    );
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red)
                                );
                              }
                              final taskId = taskIdMap[index];
                              if (percent > 0.0 && percent < 100.0) {
                                return LinearPercentIndicator(
                                  progressColor: Colors.blueAccent.withAlpha(180),
                                  percent: (percent / 100).clamp(0.0, 1.0),
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: Text("${(percent).toStringAsFixed(0)}%"),
                                );
                              }
                              if (loadingIndexes.contains(index) || (taskId != null && loadingTaskIds.contains(taskId) && percent == 0.0)) {
                                return LinearPercentIndicator(
                                  progressColor: Colors.blueAccent.withAlpha(180),
                                  percent: 0.0,
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: const SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () async{
                                  setState(() {
                                    loadingIndexes.add(index);
                                  });
                                  final dir = "/data/data/com.vsdroid/runtimes";
                                  if(!(await Directory(dir).exists())){
                                    await Directory(dir).create(recursive: true);
                                  }
                                  final String? taskId = await FlutterDownloader.enqueue(
                                    url: runtimes[index].url,
                                    savedDir: dir,
                                    saveInPublicStorage: false,
                                    showNotification: true,
                                    openFileFromNotification: false,
                                  );
                                  if(taskId != null){
                                    setState(() {
                                      taskIdMap[index] = taskId;
                                      loadingTaskIds.add(taskId);
                                    });
                                    archiveNameMap[taskId] = runtimes[index].archiveName;
                                  }
                                },
                                child: LinearPercentIndicator(
                                  progressColor: Colors.blueAccent.withAlpha(180),
                                  percent: 0.0,
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: Icon(Icons.download),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ListView.builder(
                itemCount: extensions.length,
                itemBuilder: (_, index) {
                  final exten = extensions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    child: Card(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: exten.icon,
                        ),
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(exten.name),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: Text(
                                "Size: ${exten.archiveSize} MB",
                                style: TextStyle(
                                  color: appThemeState.appTheme.selectScreenCardTextColor,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                            Text(exten.details)
                          ],
                        ),
                        trailing: SizedBox(
                          height: 50,
                          width: 100,
                          child: BlocBuilder<DownloadProgressBloc, DownloadProgressState>(
                            builder: (context, downloadState) {
                              double? percent = downloadState.downloadProgress?[taskIdMap[index]] ?? 0;
                              final File archiveFile = File("/data/data/com.vsdroid/extensions/${extensions[index].archiveName}");
                              final Directory parentDir = Directory("/data/data/com.vsdroid/extensions/${extensions[index].parentName}");
                              if ((percent / 100).clamp(0.0, 1.0) == 1.0 ||
                                  (archiveFile.existsSync() && ((archiveFile.lengthSync() / (1024 * 1024)).toInt() == (exten.archiveSize).toInt())) ||
                                  parentDir.existsSync()) {
                                return IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: appThemeState.appTheme.isDark ? appThemeState.appTheme.scaffoldBg : null,
                                        title: Text(
                                          exten.name,
                                          style: TextStyle(
                                            color: appThemeState.appTheme.selectScreenCardTextColor,
                                            fontSize: 20
                                          ),
                                        ),
                                        content: Text(
                                          "Are you sure you want to delete this extension?",
                                          style: TextStyle(
                                            color: appThemeState.appTheme.selectScreenCardTextColor.withAlpha(150),
                                            fontSize: 16
                                          )
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Cancel')
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (archiveFile.existsSync()) {
                                                archiveFile.deleteSync(recursive: true);
                                              }
                                              if (parentDir.existsSync()) {
                                                parentDir.deleteSync(recursive: true);
                                              }
                                              setState(() {
                                                final taskId = taskIdMap[index];
                                                if (taskId != null) {
                                                  loadingTaskIds.remove(taskId);
                                                  taskIdMap.remove(index);
                                                }
                                                loadingIndexes.remove(index);
                                              });
                                              context.read<DownloadProgressBloc>().add(DownloadProgressEvent(null));
                                              Navigator.of(context).pop(true);
                                            },
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStateProperty.all<Color>(Colors.red)
                                            ),
                                            child: Text('Delete', style: TextStyle(color: Colors.white))
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                );
                              }
                              final taskId = taskIdMap[index];
                              if (percent > 0.0 && percent < 100.0) {
                                return LinearPercentIndicator(
                                  progressColor: Colors.blueAccent.withAlpha(180),
                                  percent: (percent / 100).clamp(0.0, 1.0),
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: Text("${(percent).toStringAsFixed(0)}%"),
                                );
                              }
                              if (loadingIndexes.contains(index) || (taskId != null && loadingTaskIds.contains(taskId) && percent == 0.0)) {
                                return LinearPercentIndicator(
                                  progressColor: Colors.blueAccent.withAlpha(180),
                                  percent: 0.0,
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: const SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    loadingIndexes.add(index);
                                  });
                                  final dir = "/data/data/com.vsdroid/extensions";
                                  if (!(await Directory(dir).exists())) {
                                    await Directory(dir).create(recursive: true);
                                  }
                                  final String? taskId = await FlutterDownloader.enqueue(
                                    url: extensions[index].url,
                                    savedDir: dir,
                                    saveInPublicStorage: false,
                                    showNotification: true,
                                    openFileFromNotification: false,
                                  );
                                  if (taskId != null) {
                                    setState(() {
                                      taskIdMap[index] = taskId;
                                      loadingTaskIds.add(taskId);
                                    });
                                    archiveNameMap[taskId] = extensions[index].archiveName;
                                  }
                                },
                                child: LinearPercentIndicator(
                                  progressColor: Colors.blueAccent.withAlpha(180),
                                  percent: 0.0,
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: Icon(Icons.download),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}