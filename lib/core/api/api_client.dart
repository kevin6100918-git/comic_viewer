import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_entry.dart';

class ApiClient {
  final String baseUrl;

  const ApiClient(this.baseUrl);

  // Encodes each path segment individually, joins with encoded slash, and prepends %2F.
  // e.g. ['漫畫', '作者?名'] → '%2F%E6%BC%AB%E7%95%AB%2F%E4%BD%9C%E8%80%85%3F%E5%90%8D'
  // The server requires a leading / in the path parameter value.
  String _encodePath(List<String> segments) =>
      '%2F${segments.map(Uri.encodeQueryComponent).join('%2F')}';

  Future<List<FileEntry>> listFolder(
    List<String> pathSegments, {
    String sortingVote = 'name',
    String sortingMethod = 'ASC',
  }) async {
    final encodedPath = _encodePath(pathSegments);
    final uri = Uri.parse(
      'http://$baseUrl/api/cloud-drive/folder?path=$encodedPath'
      '&sortingVote=$sortingVote&sortingMethod=$sortingMethod',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to list folder (${response.statusCode})');
    }
    final list =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list
        .map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String imageUrl(List<String> pathSegments, String filename) {
    final encodedPath = _encodePath(pathSegments);
    final encodedFile = Uri.encodeQueryComponent(filename);
    return 'http://$baseUrl/cloud-drive/image?path=$encodedPath&file=$encodedFile';
  }
}
