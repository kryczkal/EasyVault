import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:wed_pic_frontend/services/ApiSettings.dart';
import 'dart:convert';

import 'IApiClient.dart';

class ApiClient implements IApiClient {
  final String baseUrl;
  final http.Client client;
  var logger = Logger();

  ApiClient(this.baseUrl, {http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<dynamic> getRequest(String endpoint,
      {Map<String, String>? headers = const {
        'Content-Type': 'application/json'
      }}) async {
    logger.i('GET request to ${Uri.parse('$baseUrl$endpoint')}');

    try {
      final response =
          await client.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  @override
  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers = ApiSettings.defaultHeaders}) async {
    logger.i('POST request to ${Uri.parse('$baseUrl$endpoint')}');
    try {
      final response = await client.post(
        Uri.parse('$baseUrl$endpoint'),
        body: json.encode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<dynamic> postBinaryRequest(String endpoint, List<int> bodyBytes,
      {Map<String, String>? headers}) async {
    logger.i('POST binary request to ${Uri.parse('$baseUrl$endpoint')}');
    try {
      final response = await client.post(
        Uri.parse('$baseUrl$endpoint'),
        body: bodyBytes,
        headers: headers ?? {'Content-Type': 'application/octet-stream'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post binary data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
