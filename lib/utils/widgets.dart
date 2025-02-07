import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vsdroid/utils/themes.dart';


Widget drawerButtons(VoidCallback onPressed, dynamic icon,
  {Color color = const Color(0xff6d6d6d),Color bgColor = Colors.transparent}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(10))
      ),
      padding:  EdgeInsets.symmetric(
        horizontal: ![IconData,IconDataSolid].contains(icon.runtimeType)? 2.5:icon.runtimeType==IconDataSolid?5:4,
        vertical:![IconData,IconDataSolid].contains(icon.runtimeType)? 8:5),
      child: IconButton(
        onPressed: onPressed, icon: ![IconData,IconDataSolid].contains(icon.runtimeType) ?
         icon:
         Icon(icon, color: color, size: icon.runtimeType == IconDataSolid? 35:38)),
    ),
  );
}

Widget fileTiles(VoidCallback onPressed, String text, dynamic icon,{double val = 0}) {
  return Padding(
    padding: const EdgeInsets.only(left: 15),
    child: ListTile(
      onTap: onPressed,
      title: Text(text,
          style: const TextStyle(
              color: Color.fromARGB(255, 118, 180, 234),
              fontWeight: FontWeight.w300)),
      leading: Padding(
        child: icon,
        padding: EdgeInsets.only(left: val),
      ),
      iconColor: const Color(0xff5090c8),
    ),
  );
}

Widget settingsTile(VoidCallback onPressed, String title, dynamic icon) {
  return ListTile(
    dense: true,
    onTap: onPressed,
    leading: icon,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 18.5,
        fontWeight: FontWeight.w400,
        color:Colors.grey[400],
      ),
    ),
  );
}

Widget drawerTile(VoidCallback onPressed, String title, dynamic icon) {
  return ListTile(onTap: onPressed, title: Text(title), leading: icon);
}

Widget projectTile(String projectName, String projectDetails, icon, VoidCallback onTap){
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13,vertical: 3),
    child: Card(
      color: const Color.fromARGB(255, 51, 50, 50),
      child: ListTile(
        onTap: onTap,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        leading: icon,
        title: Text(projectName),
        subtitle: Text(projectDetails,style: const TextStyle(color: Colors.grey),),
      ),
    ),
  );
}

//-----------------------DirectoryTreeViewer--------------------------

class DirectoryTreeViewerCustom extends StatefulWidget {
  final String rootPath;
  final bool isUnfoldedFirst;
  final bool enableCreateFolderOption;
  final bool enableCreateFileOption;
  final bool enableDeleteFolderOption;
  final bool enableDeleteFileOption;
  final FolderStyle? folderStyle;
  final FileStyle? fileStyle;
  final EditingFieldStyle? editingFieldStyle;
  final void Function(File)? onFileTap;
  final List<Widget>? folderActions;
  final List<Widget>? fileActions;
  final Widget Function(String fileExtension)? fileIconBuilder;
  
  const DirectoryTreeViewerCustom({
    super.key,
    required this.rootPath,
    this.onFileTap,
    this.folderActions,
    this.fileActions,
    this.folderStyle,
    this.fileStyle,
    this.isUnfoldedFirst = true,
    this.editingFieldStyle,
    this.enableCreateFileOption = false,
    this.enableCreateFolderOption = false,
    this.enableDeleteFileOption = false,
    this.enableDeleteFolderOption = false,
    this.fileIconBuilder,
  });

  @override
  State<DirectoryTreeViewerCustom> createState() => _DirectoryTreeViewerState();
}

class _DirectoryTreeViewerState extends State<DirectoryTreeViewerCustom> {
  String? currentDir;
  late bool isParentOpen;
  late Map<String, bool> _folderStates;
  String? newEntryPath;
  bool isFolderCreation = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    isParentOpen = widget.isUnfoldedFirst;
    _folderStates = {};
    _folderStates[widget.rootPath] = isParentOpen;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool isUnfolded(String dirPath) => _folderStates[dirPath] ?? false;

  void toggleFolder(String dirPath) {
    setState(() {
      _folderStates[dirPath] = !isUnfolded(dirPath);
    });
  }

  void startCreating(String parentPath, bool isFolder) {
    setState(() {
      newEntryPath = parentPath;
      isFolderCreation = isFolder;
      _controller.clear();
    });
  }

  void stopCreating() {
    setState(() {
      newEntryPath = null;
    });
  }

