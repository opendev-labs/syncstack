import 'dart:convert';
import 'package:http/http.dart' as http;

class HFService {
  final String? token;

  HFService(this.token);

  Future<Map<String, dynamic>> getSpaces() async {
    if (token == null || token!.isEmpty) {
      return {'success': false, 'message': 'No Hugging Face token provided'};
    }

    try {
      final response = await http.get(
        Uri.parse('https://huggingface.co/api/spaces'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List spaces = jsonDecode(response.body);
        
        final mappedRepos = spaces.map((s) => {
          'name': s['id'].split('/').last,
          'description': 'Hugging Face Space',
          'full_name': s['id'],
          'clone_url': 'https://huggingface.co/spaces/${s['id']}.git',
          'type': 'hf',
          'raw': s,
        }).toList();

        return {'success': true, 'repos': mappedRepos};
      } else {
        return {'success': false, 'message': 'Hugging Face API Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
