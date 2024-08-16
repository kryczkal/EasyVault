import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

import 'IClientService.dart';

class BackendService implements IClientService {
  final String baseUrl;
  final http.Client client;
  var logger = Logger();

  BackendService(this.baseUrl, {http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<dynamic> getRequest(String endpoint) async {
    logger.i('GET request to ${Uri.parse('$baseUrl$endpoint')}');
    try {
      final response = await client.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  @override
  Future<dynamic> postRequest(
      String endpoint, Map<String, dynamic> body) async {
    logger.i('POST request to ${Uri.parse('$baseUrl$endpoint')}');
    try {
      final response = await client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
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
}
