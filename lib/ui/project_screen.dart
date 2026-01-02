import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import '../bloc/ui_bloc/ui_bloc.dart';
import '../ui/folder_page.dart';
import '../utils/constants.dart';
import '../utils/functions.dart';
import '../utils/themes.dart';
import '../utils/widgets.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  bool _yourProjectsExpanded = false;
  bool _templatesExpanded = false;
  Future<List<Directory>>? _existingProjectsFuture;
  late final Future<Directory> _projectDirFuture;

  @override
  void initState() {
    super.initState();
    _projectDirFuture = setupProjectDir();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  static Future<List<Directory>> _getExistingProjects(Directory projectDir) async {
    try {
      if (!await projectDir.exists()) {
        return [];
      }
      final entities = await projectDir.list().toList();
      final directories = entities.whereType<Directory>().toList();
      directories.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return directories;
    } catch (e) {
      return [];
    }
  }

  void _showNewProjectDialog(BuildContext context, AppTheme appTheme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appTheme.isDark ? const Color(0xff2b2b2b) : const Color.fromARGB(255, 240, 240, 240),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffffc928).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      color: Color(0xffffc928),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "New Project",
                      style: TextStyle(
                        color: appTheme.selectScreenCardTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _projectNameController,
                style: TextStyle(
                  color: appTheme.selectScreenCardTextColor,
                ),
                cursorColor: const Color(0xff5090c8),
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  hintText: "Project name",
                  filled: true,
                  fillColor: appTheme.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xff5090c8), width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_projectNameController.text.trim().isNotEmpty) {
                        final actualProjectDir = Directory("$projectDir/${_projectNameController.text.trim()}");
                        if (!actualProjectDir.existsSync()) {
                          await actualProjectDir.create(recursive: true);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                FolderPage(dir: actualProjectDir, isCloned: true),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SizeTransition(sizeFactor: animation, child: child);
                              },
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff5090c8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Create",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
    required AppTheme appTheme,
    int? itemCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: appTheme.selectScreenCardTextColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: appTheme.selectScreenCardTextColor,
                    fontSize: 18,
                    fontWeight: appTheme.isDark ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
                if (itemCount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: appTheme.isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        color: appTheme.selectScreenCardTextColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            );
          },
          child: isExpanded
              ? Padding(
                  key: const ValueKey('expanded'),
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('collapsed')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeBloc, AppThemeState>(
      builder: (context, appThemestate) {
        final appTheme = appThemestate.appTheme;
        return Scaffold(
          body: FutureBuilder<Directory>(
            future: _projectDirFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AlertDialog(
                  title: Text("Permission denied", style: TextStyle(color: Colors.grey[400], fontSize: 20)),
                  backgroundColor: const Color(0xff2b2b2b),
                  icon: const Icon(Icons.error_outline, size: 35),
                  iconColor: Colors.red[600],
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              }

              _existingProjectsFuture ??= _getExistingProjects(snapshot.data!);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 75),
                    projectTile(
                      "New Project",
                      "Create a new custom project with version control (Git)",
                      const Icon(Icons.folder_special_rounded, color: Color(0xffffc928), size: 28),
                      appTheme.selectScreenCardsBg,
                      () => _showNewProjectDialog(context, appTheme),
                    ),
                    const SizedBox(height: 20),
                    
                    FutureBuilder<List<Directory>>(
                      future: _existingProjectsFuture,
                      builder: (context, projectsSnapshot) {
                        if (projectsSnapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (projectsSnapshot.hasError || !projectsSnapshot.hasData || projectsSnapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        final projects = projectsSnapshot.data!;
                        return _buildCollapsibleSection(
                          title: "Your Projects",
                          isExpanded: _yourProjectsExpanded,
                          onToggle: () => setState(() => _yourProjectsExpanded = !_yourProjectsExpanded),
                          itemCount: projects.length,
                          appTheme: appTheme,
                          children: projects.map((dir) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: projectTile(
                              path.basename(dir.path),
                              "Open existing project",
                              const Icon(Icons.folder, color: Color(0xff5090c8), size: 28),
                              appTheme.selectScreenCardsBg,
                              () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                      FolderPage(dir: dir, isCloned: true),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return SizeTransition(sizeFactor: animation, child: child);
                                    },
                                  ),
                                );
                              },
                            ),
                          )).toList(),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 10),
                    
                    _buildCollapsibleSection(
                      title: "Project Templates",
                      isExpanded: _templatesExpanded,
                      onToggle: () => setState(() => _templatesExpanded = !_templatesExpanded),
                      itemCount: 3,
                      appTheme: appTheme,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: projectTile(
                            "Web",
                            "Simple web project with an HTML, CSS and a JavaScript file",
                            SvgPicture.asset("assets/material_icons/web.svg", width: 30, height: 30),
                            appTheme.selectScreenCardsBg,
                            () {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: projectTile(
                            "Android",
                            "An android project with necessary files",
                            SvgPicture.asset("assets/material_icons/folder-android.svg", width: 30, height: 30),
                            appTheme.selectScreenCardsBg,
                            () {},
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: projectTile(
                            "React",
                            "Create a react app",
                            SvgPicture.asset("assets/material_icons/folder-react-components.svg", width: 30, height: 30),
                            appTheme.selectScreenCardsBg,
                            () {},
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
