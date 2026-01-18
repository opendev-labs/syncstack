import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class GHService {
  // Locate the python script
  Future<String> _getScriptPath() async {
    // 1. Check if we are running in a SNAP environment
    final snapPath = Platform.environment['SNAP'];
    if (snapPath != null) {
      return p.join(snapPath, 'data/flutter_assets/assets/scripts/gh_engine.py');
    }

    // 2. Check for the bundled asset relative to the executable (Linux release/bundle)
    final executableDir = p.dirname(Platform.resolvedExecutable);
    final bundledPath = p.join(executableDir, 'data', 'flutter_assets', 'assets', 'scripts', 'gh_engine.py');
    
    if (await File(bundledPath).exists()) {
      return bundledPath;
    }

    // 3. Fallback to the absolute development path
    return '/home/cube/Gh-sync/opendev-labs/gh-sync-desk/assets/scripts/gh_engine.py';
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
