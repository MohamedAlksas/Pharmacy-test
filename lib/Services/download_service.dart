import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum DownloadState { idle, downloading, done, error }

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
          : 'update.exe';
      final filePath = '${dir.path}\\$fileName';

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
            final file = File(filePath);
            await file.writeAsBytes(receivedBytes);
            onProgress(const DownloadProgress(state: DownloadState.done));
            await Process.run(filePath, [], runInShell: true);
            completer.complete(DownloadProgress(
              state: DownloadState.done,
              filePath: filePath,
            ));
          } catch (e) {
            final err = DownloadProgress(
              state: DownloadState.error,
              error: 'Failed to launch installer: $e',
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
}
