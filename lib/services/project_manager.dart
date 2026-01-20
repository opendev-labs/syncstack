import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

/// Manages project workspaces and file operations for the IDE
class ProjectManager {
  final String workspaceRoot;
  String? currentProjectPath;
  Map<String, dynamic> fileTree = {};

  ProjectManager({String? customRoot})
      : workspaceRoot = customRoot ?? p.join(Platform.environment['HOME'] ?? '/tmp', '.syncstack-data', 'projects');

  /// Initialize workspace directory
  Future<void> initialize() async {
    final dir = Directory(workspaceRoot);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Create a new empty project
  Future<Map<String, dynamic>> createProject(String name) async {
    try {
      final projectId = '${name}_${DateTime.now().millisecondsSinceEpoch}';
      final projectPath = p.join(workspaceRoot, projectId);
      
      final dir = Directory(projectPath);
      await dir.create(recursive: true);
      
      // Create default files
      await File(p.join(projectPath, 'index.html')).writeAsString(
        '<!DOCTYPE html>\n<html>\n<head>\n  <title>$name</title>\n  <link rel="stylesheet" href="style.css">\n</head>\n<body>\n  <h1>$name</h1>\n  <script src="app.js"></script>\n</body>\n</html>'
      );
      
      await File(p.join(projectPath, 'style.css')).writeAsString(
        'body {\n  background: #0a0a0a;\n  color: #00ff41;\n  font-family: "Inter", sans-serif;\n  padding: 20px;\n}\n\nh1 {\n  font-size: 2rem;\n}'
      );
      
      await File(p.join(projectPath, 'app.js')).writeAsString(
        'console.log("$name initialized");\n'
      );
      
      currentProjectPath = projectPath;
      await _scanDirectory(projectPath);
      
      return {
        'success': true,
        'projectId': projectId,
        'path': projectPath,
        'fileTree': fileTree,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Upload and extract a zip file
  Future<Map<String, dynamic>> uploadZip(String zipPath) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final projectName = p.basenameWithoutExtension(zipPath);
      final projectId = '${projectName}_${DateTime.now().millisecondsSinceEpoch}';
      final projectPath = p.join(workspaceRoot, projectId);
      
      await Directory(projectPath).create(recursive: true);
      
      // Extract all files
      for (final file in archive) {
        final filename = p.join(projectPath, file.name);
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }
      
      currentProjectPath = projectPath;
      await _scanDirectory(projectPath);
      
      // Detect project type
      final projectType = await _detectProjectType(projectPath);
      
      return {
        'success': true,
        'projectId': projectId,
        'path': projectPath,
        'fileTree': fileTree,
        'projectType': projectType,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Upload individual files
  Future<Map<String, dynamic>> uploadFiles(List<String> filePaths, {String? targetDir}) async {
    try {
      if (currentProjectPath == null) {
        return {'success': false, 'message': 'No active project'};
      }
      
      final destination = targetDir ?? currentProjectPath!;
      
      for (final filePath in filePaths) {
        final fileName = p.basename(filePath);
        final targetPath = p.join(destination, fileName);
        await File(filePath).copy(targetPath);
      }
      
      await _scanDirectory(currentProjectPath!);
      
      return {
        'success': true,
        'fileTree': fileTree,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Open an existing project
  Future<Map<String, dynamic>> openProject(String projectPath) async {
    try {
      final dir = Directory(projectPath);
      if (!await dir.exists()) {
        return {'success': false, 'message': 'Project directory not found'};
      }
      
      currentProjectPath = projectPath;
      await _scanDirectory(projectPath);
      
      final projectType = await _detectProjectType(projectPath);
      
      return {
        'success': true,
        'path': projectPath,
        'fileTree': fileTree,
        'projectType': projectType,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Read file content
  Future<Map<String, dynamic>> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'File not found'};
      }
      
      final content = await file.readAsString();
      return {
        'success': true,
        'content': content,
        'path': filePath,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Write file content
  Future<Map<String, dynamic>> writeFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      
      return {
        'success': true,
        'path': filePath,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create new file
  Future<Map<String, dynamic>> createFile(String fileName, {String? targetDir}) async {
    try {
      if (currentProjectPath == null) {
        return {'success': false, 'message': 'No active project'};
      }
      
      final destination = targetDir ?? currentProjectPath!;
      final filePath = p.join(destination, fileName);
      
      final file = File(filePath);
      if (await file.exists()) {
        return {'success': false, 'message': 'File already exists'};
      }
      
      await file.create(recursive: true);
      await file.writeAsString('');
      
      await _scanDirectory(currentProjectPath!);
      
      return {
        'success': true,
        'path': filePath,
        'fileTree': fileTree,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delete file or directory
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final file = File(path);
      final dir = Directory(path);
      
      if (await file.exists()) {
        await file.delete();
      } else if (await dir.exists()) {
        await dir.delete(recursive: true);
      } else {
        return {'success': false, 'message': 'Path not found'};
      }
      
      if (currentProjectPath != null) {
        await _scanDirectory(currentProjectPath!);
      }
      
      return {
        'success': true,
        'fileTree': fileTree,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// List all projects in workspace
  Future<List<Map<String, dynamic>>> listProjects() async {
    try {
      final dir = Directory(workspaceRoot);
      if (!await dir.exists()) {
        return [];
      }
      
      final projects = <Map<String, dynamic>>[];
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final stat = await entity.stat();
          projects.add({
            'name': p.basename(entity.path),
            'path': entity.path,
            'modified': stat.modified.toIso8601String(),
          });
        }
      }
      
      return projects;
    } catch (e) {
      return [];
    }
  }

  /// Scan directory and build file tree
  Future<void> _scanDirectory(String path) async {
    fileTree = await _buildTree(path, path);
  }

  /// Recursively build file tree
  Future<Map<String, dynamic>> _buildTree(String rootPath, String currentPath) async {
    final tree = <String, dynamic>{
      'name': p.basename(currentPath),
      'path': currentPath,
      'type': 'directory',
      'children': [],
    };
    
    try {
      final dir = Directory(currentPath);
      final entities = await dir.list().toList();
      
      // Sort: directories first, then files
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p.basename(a.path).compareTo(p.basename(b.path));
      });
      
      for (final entity in entities) {
        final name = p.basename(entity.path);
        
        // Skip hidden files and node_modules
        if (name.startsWith('.') || name == 'node_modules') continue;
        
        if (entity is Directory) {
          final subtree = await _buildTree(rootPath, entity.path);
          tree['children'].add(subtree);
        } else if (entity is File) {
          tree['children'].add({
            'name': name,
            'path': entity.path,
            'type': 'file',
            'extension': p.extension(name),
          });
        }
      }
    } catch (e) {
      tree['error'] = e.toString();
    }
    
    return tree;
  }

  /// Detect project type based on files
  Future<String> _detectProjectType(String projectPath) async {
    // Check for package.json
    final packageJson = File(p.join(projectPath, 'package.json'));
    if (await packageJson.exists()) {
      final content = await packageJson.readAsString();
      final json = jsonDecode(content);
      
      // Check dependencies
      final deps = json['dependencies'] as Map<String, dynamic>? ?? {};
      final devDeps = json['devDependencies'] as Map<String, dynamic>? ?? {};
      
      if (deps.containsKey('react') || devDeps.containsKey('react')) return 'react';
      if (deps.containsKey('vue') || devDeps.containsKey('vue')) return 'vue';
      if (deps.containsKey('next') || devDeps.containsKey('next')) return 'next';
      if (deps.containsKey('vite') || devDeps.containsKey('vite')) return 'vite';
      
      return 'nodejs';
    }
    
    // Check for requirements.txt
    final requirements = File(p.join(projectPath, 'requirements.txt'));
    if (await requirements.exists()) return 'python';
    
    // Check for index.html
    final indexHtml = File(p.join(projectPath, 'index.html'));
    if (await indexHtml.exists()) return 'static';
    
    return 'unknown';
  }

  /// Get project type display name
  String getProjectTypeDisplay(String type) {
    switch (type) {
      case 'react': return 'React App';
      case 'vue': return 'Vue App';
      case 'next': return 'Next.js App';
      case 'vite': return 'Vite App';
      case 'nodejs': return 'Node.js Project';
      case 'python': return 'Python Project';
      case 'static': return 'Static HTML';
      default: return 'Unknown Project';
    }
  }
}
