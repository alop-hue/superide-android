import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import '../bloc/ui_bloc/ui_bloc.dart';
import '../utils/constants.dart';
import '../utils/functions.dart';

class DownloadManager extends StatefulWidget {
  const DownloadManager({super.key});

  @override
  State<DownloadManager> createState() => _DownloadManagerState();
}

class _DownloadManagerState extends State<DownloadManager> {
  final Set<int> loadingIndexes = {};
  late final AppThemeState appThemeState;
  bool _isOnDownloadPage = true;
  final List<_ComingSoonRuntimeItem> _comingSoonRuntimes = [
    _ComingSoonRuntimeItem(
      name: 'Rust Runtime',
      details: 'Planned for next release.',
      icon: SvgPicture.asset("assets/material_icons/rust.svg"),
    ),
    _ComingSoonRuntimeItem(
      name: 'Dart Runtime',
      details: 'Planned for next release.',
      icon: SvgPicture.asset("assets/material_icons/dart.svg"),
    ),
    _ComingSoonRuntimeItem(
      name: 'Go Runtime',
      details: 'Planned for next release.',
      icon: SvgPicture.asset("assets/material_icons/go_gopher.svg"),
    ),
    _ComingSoonRuntimeItem(
      name: 'PHP Runtime',
      details: 'Planned for next release.',
      icon: SvgPicture.asset("assets/material_icons/php.svg"),
    ),
  ];

