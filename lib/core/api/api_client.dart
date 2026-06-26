import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_entry.dart';

class ApiClient {
  final String baseUrl;

  const ApiClient(this.baseUrl);

  // Encodes each segment with Uri.encodeComponent (covers Chinese, spaces,
  // special chars) and joins with '/'. Safe for URL path segments.
  static String _encodeSegments(List<String> segments) =>
      segments.map(Uri.encodeComponent).join('/');

  Future<List<FileEntry>> listFolder(List<String> pathSegments) async {
    // Root → /api/files/   Subpath → /api/files/seg1/seg2
    final path = pathSegments.isEmpty
        ? 'api/files/'
        : 'api/files/${_encodeSegments(pathSegments)}';
    final uri = Uri.parse('http://$baseUrl/$path');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to list folder (${response.statusCode})');
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final list = (body['entries'] as List<dynamic>?) ?? [];
    return list
        .map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String imageUrl(List<String> pathSegments, String filename) =>
      'http://$baseUrl/api/raw/${_encodeSegments([...pathSegments, filename])}';
}
