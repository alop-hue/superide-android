import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'languages.dart';

class PackageCatalogSyncResult {
  final List<RunTime> runtimes;
  final List<Extension> extensions;
  final Set<String> runtimeUpdates;
  final Set<String> extensionUpdates;
  final bool usedRemote;
  final bool remoteFetchFailed;

  const PackageCatalogSyncResult({
    required this.runtimes,
    required this.extensions,
    required this.runtimeUpdates,
    required this.extensionUpdates,
    required this.usedRemote,
    required this.remoteFetchFailed,
  });
}

class PackageCatalogService {
  static Future<PackageCatalogSyncResult> syncOnStartup() async {
    await Directory(packageCatalogCacheDir).create(recursive: true);

    final installed = await _loadInstalledCatalog();
    final cached = await _loadCachedCatalog();

    final remoteResult = await _fetchRemoteCatalog();
    final remote = remoteResult.catalog;
    final effective = remote ?? cached ?? installed;

    if (remote != null) {
      await _writeCache(remote.runtimes, remote.extensions);
    }

    updatePackageCatalog(
      fetchedRuntimes: effective.runtimes,
      fetchedExtensions: effective.extensions,
    );

    final updates = _buildUpdateSets(
      catalogRuntimes: effective.runtimes,
      catalogExtensions: effective.extensions,
      installedRuntimes: installed.runtimes,
      installedExtensions: installed.extensions,
    );

    return PackageCatalogSyncResult(
      runtimes: effective.runtimes,
      extensions: effective.extensions,
      runtimeUpdates: updates.runtimeUpdates,
      extensionUpdates: updates.extensionUpdates,
      usedRemote: remote != null,
      remoteFetchFailed: remoteResult.failed,
    );
  }

  static Future<PackageCatalogSyncResult> refreshInstalledStatusOnly({
    required List<RunTime> runtimes,
    required List<Extension> extensions,
  }) async {
    final installed = await _loadInstalledCatalog();

    final updates = _buildUpdateSets(
      catalogRuntimes: runtimes,
      catalogExtensions: extensions,
      installedRuntimes: installed.runtimes,
      installedExtensions: installed.extensions,
    );

    return PackageCatalogSyncResult(
      runtimes: runtimes,
      extensions: extensions,
      runtimeUpdates: updates.runtimeUpdates,
      extensionUpdates: updates.extensionUpdates,
      usedRemote: false,
      remoteFetchFailed: false,
    );
  }

  static Future<({
    ({List<RunTime> runtimes, List<Extension> extensions})? catalog,
    bool failed,
  })>
  _fetchRemoteCatalog() async {
    try {
      final runtimeResponse = await http
          .get(Uri.parse(runtimesCatalogUrl))
          .timeout(const Duration(seconds: 12));
      final extensionResponse = await http
          .get(Uri.parse(extensionsCatalogUrl))
          .timeout(const Duration(seconds: 12));

      if (runtimeResponse.statusCode != 200 ||
          extensionResponse.statusCode != 200) {
        return (catalog: null, failed: true);
      }

      final runtimeJson = jsonDecode(runtimeResponse.body) as Map<String, dynamic>;
      final extensionJson =
          jsonDecode(extensionResponse.body) as Map<String, dynamic>;

      return (
        catalog: (
          runtimes: _parseRuntimes(runtimeJson),
          extensions: _parseExtensions(extensionJson),
        ),
        failed: false,
      );
    } catch (e) {
      debugPrint('Package catalog remote fetch failed: $e');
      return (catalog: null, failed: true);
    }
  }

  static Future<({List<RunTime> runtimes, List<Extension> extensions})?>
  _loadCachedCatalog() async {
    try {
      final runtimeFile = File(runtimesCatalogCacheFile);
      final extensionFile = File(extensionsCatalogCacheFile);

      if (!runtimeFile.existsSync() || !extensionFile.existsSync()) {
        return null;
      }

      final runtimeJson =
          jsonDecode(await runtimeFile.readAsString()) as Map<String, dynamic>;
      final extensionJson =
          jsonDecode(await extensionFile.readAsString()) as Map<String, dynamic>;

      return (
        runtimes: _parseRuntimes(runtimeJson),
        extensions: _parseExtensions(extensionJson),
      );
    } catch (e) {
      debugPrint('Package catalog cache load failed: $e');
      return null;
    }
  }

