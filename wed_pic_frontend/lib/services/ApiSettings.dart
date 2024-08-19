import 'package:wed_pic_frontend/services/ApiClient.dart';
import 'package:wed_pic_frontend/services/IApiClient.dart';

class Endpoints {
  const Endpoints();
  final String fetchMedia = '/list-bucket-files-2';
  final String uploadMediaChunk = '/upload-chunk';
  final String finalizeMediaUpload = '/upload-finalize';

  String parseFetchMedia(String sessionId) {
    return '$fetchMedia?session_id=$sessionId';
  }

  String parseUploadMediaChunk(String sessionId) {
    return '$uploadMediaChunk?session_id=$sessionId';
  }

  String parseFinalizeMediaUpload(String sessionId) {
    return '$finalizeMediaUpload?session_id=$sessionId';
  }
}

class Urls {
  const Urls();
  final String apiUrl =
      'https://europe-west1-careful-bridge-432408-c6.cloudfunctions.net';
  final String siteUrl = 'https://careful-bridge-432408-c6.ew.r.appspot.com';

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
