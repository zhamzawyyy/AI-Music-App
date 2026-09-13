import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

/// Thrown for any non-2xx response, carrying the backend's error detail.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Talks to the FastAPI backend. Never calls OpenAI/ModelsLab/AudD directly --
/// those API keys live server-side only.
class ApiClient {
  final String baseUrl;
  final TokenStorage tokenStorage;

  ApiClient({required this.baseUrl, required this.tokenStorage});

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await tokenStorage.getAccessToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeOrThrow(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String detail = 'Request failed';
    try {
      final body = jsonDecode(res.body);
      detail = body['detail']?.toString() ?? detail;
    } catch (_) {}
    throw ApiException(res.statusCode, detail);
  }

  // ---- Auth ----

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _u('/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    _decodeOrThrow(res);
  }

  Future<void> login({required String email, required String password}) async {
    final res = await http.post(
      _u('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decodeOrThrow(res);
    await tokenStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
  }

  Future<void> logout() => tokenStorage.clear();

  // ---- Generation ----

  Future<Map<String, dynamic>> startGeneration(String prompt) async {
    final res = await http.post(
      _u('/generation'),
      headers: await _authHeaders(),
      body: jsonEncode({'prompt': prompt}),
    );
    return _decodeOrThrow(res);
  }

  Future<Map<String, dynamic>> getGenerationStatus(String jobId) async {
    final res = await http.get(_u('/generation/$jobId'), headers: await _authHeaders());
    return _decodeOrThrow(res);
  }

  // ---- Library ----

  Future<List<dynamic>> listTracks() async {
    final res = await http.get(_u('/library'), headers: await _authHeaders());
    return _decodeOrThrow(res) as List<dynamic>;
  }

  Future<void> deleteTrack(String trackId) async {
    final res = await http.delete(_u('/library/$trackId'), headers: await _authHeaders());
    if (res.statusCode != 204) _decodeOrThrow(res);
  }

  // ---- Recognition ----

  Future<Map<String, dynamic>> identifyClip(List<int> audioBytes, String filename) async {
    final headers = await _authHeaders(json: false);
    final request = http.MultipartRequest('POST', _u('/recognition/identify'))
      ..headers.addAll(headers)
      ..files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: filename));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decodeOrThrow(res);
  }
}
