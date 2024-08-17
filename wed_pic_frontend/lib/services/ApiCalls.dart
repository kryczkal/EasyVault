import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';

class ApiCalls {
  static final ApiCalls _instance = ApiCalls._internal();

  factory ApiCalls() {
    return _instance;
  }

  ApiCalls._internal();

  int adaptiveChunkSize(int baseChunkSize, double networkSpeedFactor) {
    return max(256, (baseChunkSize * networkSpeedFactor).toInt());
  }

  Future<void> exponentialBackoffRetry(
      Function uploadChunk, int maxAttempts) async {
    int attempts = 0;
    int delayMs = 100;
    while (attempts < maxAttempts) {
      try {
        await uploadChunk();
        return;
      } catch (e) {
        attempts += 1;
        if (attempts >= maxAttempts) {
          throw Exception('Failed after $attempts attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
  }

  Future<void> uploadMediaInChunks(String sessionId, XFile media,
      Function(double) uploadProgressUpdateHandler) async {
    var requestUrl =
        '${ApiSettings.uploadMediaChunkEndpoint}?session_id=$sessionId';

    final bytes = await media.readAsBytes();
    int baseChunkSizeB = 1024 * 1024; // 1MB
    double networkSpeedFactor = 1.0;

    int chunkSize = adaptiveChunkSize(baseChunkSizeB, networkSpeedFactor);
    final totalChunks = (bytes.length / chunkSize).ceil();
    final fileId = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end =
          start + chunkSize > bytes.length ? bytes.length : start + chunkSize;
      final Uint8List chunk = bytes.sublist(start, end);

      await exponentialBackoffRetry(() async {
        await ApiSettings.client.postBinaryRequest(
          requestUrl,
          chunk,
          headers: {
            'Content-Type': 'application/octet-stream',
            'X-File-Id': fileId,
            'X-Chunk-Index': i.toString(),
            'X-Total-Chunks': totalChunks.toString(),
          },
        );
      }, 6);

      uploadProgressUpdateHandler((i + 1) / totalChunks);
    }

    await finalizeUpload(sessionId, fileId, media.name);
  }

  Future<void> finalizeUpload(
      String sessionId, String fileId, String fileName) async {
    var finalizeUrl =
        '${ApiSettings.finalizeMediaUploadEndpoint}?session_id=$sessionId';

    await exponentialBackoffRetry(() async {
      await ApiSettings.client.postRequest(
        finalizeUrl,
        {'fileId': fileId, 'fileName': fileName},
      );
    }, 6);
  }
}