  @override
  void initState() {
    appThemeState = context.read<AppThemeBloc>().state;
    _isOnDownloadPage = true;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalogState = context.read<PackageCatalogCubit>().state;
      if (catalogState.runtimes.isEmpty &&
          catalogState.extensions.isEmpty &&
          !catalogState.isSyncing) {
        context.read<PackageCatalogCubit>().refreshCatalog();
      }
    });
  }

  @override
  void dispose() {
    _isOnDownloadPage = false;
    super.dispose();
  }

  void _startDownload(BuildContext context, int index, String url, String archiveName, String targetDir, bool isExtension) {
    final downloadBloc = context.read<DownloadManagerBloc>();
    
    setState(() {
      loadingIndexes.add(index);
    });

    final archivePath = "$targetDir/$archiveName";
    final extractDir = isExtension ? extensionDir : runtimesDir;

    FileDownloader.downloadFile(
      url: url,
      name: archiveName,
      downloadDestination: DownloadDestinations.appFiles,
      notificationType: NotificationType.all,
      onProgress: (fileName, progress) {
        downloadBloc.updateProgress(index, progress);
        
        if (mounted && _isOnDownloadPage) {
          setState(() {
            loadingIndexes.remove(index);
          });
        } else if (mounted && !_isOnDownloadPage) {
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Downloading... ${(progress).toStringAsFixed(0)}%'),
                  ),
                ],
              ),
            ),
          );
        }
        
        
        if (progress >= 100.0 && !downloadBloc.state.isExtracting(index) && !downloadBloc.state.isFullyCompleted(index)) {
          _startExtraction(downloadBloc, index, archivePath, extractDir, archiveName);
        }
      },
      onDownloadCompleted: (path) async {
        
        
        if (mounted && _isOnDownloadPage) {
          setState(() {});
        }
      },
      onDownloadError: (error) {
        downloadBloc.clearProgress(index);
        
        if (mounted) {
          setState(() {
            loadingIndexes.remove(index);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $error'))
          );
        }
      },
    );
  }

  Future<void> _startExtraction(DownloadManagerBloc downloadBloc, int index, String archivePath, String extractDir, String archiveName) async {
    downloadBloc.startExtracting(index);
    
    try {
      await Extractor.extractZipBackground(
        archivePath,
        extractDir,
        archiveName: archiveName,
        onProgress: (progress) {
          downloadBloc.updateExtractionProgress(index, progress);
        },
      );
      
      
      final archiveFile = File(archivePath);
      if (await archiveFile.exists()) {
        await archiveFile.delete();
      }

      if(archiveName == "copilot-language-server.zip"){
        final String sharedPath = await NativeChannel.getLibraryPath();
        await Process.run("ln", ["-sf", "$sharedPath/librg.so", "$extensionDir/copilot-language-server/bin/linux/arm64/rg"]);
      }
      
      downloadBloc.markFullyCompleted(index);
    } catch (e) {
      debugPrint('Error during extraction: $e');
      downloadBloc.markFullyCompleted(index);
    } finally {
      if (mounted) {
        await context.read<PackageCatalogCubit>().refreshInstalledStatusOnly();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final catalogState = context.watch<PackageCatalogCubit>().state;
    final runtimeItems = catalogState.runtimes;
    final extensionItems = catalogState.extensions;

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
              child: runtimeItems.isEmpty &&
                      (catalogState.isSyncing || catalogState.remoteFetchFailed)
                  ? _buildCatalogStateView(
                      title: 'No runtime catalog available',
                      actionLabel: 'Retry',
                      onRetry: () => context.read<PackageCatalogCubit>().refreshCatalog(),
                    )
                  : ListView.builder(
                itemCount: runtimeItems.length + _comingSoonRuntimes.length,
                itemBuilder: (_, index) {
                  if (index >= runtimeItems.length) {
                    final comingSoonRuntime =
                        _comingSoonRuntimes[index - runtimeItems.length];
                    final textColor = appThemeState
                        .appTheme
                        .selectScreenCardTextColor
                        .withAlpha(180);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      child: Card(
                        child: Opacity(
                          opacity: 0.7,
                          child: ListTile(
                            enabled: false,
                            contentPadding: EdgeInsets.zero,
                            leading: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: comingSoonRuntime.icon,
                            ),
                            title: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      comingSoonRuntime.name,
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withAlpha(45),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Coming soon',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              comingSoonRuntime.details,
                              style: TextStyle(color: textColor.withAlpha(180)),
                            ),
                            trailing: SizedBox(
                              height: 50,
                              width: 100,
                              child: LinearPercentIndicator(
                                progressColor: Colors.grey.withAlpha(120),
                                percent: 0.0,
                                width: 95,
                                lineHeight: 40,
                                barRadius: const Radius.circular(20),
                                center: const Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final runtime = runtimeItems[index];
                  final hasUpdate = catalogState.runtimeUpdates.contains(
                    runtime.parentName,
                  );
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Text("${runtime.name} - ${runtime.version ?? ''}"),
                              ),
                              if (hasUpdate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Update',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                          child: BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
                            builder: (context, downloadState) {
                              final percent = downloadState.downloadProgress[index] ?? 0;
                              final File archiveFile = File("$runtimesDir/${runtimeItems[index].archiveName}");
                              final Directory parentDir = Directory("$runtimesDir/${runtimeItems[index].parentName}");
                              
                              
                              final isExtracting = downloadState.isExtracting(index);
                              final extractionPercent = downloadState.extractionProgress[index] ?? 0;
                              
                              
                              if (isExtracting) {
                                if (extractionPercent > 0.0 && extractionPercent < 100.0) {
                                  return LinearPercentIndicator(
                                    progressColor: Colors.greenAccent.withAlpha(180),
                                    percent: (extractionPercent / 100).clamp(0.0, 1.0),
                                    width: 95,
                                    lineHeight: 40,
                                    barRadius: Radius.circular(20),
                                    center: Text("${(extractionPercent).toStringAsFixed(0)}%",
                                      style: const TextStyle(fontSize: 12)),
                                  );
                                } else {
                                  
                                  return LinearPercentIndicator(
                                    progressColor: Colors.greenAccent.withAlpha(180),
                                    percent: 0.0,
                                    width: 95,
                                    lineHeight: 40,
                                    barRadius: Radius.circular(20),
                                    center: const SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                              }
                              
                              final zipExistsButNotExtracted = archiveFile.existsSync() && !parentDir.existsSync();
                              if (zipExistsButNotExtracted && !isExtracting) {
                                
                                return LinearPercentIndicator(
                                  progressColor: Colors.orangeAccent.withAlpha(180),
                                  percent: 0.0,
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: const SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                              
                              final isFullyInstalled = parentDir.existsSync() || downloadState.isFullyCompleted(index);
                              final isUpdateAvailable = hasUpdate;

                              if (isFullyInstalled && isUpdateAvailable) {
                                return IconButton(
                                  onPressed: () async {
                                    if (!context.mounted) return;
                                    _startDownload(
                                      context,
                                      index,
                                      runtimeItems[index].url,
                                      runtimeItems[index].archiveName,
                                      downloadsDir,
                                      false,
                                    );
                                  },
                                  icon: Icon(Icons.system_update, color: Colors.orange),
                                  tooltip: 'Update to latest version',
                                );
                              }

                              if (isFullyInstalled) {
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
                                              context.read<DownloadManagerBloc>().removeDownload(index);
                                              setState(() {
                                                loadingIndexes.remove(index);
                                              });
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
                              
                              if (loadingIndexes.contains(index)) {
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
                                  
                                  if (!context.mounted) return;
                                  _startDownload(
                                    context,
                                    index,
                                    runtimeItems[index].url,
                                    runtimeItems[index].archiveName,
                                    downloadsDir,
                                    false, 
                                  );
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
              child: extensionItems.isEmpty
                  ? _buildCatalogStateView(
                      title: 'No extension catalog available',
                      actionLabel: 'Retry',
                      onRetry: () => context.read<PackageCatalogCubit>().refreshCatalog(),
                    )
                  : ListView.builder(
                itemCount: extensionItems.length,
                itemBuilder: (_, index) {
                  final extensionIndex = index + runtimeItems.length;
                  final exten = extensionItems[index];
                  final hasUpdate = catalogState.extensionUpdates.contains(
                    exten.parentName,
                  );
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
                          child: Row(
                            children: [
                              Expanded(child: Text(exten.name)),
                              if (hasUpdate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Update',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                          child: BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
                            builder: (context, downloadState) {
                              final percent = downloadState.downloadProgress[extensionIndex] ?? 0;
                              final File archiveFile = File("$extensionDir/${extensionItems[index].archiveName}");
                              final Directory parentDir = Directory("$extensionDir/${extensionItems[index].parentName}");
                              
                              
                              final isExtracting = downloadState.isExtracting(extensionIndex);
                              final extractionPercent = downloadState.extractionProgress[extensionIndex] ?? 0;
                              
                              
                              if (isExtracting) {
                                if (extractionPercent > 0.0 && extractionPercent < 100.0) {
                                  return LinearPercentIndicator(
                                    progressColor: Colors.greenAccent.withAlpha(180),
                                    percent: (extractionPercent / 100).clamp(0.0, 1.0),
                                    width: 95,
                                    lineHeight: 40,
                                    barRadius: Radius.circular(20),
                                    center: Text("${(extractionPercent).toStringAsFixed(0)}%",
                                      style: const TextStyle(fontSize: 12)),
                                  );
                                } else {
                                  
                                  return LinearPercentIndicator(
                                    progressColor: Colors.greenAccent.withAlpha(180),
                                    percent: 0.0,
                                    width: 95,
                                    lineHeight: 40,
                                    barRadius: Radius.circular(20),
                                    center: const SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                              }
                              
                              
                              final zipExistsButNotExtracted = archiveFile.existsSync() && !parentDir.existsSync();
                              if (zipExistsButNotExtracted && !isExtracting) {
                                
                                return LinearPercentIndicator(
                                  progressColor: Colors.orangeAccent.withAlpha(180),
                                  percent: 0.0,
                                  width: 95,
                                  lineHeight: 40,
                                  barRadius: Radius.circular(20),
                                  center: const SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                              
                              
                              final isFullyInstalled = parentDir.existsSync() || downloadState.isFullyCompleted(extensionIndex);
                              final isUpdateAvailable = hasUpdate;

                              if (isFullyInstalled && isUpdateAvailable) {
                                return IconButton(
                                  onPressed: () async {
                                    if (!context.mounted) return;
                                    _startDownload(
                                      context,
                                      extensionIndex,
                                      extensionItems[index].url,
                                      extensionItems[index].archiveName,
                                      downloadsDir,
                                      true,
                                    );
                                  },
                                  icon: Icon(Icons.system_update, color: Colors.orange),
                                  tooltip: 'Update to latest version',
                                );
                              }

                              if (isFullyInstalled) {
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
                                              context.read<DownloadManagerBloc>().removeDownload(extensionIndex);
                                              setState(() {
                                                loadingIndexes.remove(extensionIndex);
                                              });
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
                              
                              if (loadingIndexes.contains(extensionIndex)) {
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
                                  if (!(await Directory(downloadsDir).exists())) {
                                    await Directory(downloadsDir).create(recursive: true);
                                  }
                                  
                                  if (!context.mounted) return;
                                  _startDownload(
                                    context,
                                    extensionIndex,
                                    extensionItems[index].url,
                                    extensionItems[index].archiveName,
                                    downloadsDir,
                                    true, 
                                  );
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

  Widget _buildCatalogStateView({
    required String title,
    required String actionLabel,
    required VoidCallback onRetry,
  }) {
    final catalogState = context.watch<PackageCatalogCubit>().state;
    final textColor = appThemeState.appTheme.selectScreenCardTextColor;

    if (catalogState.isSyncing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: appThemeState.appTheme.isDark
                  ? const Color(0xff5090c8)
                  : const Color(0xff2c6fa8),
            ),
            const SizedBox(height: 14),
            Text(
              'Fetching package catalog...',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      );
    }

    if (catalogState.remoteFetchFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: textColor.withAlpha(170),
              ),
              const SizedBox(height: 10),
              Text(
                'Failed to fetch latest package data.',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(color: textColor.withAlpha(170)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Text(
        title,
        style: TextStyle(color: textColor.withAlpha(190)),
      ),
    );
  }
}

class _ComingSoonRuntimeItem {
  final String name;
  final String details;
  final dynamic icon;

  _ComingSoonRuntimeItem({
    required this.name,
    required this.details,
    required this.icon,
  });
}