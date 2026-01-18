import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class GHService {
  // Locate the python script
  Future<String> _getScriptPath() async {
    // For development (running from source):
    // We assume the script is at assets/scripts/gh_engine.py relative to project root
    // But when running `flutter run`, the CWD might be different.
    // In a real build, we'd bundle this.
    // For this environment, we know the absolute path from our task.
    return '/home/cube/Gh-sync/opendev-labs/gh-sync-flutter/assets/scripts/gh_engine.py';
  }

  Future<Map<String, dynamic>> _runPython(List<String> args) async {
    try {
      final scriptPath = await _getScriptPath();
      final result = await Process.run('python3', [scriptPath, ...args]);

      if (result.exitCode != 0) {
        return {
          'success': false,
          'message': 'Process exited with code ${result.exitCode}: ${result.stderr}'
        };
      }

      final output = result.stdout.toString().trim();
      if (output.isEmpty) {
         return {'success': false, 'message': 'Empty output from python script'};
      }

      try {
        return jsonDecode(output);
      } catch (e) {
        return {'success': false, 'message': 'Failed to parse JSON: $output'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Execution error: $e'};
    }
  }

  // Auth
  Future<Map<String, dynamic>> validateToken(String username, String token) async {
    return _runPython(['validate', username, token]);
  }

  // Repos
  Future<Map<String, dynamic>> getUserRepos(String token) async {
    return _runPython(['get_repos', token]);
  }

  Future<Map<String, dynamic>> getRepoStatus(String path) async {
    return _runPython(['get_status', path]);
  }

  // Sync
  Future<Map<String, dynamic>> syncRepo(String path, String name, String url, String token, String strategy) async {
    return _runPython(['sync', path, name, url, token, strategy]);
  }
}
