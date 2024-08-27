import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:easyvault/models/media.dart';
import 'package:easyvault/services/api_settings.dart';

class ApiCalls {
  static final ApiCalls _instance = ApiCalls._internal();
  factory ApiCalls() {
    return _instance;
  }
  ApiCalls._internal();

  static int adaptiveChunkSize(int baseChunkSize, double networkSpeedFactor) {
    return max(256, (baseChunkSize * networkSpeedFactor).toInt());
  }

  static Future<void> exponentialBackoffRetry(
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

  //  __    __  .______    __        ______        ___       _______
  // |  |  |  | |   _  \  |  |      /  __  \      /   \     |       \
  // |  |  |  | |  |_)  | |  |     |  |  |  |    /  ^  \    |  .--.  |
  // |  |  |  | |   ___/  |  |     |  |  |  |   /  /_\  \   |  |  |  |
  // |  `--'  | |  |      |  `----.|  `--'  |  /  _____  \  |  '--'  |
  //  \______/  | _|      |_______| \______/  /__/     \__\ |_______/

  static Future<void> uploadMediaInChunks(String sessionId, XFile media,
      Function(double) uploadProgressUpdateHandler) async {
    var requestUrl = ApiSettings.endpoints.parseUploadMediaChunk(sessionId);

    final bytes = await media.readAsBytes();
    int baseChunkSizeB = 1024 * 1024; // 1MB
    double networkSpeedFactor = 1.0;

    int chunkSize = adaptiveChunkSize(baseChunkSizeB, networkSpeedFactor);
    final totalChunks = (bytes.length / chunkSize).ceil();
    final fileId =
        "${DateTime.now().millisecondsSinceEpoch.toString()}-${media.name}";

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
            'X-Chunk-Index': (i + 1).toString(),
            'X-Total-Chunks': totalChunks.toString(),
          },
        );
      }, 6);

      uploadProgressUpdateHandler((i + 1) / totalChunks);
    }

    await finalizeUpload(sessionId, fileId, media.name);
  }

  static Future<void> finalizeUpload(
      String sessionId, String fileId, String fileName) async {
    var finalizeUrl = ApiSettings.endpoints.parseFinalizeMediaUpload(sessionId);

    await exponentialBackoffRetry(() async {
      await ApiSettings.client.postRequest(
        finalizeUrl,
        {},
        headers: {'X-File-Id': fileId, 'X-File-Name': fileName},
      );
    }, 6);
  }

  //  _______  _______ .___________.  ______  __    __
  // |   ____||   ____||           | /      ||  |  |  |
  // |  |__   |  |__   `---|  |----`|  ,----'|  |__|  |
  // |   __|  |   __|      |  |     |  |     |   __   |
  // |  |     |  |____     |  |     |  `----.|  |  |  |
  // |__|     |_______|    |__|      \______||__|  |__|

  static Future<List<Media>> fetchMedia(String sessionId) {
    var requestUrl = ApiSettings.endpoints.parseFetchMedia(sessionId);

    try {
      return ApiSettings.client.getRequest(requestUrl).then((data) {
        try {
          List<Media> mediaItems = [];
          for (var item in data) {
            mediaItems.add(Media.fromJson(item));
          }
          return mediaItems;
        } on Exception catch (e) {
          Logger().e('Failed to load media items: $e');
          return [];
        }
      });
    } on Exception catch (e) {
      Logger().e('Failed to load media items: $e');
      return Future.value([]);
    }
  }
}
