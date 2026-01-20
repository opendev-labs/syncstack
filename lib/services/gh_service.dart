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
    return '/home/cube/syncstack/opendev-labs/syncstack/assets/scripts/gh_engine.py';
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

  Future<Map<String, dynamic>> syncRepo(String path, String name, String url, String token, String strategy) async {
    return _runPython(['sync', path, name, url, token, strategy]);
  }

  // New methods for enhanced git visualization
  Future<Map<String, dynamic>> getDetailedStatus(String path) async {
    return _runPython(['get_detailed_status', path]);
  }

  Future<Map<String, dynamic>> getFileDiff(String path, String file) async {
    return _runPython(['get_file_diff', path, file]);
  }

  // GitHub Actions
  Future<Map<String, dynamic>> getWorkflows(String token, String repo) async {
    return _runPython(['get_workflows', token, repo]);
  }

  Future<Map<String, dynamic>> getWorkflowRuns(String token, String repo) async {
    return _runPython(['get_workflow_runs', token, repo]);
  }

  Future<Map<String, dynamic>> triggerWorkflow(String token, String repo, String workflowId, {String ref = 'main'}) async {
    return _runPython(['trigger_workflow', token, repo, workflowId, ref]);
  }

  Future<Map<String, dynamic>> createRepo(String token, String name, String description, {bool private = false}) async {
    return _runPython(['create_repo', token, name, description, private.toString()]);
  }

  Future<Map<String, dynamic>> getGitGraph(String path) async {
    return _runPython(['get_git_graph', path]);
  }

  Future<Map<String, dynamic>> getBulkStatus(List<Map<String, String>> repos) async {
    return _runPython(['get_bulk_status', jsonEncode(repos)]);
  }

  Future<Map<String, dynamic>> scaffoldRepo(String path, String templateName) async {
    return _runPython(['scaffold_repo', path, templateName]);
  }

  Future<Map<String, dynamic>> getRunJobs(String token, String repoFullName, String runId) async {
    return _runPython(['get_run_jobs', token, repoFullName, runId]);
  }

  Future<Map<String, dynamic>> scanLocal(String path, {int depth = 3}) async {
    return _runPython(['scan_local', path, depth.toString()]);
  }

  Future<Map<String, dynamic>> getRemoteDiff(String path, String branch) async {
    return _runPython(['get_remote_diff', path, branch]);
  }

  Future<Map<String, dynamic>> exportSandbox(String html, String css, String js) async {
    return _runPython(['export_sandbox', html, css, js]);
  }

  Future<Map<String, dynamic>> deploySandbox(String path, String html, String css, String js, String commitMsg) async {
    return _runPython(['deploy_sandbox', path, html, css, js, commitMsg]);
  }
}
