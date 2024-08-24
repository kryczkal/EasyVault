import 'package:easyvault/services/api_client.dart';
import 'package:easyvault/services/api_client_interface.dart';

class Endpoints {
  const Endpoints();
  final String fetchMedia = '/list-bucket-files';
  final String uploadMediaChunk = '/upload-chunk';
  final String finalizeMediaUpload = '/upload-finalize';
  final String downloadAllFiles = '/download-all-files';

  String parseFetchMedia(String sessionId) {
    return '$fetchMedia?session_id=$sessionId';
  }

  String parseUploadMediaChunk(String sessionId) {
    return '$uploadMediaChunk?session_id=$sessionId';
  }

  String parseFinalizeMediaUpload(String sessionId) {
    return '$finalizeMediaUpload?session_id=$sessionId';
  }

  String parseDownloadAllFiles(String sessionId) {
    return '${const Urls().apiUrl}/$downloadAllFiles?session_id=$sessionId';
  }
}

class Urls {
  const Urls();
  final String apiUrl =
      'https://europe-west1-careful-bridge-432408-c6.cloudfunctions.net';
  final String siteUrl = 'https://easyvault.net';

  String parseQrCode(String sessionId) {
    return '$siteUrl/#/session/$sessionId';
  }
}

class Requests {
  const Requests();
  final Map<String, String> defaultHeaders = const {
    'Content-Type': 'application/json',
  };
}

class ApiSettings {
  static const Endpoints endpoints = Endpoints();
  static const Urls urls = Urls();
  static const Requests requests = Requests();

  static IApiClient client = ApiClient(urls.apiUrl);
}
