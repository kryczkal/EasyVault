import 'package:wed_pic_frontend/services/ApiClient.dart';
import 'package:wed_pic_frontend/services/IApiClient.dart';

class ApiSettings {
  static const String apiUrl =
      'https://europe-west1-careful-bridge-432408-c6.cloudfunctions.net';
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  static const String fetchMediaEndpoint = '/list-bucket-files-2';
  static const String uploadMediaChunkEndpoint = '/upload-chunk';
  static const String finalizeMediaUploadEndpoint = '/upload-finalize';

  static IApiClient client = ApiClient(ApiSettings.apiUrl);
}
