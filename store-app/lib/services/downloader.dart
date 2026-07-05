import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Streams an APK to the app's external cache with progress callbacks, so the UI
// can show a real download bar before the install dialog appears.
//
// Resumable: a network drop (Wi-Fi/mobile data switch, signal loss) leaves the
// partial file in place instead of discarding it -- retrying the same
// (id, version) sends a Range request continuing from the bytes already on
// disk instead of starting over. Also survives the app being killed mid-
// download entirely, since cleanupApks() no longer blindly deletes every APK
// (see below).
class Downloader {
  Future<File> download(
    String url,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getExternalCacheDirectories();
    final base = (dir != null && dir.isNotEmpty)
        ? dir.first
        : await getTemporaryDirectory();
    final file = File("${base.path}/$fileName");

    final alreadyOnDisk = await file.exists() ? await file.length() : 0;

    final req = http.Request("GET", Uri.parse(url));
    if (alreadyOnDisk > 0) {
      req.headers["Range"] = "bytes=$alreadyOnDisk-";
    }
    final res = await http.Client().send(req);

    // 416 = the range we asked for starts beyond what the server has, i.e.
    // the file on disk is already the complete download (e.g. it finished
    // last time but the app closed before the install handoff ran) -- reuse
    // it as-is instead of re-fetching anything.
    if (res.statusCode == 416) {
      onProgress?.call(1);
      return file;
    }
    // Server may not support Range (200 instead of 206) -- start clean in
    // that case rather than corrupting the file by appending onto a full
    // copy that's about to be re-sent from byte 0.
    final resuming = alreadyOnDisk > 0 && res.statusCode == 206;
    if (res.statusCode != 200 && res.statusCode != 206) {
      throw Exception("download ${res.statusCode}");
    }

    final total = resuming
        ? alreadyOnDisk + (res.contentLength ?? 0)
        : (res.contentLength ?? 0);
    var received = resuming ? alreadyOnDisk : 0;
    final sink = file.openWrite(mode: resuming ? FileMode.append : FileMode.write);
    try {
      await for (final chunk in res.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) onProgress?.call(received / total);
      }
    } catch (e) {
      // Network dropped mid-stream (Wi-Fi/mobile data switch, signal loss):
      // leave the partial file on disk so the next attempt resumes instead
      // of re-downloading everything already received.
      await sink.close();
      rethrow;
    }
    await sink.close();
    return file;
  }

  // Age-based, not unconditional: only deletes .apk files untouched for
  // longer than [minAge] (default 15 minutes). A file actively mid-download
  // keeps getting written to (fresh mtime); a just-completed download is
  // fresh too, so closing the app right after a download finishes -- before
  // the install handoff runs -- no longer loses it. Only genuinely abandoned
  // downloads (old attempts, since-superseded versions) actually get swept.
  Future<void> cleanupApks({Duration minAge = const Duration(minutes: 15)}) async {
    try {
      final dirs = await getExternalCacheDirectories();
      final base = (dirs != null && dirs.isNotEmpty)
          ? dirs.first
          : await getTemporaryDirectory();
      final cutoff = DateTime.now().subtract(minAge);
      for (final f in base.listSync()) {
        if (f is File && f.path.toLowerCase().endsWith(".apk")) {
          try {
            if (f.lastModifiedSync().isBefore(cutoff)) f.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
