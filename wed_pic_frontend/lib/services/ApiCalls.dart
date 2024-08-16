import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';

class ApiCalls {
  static final ApiCalls _instance = ApiCalls._internal();

  factory ApiCalls() {
    return _instance;
  }

  ApiCalls._internal();

  Future<void> uploadMediaInChunks(String sessionId, XFile media,
      Function(double) uploadProgressUpdateHandler) async {
    var requestUrl =
        '${ApiSettings.uploadMediaChunkEndpoint}?session_id=$sessionId';

    final bytes = await media.readAsBytes();
    const chunkSize = 1024 * 1024; // 1MB chunks
    final totalChunks = (bytes.length / chunkSize).ceil();
    final fileId = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end =
          start + chunkSize > bytes.length ? bytes.length : start + chunkSize;
      final Uint8List chunk = bytes.sublist(start, end);

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

      uploadProgressUpdateHandler((i + 1) / totalChunks);
    }

    await finalizeUpload(sessionId, fileId);
  }

  Future<void> finalizeUpload(String sessionId, String fileId) async {
    var finalizeUrl =
        '${ApiSettings.finalizeMediaUploadEndpoint}?session_id=$sessionId';

    await ApiSettings.client.postRequest(
      finalizeUrl,
      {'fileId': fileId},
    );
  }
}