  static Future<({List<RunTime> runtimes, List<Extension> extensions})>
  _loadInstalledCatalog() async {
    final runtimeDir = Directory(runtimesDir);
    final extensionDirPath = Directory(extensionDir);
    final installedRuntimes = <RunTime>[];
    final installedExtensions = <Extension>[];

    if (runtimeDir.existsSync()) {
      final runtimeEntries = runtimeDir
        .listSync(followLinks: false)
        .whereType<Directory>()
        .toList();
      for (final dir in runtimeEntries) {
        final packageFile = File('${dir.path}/rsx-package.json');
        if (!packageFile.existsSync()) continue;
        try {
          final parsed = jsonDecode(await packageFile.readAsString()) as Map<String, dynamic>;
          installedRuntimes.add(RunTime.fromJson(parsed));
        } catch (_) {}
      }
    }

    if (extensionDirPath.existsSync()) {
      final extensionEntries = extensionDirPath
        .listSync(followLinks: false)
        .whereType<Directory>()
        .toList();
      for (final dir in extensionEntries) {
        final packageFile = File('${dir.path}/rsx-package.json');
        if (!packageFile.existsSync()) continue;
        try {
          final parsed = jsonDecode(await packageFile.readAsString()) as Map<String, dynamic>;
          installedExtensions.add(Extension.fromJson(parsed));
        } catch (_) {}
      }
    }

    return (runtimes: installedRuntimes, extensions: installedExtensions);
  }

  static Future<void> _writeCache(
    List<RunTime> runtimes,
    List<Extension> extensions,
  ) async {
    final runtimeFile = File(runtimesCatalogCacheFile);
    final extensionFile = File(extensionsCatalogCacheFile);

    await runtimeFile.writeAsString(
      jsonEncode({'runtimes': runtimes.map((item) => item.toJson()).toList()}),
      flush: true,
    );

    await extensionFile.writeAsString(
      jsonEncode({'extensions': extensions.map((item) => item.toJson()).toList()}),
      flush: true,
    );
  }

  static List<RunTime> _parseRuntimes(Map<String, dynamic> decoded) {
    final values = decoded['runtimes'];
    if (values is! List<dynamic>) return const [];
    return values
        .whereType<Map<String, dynamic>>()
        .map(RunTime.fromJson)
        .toList();
  }

  static List<Extension> _parseExtensions(Map<String, dynamic> decoded) {
    final values = decoded['extensions'];
    if (values is! List<dynamic>) return const [];
    return values
        .whereType<Map<String, dynamic>>()
        .map(Extension.fromJson)
        .toList();
  }

  static ({Set<String> runtimeUpdates, Set<String> extensionUpdates})
  _buildUpdateSets({
    required List<RunTime> catalogRuntimes,
    required List<Extension> catalogExtensions,
    required List<RunTime> installedRuntimes,
    required List<Extension> installedExtensions,
  }) {
    final runtimeUpdates = <String>{};
    final extensionUpdates = <String>{};

    final installedRuntimeByParent = {
      for (final item in installedRuntimes) item.parentName: item,
    };
    final installedExtensionByParent = {
      for (final item in installedExtensions) item.parentName: item,
    };

    for (final item in catalogRuntimes) {
      final installed = installedRuntimeByParent[item.parentName];
      if (installed == null) continue;

      if (_isRuntimeUpdateAvailable(item, installed)) {
        runtimeUpdates.add(item.parentName);
      }
    }

    for (final item in catalogExtensions) {
      final installed = installedExtensionByParent[item.parentName];
      if (installed == null) continue;

      if (_isExtensionUpdateAvailable(item, installed)) {
        extensionUpdates.add(item.parentName);
      }
    }

    return (
      runtimeUpdates: runtimeUpdates,
      extensionUpdates: extensionUpdates,
    );
  }

  static bool _isRuntimeUpdateAvailable(RunTime catalog, RunTime installed) {
    final catalogVersion = catalog.version?.trim();
    final installedVersion = installed.version?.trim();

    if ((catalogVersion ?? '').isNotEmpty && (installedVersion ?? '').isNotEmpty) {
      return catalogVersion != installedVersion;
    }

    final catalogArchive = catalog.archiveName.trim();
    final installedArchive = installed.archiveName.trim();
    if (catalogArchive.isNotEmpty && installedArchive.isNotEmpty) {
      return catalogArchive != installedArchive;
    }

    return false;
  }

  static bool _isExtensionUpdateAvailable(Extension catalog, Extension installed) {
    final catalogArchive = catalog.archiveName.trim();
    final installedArchive = installed.archiveName.trim();
    if (catalogArchive.isNotEmpty && installedArchive.isNotEmpty) {
      return catalogArchive != installedArchive;
    }

    return false;
  }
}