  void createEntry(Directory parent) {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      final newPath = path.join(parent.path, value);
      if (isFolderCreation) {
        Directory(newPath).createSync();
      } else {
        File(newPath).createSync();
      }
    }
    stopCreating();
  }

  Widget _buildDirectoryTree(Directory directory) {
    final entries = directory.listSync();
    entries.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            toggleFolder(directory.path);
            currentDir = directory.path;
          },
          child: Row(
            children: [
              isUnfolded(directory.path)
                ? widget.folderStyle?.folderOpenedicon ?? FolderStyle().folderOpenedicon
                : widget.folderStyle?.folderClosedicon ?? FolderStyle().folderClosedicon,
              const SizedBox(width: 8),
              Text(path.basename(directory.path),style: widget.folderStyle?.folderNameStyle ?? FolderStyle().folderNameStyle),
              SizedBox(width: widget.folderStyle?.itemGap ?? FolderStyle().itemGap),
              if (widget.enableCreateFileOption && isUnfolded(directory.path) && currentDir == directory.path)
                IconButton(
                  onPressed: () => startCreating(directory.path, false),
                  icon: widget.folderStyle?.iconForCreateFile ??
                      FolderStyle().iconForCreateFile,
                ),

              if (widget.enableCreateFolderOption && isUnfolded(directory.path) && currentDir == directory.path)
                IconButton(
                  onPressed: () => startCreating(directory.path, true),
                  icon: widget.folderStyle?.iconForCreateFolder ??
                    FolderStyle().iconForCreateFolder,
                ), 

              if (widget.enableDeleteFolderOption && isUnfolded(directory.path) && currentDir == directory.path)
                IconButton(
                  onPressed: () {
                    Directory(directory.path).delete(recursive: true);
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete),
                ),
              ...widget.folderActions ?? [],
            ],
          ),
        ),
        if (isUnfolded(directory.path))
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: [
                ...entries.map((entry) =>
                    entry is Directory ? _buildDirectoryTree(entry) : _buildFileItem(entry as File)),
                if (newEntryPath == directory.path) _buildNewEntryField(directory),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNewEntryField(Directory parent) {
    return Row(
      children: [
        isFolderCreation
          ? widget.editingFieldStyle?.folderIcon ?? EditingFieldStyle().folderIcon
          : widget.editingFieldStyle?.fileIcon ?? EditingFieldStyle().fileIcon,
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: widget.editingFieldStyle?.textFieldHeight,
            width: widget.editingFieldStyle?.textFieldWidth,
            child: TextField(
              style: widget.editingFieldStyle?.textStyle,
              textAlignVertical: widget.editingFieldStyle?.verticalTextAlign,
              cursorRadius: widget.editingFieldStyle?.cursorRadius,
              cursorWidth: widget.editingFieldStyle?.cursorWidth ?? 2.0,
              cursorHeight: widget.editingFieldStyle?.cursorHeight,
              cursorColor: widget.editingFieldStyle?.cursorColor,
              autofocus: true,
              decoration: widget.editingFieldStyle?.textfieldDecoration ?? EditingFieldStyle().textfieldDecoration,
              controller: _controller,
              onSubmitted: (_) => createEntry(parent),
            ),
          ),
        ),
        IconButton(icon: widget.editingFieldStyle?.doneIcon ?? EditingFieldStyle().doneIcon, onPressed: () => createEntry(parent)),
        IconButton(icon: widget.editingFieldStyle?.cancelIcon ?? EditingFieldStyle().cancelIcon, onPressed: stopCreating),
      ],
    );
  }

  Widget _buildFileItem(File file) {
    return InkWell(
      onTap: () => widget.onFileTap?.call(file),
      child: Row(
        children: [
          widget.fileIconBuilder?.call(path.extension(file.path).toLowerCase()) ??
              widget.fileStyle?.fileIcon ??
              FileStyle().fileIcon,
          const SizedBox(width: 8),
          Text(path.basename(file.path),
              style: widget.fileStyle?.fileNameStyle ?? FileStyle().fileNameStyle),
          if (widget.enableDeleteFileOption)
            IconButton(
              onPressed: () {
                file.deleteSync();
                setState(() {});
              },
              icon: widget.fileStyle?.iconForDeleteFile ?? FileStyle().iconForDeleteFile,
            ),
          ...widget.fileActions ?? [],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootDirectory = Directory(widget.rootPath);
    if (!rootDirectory.existsSync()) {
      return const Center(child: Text('Directory does not exist'));
    }
    return SingleChildScrollView(child: _buildDirectoryTree(rootDirectory));
  }
}
