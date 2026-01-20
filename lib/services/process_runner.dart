import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// Handles running local development servers and processes
class ProcessRunner {
  Process? _currentProcess;
  final StreamController<String> _outputController = StreamController<String>.broadcast();
  String? _serverUrl;
  bool _isRunning = false;

  Stream<String> get outputStream => _outputController.stream;
  String? get serverUrl => _serverUrl;
  bool get isRunning => _isRunning;

  /// Start a development server based on project type
  Future<Map<String, dynamic>> startDevServer(String projectPath, String projectType) async {
    try {
      // Stop any existing process
      await stop();

      String command;
      List<String> args;
      
      switch (projectType) {
        case 'react':
        case 'vue':
        case 'next':
        case 'vite':
        case 'nodejs':
          // Check if node_modules exists
          final nodeModules = Directory('$projectPath/node_modules');
          if (!await nodeModules.exists()) {
            _addOutput('📦 Installing dependencies...');
            await _runCommand(projectPath, 'npm', ['install']);
            _addOutput('✓ Dependencies installed');
          }
          
          // Run dev server
          command = 'npm';
          args = ['run', 'dev'];
          break;
          
        case 'python':
          command = 'python3';
          args = ['-m', 'http.server', '8000'];
          _serverUrl = 'http://localhost:8000';
          break;
          
        case 'static':
        default:
          // Use Python's simple HTTP server for static files
          command = 'python3';
          args = ['-m', 'http.server', '8080'];
          _serverUrl = 'http://localhost:8080';
          break;
      }

      _addOutput('🚀 Starting development server...');
      _addOutput(r'$ ' + '$command ${args.join(' ')}');
      
      _currentProcess = await Process.start(
        command,
        args,
        workingDirectory: projectPath,
        runInShell: true,
      );

      _isRunning = true;

      // Listen to stdout
      _currentProcess!.stdout.transform(utf8.decoder).listen((data) {
        _addOutput(data);
        _parseServerUrl(data, projectType);
      });

      // Listen to stderr
      _currentProcess!.stderr.transform(utf8.decoder).listen((data) {
        _addOutput('[ERROR] $data');
      });

      // Listen to exit
      _currentProcess!.exitCode.then((exitCode) {
        _isRunning = false;
        _addOutput('Process exited with code $exitCode');
        if (exitCode != 0) {
          _serverUrl = null;
        }
      });

      // Wait a bit for the server to start
      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'serverUrl': _serverUrl,
        'message': 'Development server started',
      };
    } catch (e) {
      _isRunning = false;
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Run a custom command
  Future<Map<String, dynamic>> runCommand(String projectPath, String command, List<String> args) async {
    try {
      _addOutput(r'$ ' + '$command ${args.join(' ')}');
      
      final result = await Process.run(
        command,
        args,
        workingDirectory: projectPath,
        runInShell: true,
      );

      _addOutput(result.stdout.toString());
      if (result.stderr.toString().isNotEmpty) {
        _addOutput('[ERROR] ${result.stderr}');
      }

      return {
        'success': result.exitCode == 0,
        'exitCode': result.exitCode,
        'stdout': result.stdout.toString(),
        'stderr': result.stderr.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Install npm dependencies
  Future<Map<String, dynamic>> installDependencies(String projectPath) async {
    return await _runCommand(projectPath, 'npm', ['install']);
  }

  /// Build project
  Future<Map<String, dynamic>> buildProject(String projectPath) async {
    return await _runCommand(projectPath, 'npm', ['run', 'build']);
  }

  /// Stop the running process
  Future<void> stop() async {
    if (_currentProcess != null) {
      _addOutput('Stopping server...');
      _currentProcess!.kill();
      _currentProcess = null;
      _isRunning = false;
      _serverUrl = null;
      _addOutput('Server stopped');
    }
  }

  /// Check if npm is available
  Future<bool> isNpmAvailable() async {
    try {
      final result = await Process.run('npm', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if python is available
  Future<bool> isPythonAvailable() async {
    try {
      final result = await Process.run('python3', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  void _addOutput(String output) {
    if (!_outputController.isClosed) {
      _outputController.add(output);
    }
  }

  Future<Map<String, dynamic>> _runCommand(String workingDir, String command, List<String> args) async {
    try {
      _addOutput(r'$ ' + '$command ${args.join(' ')}');
      
      final process = await Process.start(
        command,
        args,
        workingDirectory: workingDir,
        runInShell: true,
      );

      process.stdout.transform(utf8.decoder).listen(_addOutput);
      process.stderr.transform(utf8.decoder).listen((data) => _addOutput('[ERROR] $data'));

      final exitCode = await process.exitCode;

      return {
        'success': exitCode == 0,
        'exitCode': exitCode,
      };
    } catch (e) {
      _addOutput('[ERROR] $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  void _parseServerUrl(String output, String projectType) {
    if (_serverUrl != null) return; // Already found

    final patterns = [
      RegExp(r'Local:\s+https?://[^\s]+'),
      RegExp(r'http://localhost:\d+'),
      RegExp(r'Server running (?:at|on) (https?://[^\s]+)'),
      RegExp(r'ready on (https?://[^\s]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(output);
      if (match != null) {
        _serverUrl = match.group(0)!.replaceAll(RegExp(r'Local:\s+'), '');
        _addOutput('✓ Server URL detected: $_serverUrl');
        break;
      }
    }
  }

  void dispose() {
    stop();
    _outputController.close();
  }
}
