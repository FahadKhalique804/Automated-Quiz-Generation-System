import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl =
      "http://192.222.18.77"; // use your server IP when testing on device

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse("$baseUrl/$endpoint"));
    return _processResponse(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("API Error: ${response.statusCode} ${response.body}");
    }
  }
}
