import 'dart:convert';
import 'package:http/http.dart' as http;

class VercelService {
  final String? token;

  VercelService(this.token);

  Future<Map<String, dynamic>> getProjects() async {
    if (token == null || token!.isEmpty) {
      return {'success': false, 'message': 'No Vercel token provided'};
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.vercel.com/v9/projects'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List projects = data['projects'] ?? [];
        
        // Map to a common format similar to GitHub repos if possible
        final mappedProjects = projects.map((p) => {
          'name': p['name'],
          'description': 'Vercel Project',
          'full_name': p['name'],
          'clone_url': p['link']?['repo'] != null 
              ? 'https://github.com/${p['link']['org']}/${p['link']['repo']}.git'
              : null,
          'type': 'vercel',
          'raw': p,
        }).toList();

        return {'success': true, 'repos': mappedProjects};
      } else {
        return {'success': false, 'message': 'Vercel API Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
