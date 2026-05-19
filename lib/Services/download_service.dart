import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum DownloadState { idle, downloading, extracting, launching, done, error }

class DownloadProgress {
  final DownloadState state;
  final double progress;
  final String? filePath;
  final String? error;

  const DownloadProgress({
    this.state = DownloadState.idle,
    this.progress = 0,
    this.filePath,
    this.error,
  });

  DownloadProgress copyWith({
    DownloadState? state,
    double? progress,
    String? filePath,
    String? error,
  }) {
    return DownloadProgress(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
    );
  }
}

class DownloadService {
  static Future<DownloadProgress> downloadAndInstall({
    required String url,
    required void Function(DownloadProgress) onProgress,
  }) async {
    try {
      onProgress(const DownloadProgress(state: DownloadState.idle));
      final uri = Uri.parse(url);

      final dir = await getTemporaryDirectory();
      final fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'update.zip';
      final zipPath = '${dir.path}\\$fileName';
      final extractPath = '${dir.path}\\app_update';

      // Download
      final client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        final err = DownloadProgress(
          state: DownloadState.error,
          error: 'Download failed (HTTP ${response.statusCode})',
        );
        onProgress(err);
        return err;
      }

      final totalBytes = response.contentLength ?? -1;
      final receivedBytes = <int>[];
      final completer = Completer<DownloadProgress>();

      response.stream.listen(
        (chunk) {
          receivedBytes.addAll(chunk);
          if (totalBytes > 0) {
            onProgress(DownloadProgress(
              state: DownloadState.downloading,
              progress: receivedBytes.length / totalBytes,
            ));
          }
        },
        onDone: () async {
          client.close();
          try {
            final file = File(zipPath);
            await file.writeAsBytes(receivedBytes);
            onProgress(const DownloadProgress(state: DownloadState.done));

            // Extract ZIP
            onProgress(const DownloadProgress(state: DownloadState.extracting));
            final bytes = file.readAsBytesSync();
            final archive = ZipDecoder().decodeBytes(bytes);

            final extractDir = Directory(extractPath);
            if (extractDir.existsSync()) {
              extractDir.deleteSync(recursive: true);
            }
            extractDir.createSync(recursive: true);

            for (final entry in archive) {
              final entryPath = '$extractPath\\${entry.name}';
              if (entry.isFile) {
                final outFile = File(entryPath);
                outFile.createSync(recursive: true);
                outFile.writeAsBytesSync(entry.content as List<int>);
              } else {
                Directory(entryPath).createSync(recursive: true);
              }
            }

            // Find the EXE name
            final exeFile = _findExe(extractDir);
            if (exeFile == null) {
              final err = DownloadProgress(
                state: DownloadState.error,
                error: 'No executable found in the update package',
              );
              onProgress(err);
              completer.complete(err);
              return;
            }

            // Get the current app's install directory
            final currentExe = Platform.resolvedExecutable;
            final installDir = File(currentExe).parent.path;
            final exeName = exeFile.path.split('\\').last;

            // Write a PowerShell script that renames the old EXE (so the path is free),
            // copies new files over, then launches the new EXE and cleans up.
            final scriptPath = '$extractPath\\update.ps1';
            final script = '''
Start-Sleep -Seconds 3
\$oldExe = "$installDir\\$exeName"
if (Test-Path \$oldExe) {
    Rename-Item -Path \$oldExe -NewName "$exeName.old" -Force
}
Copy-Item -Path "$extractPath\\*" -Destination "$installDir" -Recurse -Force
Start-Process "$installDir\\$exeName"
Start-Sleep -Seconds 2
Remove-Item -Path "$installDir\\$exeName.old" -Force -ErrorAction SilentlyContinue
''';
            File(scriptPath).writeAsStringSync(script);

            onProgress(const DownloadProgress(state: DownloadState.launching));
            await Process.start('powershell', ['-ExecutionPolicy', 'Bypass', '-File', scriptPath]);
            exit(0);
          } catch (e) {
            final err = DownloadProgress(
              state: DownloadState.error,
              error: 'Failed to install update: $e',
            );
            onProgress(err);
            completer.complete(err);
          }
        },
        onError: (e) {
          client.close();
          final err = DownloadProgress(
            state: DownloadState.error,
            error: 'Download failed: $e',
          );
          onProgress(err);
          completer.complete(err);
        },
      );

      return completer.future;
    } catch (e) {
      final err = DownloadProgress(
        state: DownloadState.error,
        error: e.toString(),
      );
      onProgress(err);
      return err;
    }
  }

  static File? _findExe(Directory dir) {
    if (!dir.existsSync()) return null;
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.exe')) {
        return entity;
      }
    }
    return null;
  }
}
