abstract class IApiClient {
  Future<dynamic> getRequest(String endpoint, {Map<String, String>? headers});
  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers});
  Future<dynamic> postBinaryRequest(String endpoint, List<int> bodyBytes,
      {Map<String, String>? headers});
}
