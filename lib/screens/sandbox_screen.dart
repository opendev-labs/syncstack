import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/project_manager.dart';
import '../services/process_runner.dart';
import '../services/gh_service.dart';
import '../widgets/file_tree_view.dart';
import '../widgets/editor_tabs.dart';
import '../providers/auth_provider.dart';

class WebEditorScreen extends StatefulWidget {
  const WebEditorScreen({super.key});

  @override
  State<WebEditorScreen> createState() => _WebEditorScreenState();
}

class _WebEditorScreenState extends State<WebEditorScreen> {
  late ProjectManager _projectManager;
  late ProcessRunner _processRunner;
  final GHService _ghService = GHService();
  
  Map<String, dynamic> _fileTree = {};
  final Map<String, CodeController> _editors = {};
  final List<EditorTab> _openTabs = [];
  String? _activeTab;
  String? _projectType;
  bool _isServerRunning = false;
  final List<String> _consoleLogs = [];
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _projectManager = ProjectManager();
    _processRunner = ProcessRunner();
    _projectManager.initialize();
    
    // Listen to process output
    _processRunner.outputStream.listen((output) {
      setState(() => _consoleLogs.add(output));
    });
    
    if (!Platform.isLinux) {
      try {
        _webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFFFFFFF));
      } catch (e) {
        _consoleLogs.add('WebView Error: $e');
      }
    } else {
      _consoleLogs.add('System: Platform Linux detected. Live preview will use fallback renderer.');
    }
  }

  @override
  void dispose() {
    _processRunner.dispose();
    for (var controller in _editors.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // File Tree Sidebar
                SizedBox(
                  width: 250,
                  child: FileTreeView(
                    fileTree: _fileTree,
                    selectedFile: _activeTab,
                    onFileSelected: _openFile,
                    onNewFile: _createNewFile,
                  ),
                ),
                
                // Editor Area
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(color: AppTheme.borderGlow),
                      ),
                    ),
                    child: Column(
                      children: [
                        EditorTabs(
                          tabs: _openTabs,
                          activeTab: _activeTab,
                          onTabSelected: (path) => setState(() => _activeTab = path),
                          onTabClosed: _closeTab,
                        ),
                        Expanded(
                          child: _activeTab != null
                              ? _buildEditor(_activeTab!)
                              : _buildEmptyEditor(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Live Preview Panel
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildPreviewHeader(),
                        Expanded(
                          child: _isServerRunning && _processRunner.serverUrl != null
                              ? _webController != null
                                  ? WebViewWidget(controller: _webController!)
                                  : _buildLinuxPreviewFallback()
                              : _buildPreviewPlaceholder(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Terminal/Console Panel
          _buildTerminal(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceBlack,
      toolbarHeight: 60,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SYNCSTACK IDE', style: TextStyle(letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
          Text(
            _projectType != null 
                ? '${_projectManager.getProjectTypeDisplay(_projectType!)} • ${_projectManager.currentProjectPath?.split('/').last ?? ''}'
                : 'FULL-STACK DEVELOPMENT ENVIRONMENT',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 9, letterSpacing: 1),
          ),
        ],
      ),
      actions: [
        _buildImportMenu(),
        const SizedBox(width: 8),
        _buildActionButton(Icons.add_box, 'NEW PROJECT', _createNewProject),
        const SizedBox(width: 12),
        _buildActionButton(
          _isServerRunning ? Icons.stop : Icons.play_arrow,
          _isServerRunning ? 'STOP' : 'RUN',
          _toggleServer,
          isPrimary: !_isServerRunning,
        ),
        const SizedBox(width: 8),
        _buildActionButton(Icons.open_in_browser, 'BROWSER', _openInBrowser),
        const SizedBox(width: 8),
        _buildActionButton(Icons.settings, 'SETTINGS', _showSettings),
        const SizedBox(width: 8),
        _buildActionButton(Icons.cloud_upload, 'PUBLISH', _publishToGitHub, isPrimary: true),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed, {bool isPrimary = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.cyanAccent : Colors.transparent,
          border: Border.all(color: AppTheme.cyanAccent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isPrimary ? Colors.black : AppTheme.cyanAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : AppTheme.cyanAccent,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'files':
            _uploadFiles();
            break;
          case 'zip':
            _uploadZip();
            break;
          case 'project':
            _importProject();
            break;
        }
      },
      offset: const Offset(0, 50),
      color: AppTheme.surfaceBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.cyanAccent),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'files',
          child: Row(
            children: const [
              Icon(Icons.upload_file, size: 16, color: AppTheme.cyanAccent),
              SizedBox(width: 12),
              Text('Upload Files', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'zip',
          child: Row(
            children: const [
              Icon(Icons.folder_zip, size: 16, color: AppTheme.cyanAccent),
              SizedBox(width: 12),
              Text('Upload ZIP', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'project',
          child: Row(
            children: const [
              Icon(Icons.folder_open, size: 16, color: AppTheme.cyanAccent),
              SizedBox(width: 12),
              Text('Import Project', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppTheme.cyanAccent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.download, size: 14, color: AppTheme.cyanAccent),
            SizedBox(width: 6),
            Text(
              'IMPORT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.cyanAccent,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.cyanAccent),
          ],
        ),
      ),
    );
  }


  Widget _buildEditor(String filePath) {
    if (!_editors.containsKey(filePath)) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final controller = _editors[filePath]!;
    
    return Container(
      color: AppTheme.deepBlack,
      child: CodeTheme(
        data: CodeThemeData(styles: AppTheme.codeTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: controller,
            textStyle: GoogleFonts.ibmPlexMono(fontSize: 13, height: 1.6),
            gutterStyle: const GutterStyle(
              showLineNumbers: true,
              textStyle: TextStyle(color: AppTheme.textDimmed, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEditor() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code, size: 64, color: AppTheme.textDimmed.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No file open',
            style: TextStyle(color: AppTheme.textDimmed.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a project or create a new one to get started',
            style: TextStyle(color: AppTheme.textDimmed.withOpacity(0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.elevatedSurface,
      child: Row(
        children: [
          const Icon(Icons.remove_red_eye, size: 14, color: AppTheme.textGrey),
          const SizedBox(width: 8),
          Text(
            _isServerRunning && _processRunner.serverUrl != null
                ? _processRunner.serverUrl!
                : 'LIVE PREVIEW',
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_isServerRunning)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.cyanAccent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.web, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Start the development server',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Click RUN to see your project live',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLinuxPreviewFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.computer_rounded, size: 48, color: AppTheme.cyanAccent),
            const SizedBox(height: 16),
            const Text(
              'LIVE PREVIEW (LINUX)',
              style: TextStyle(
                color: AppTheme.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Interactive WebView is currently restricted on Linux. \n\nServer is running at:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _processRunner.serverUrl ?? 'http://localhost:3000',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                backgroundColor: AppTheme.elevatedSurface,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('OPEN IN BROWSER'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.cyanAccent,
                side: const BorderSide(color: AppTheme.cyanAccent),
              ),
              onPressed: _openInBrowser,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(top: BorderSide(color: AppTheme.borderGlow, width: 2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: AppTheme.textGrey),
                const SizedBox(width: 8),
                const Text('TERMINAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, size: 16, color: AppTheme.textGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _consoleLogs.clear()),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.borderGlow, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _consoleLogs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _consoleLogs[index],
                  style: GoogleFonts.ibmPlexMono(color: AppTheme.cyanAccent, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    
    if (result != null) {
      final paths = result.files.map((f) => f.path!).toList();
      final res = await _projectManager.uploadFiles(paths);
      
      if (res['success']) {
        setState(() {
          _fileTree = res['fileTree'];
        });
        _addLog('✓ Uploaded ${paths.length} file(s)');
      } else {
        _addLog('✗ Upload failed: ${res['message']}');
      }
    }
  }

  Future<void> _uploadZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    
    if (result != null && result.files.single.path != null) {
      _addLog('📦 Extracting zip file...');
      final res = await _projectManager.uploadZip(result.files.single.path!);
      
      if (res['success']) {
        setState(() {
          _fileTree = res['fileTree'];
          _projectType = res['projectType'];
        });
        _addLog('✓ Project extracted successfully');
        _addLog('Project type detected: ${_projectManager.getProjectTypeDisplay(_projectType!)}');
        
        // Auto-open main file
        await _autoOpenMainFile();
      } else {
        _addLog('✗ Extraction failed: ${res['message']}');
      }
    }
  }

  Future<void> _importProject() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.cyanAccent),
        ),
        title: const Text('Import Project'),
        content: const Text('Choose import source:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'local'),
            child: const Text('LOCAL FOLDER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'github'),
            child: const Text('FROM GITHUB'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );

    if (choice == 'local') {
      await _importLocalProject();
    } else if (choice == 'github') {
      await _importFromGitHub();
    }
  }

  Future<void> _importLocalProject() async {
    final result = await FilePicker.platform.getDirectoryPath();
    
    if (result != null) {
      _addLog('📂 Opening local project...');
      final res = await _projectManager.openProject(result);
      
      if (res['success']) {
        setState(() {
          _fileTree = res['fileTree'];
          _projectType = res['projectType'];
        });
        _addLog('✓ Project opened successfully');
        _addLog('Project type: ${_projectManager.getProjectTypeDisplay(_projectType!)}');
        await _autoOpenMainFile();
      } else {
        _addLog('✗ Failed to open project: ${res['message']}');
      }
    }
  }

  Future<void> _importFromGitHub() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.token == null) {
      _addLog('✗ Please login to GitHub first');
      return;
    }

    // Show repository selection dialog (reuse existing repos list)
    _addLog('📦 Fetching your repositories...');
    final reposRes = await GHService().getUserRepos(auth.token!);
    
    if (!mounted) return;

    if (!reposRes['success']) {
      _addLog('✗ Failed to fetch repos: ${reposRes['message']}');
      return;
    }

    final List repos = reposRes['repos'];
    String? selectedRepo;

    final repo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.cyanAccent),
          ),
          title: const Text('Import from GitHub'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: repos.length,
              itemBuilder: (context, index) {
                final repoItem = repos[index];
                final isSelected = selectedRepo == repoItem['full_name'];
                return ListTile(
                  dense: true,
                  title: Text(
                    repoItem['full_name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppTheme.cyanAccent : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    repoItem['description'] ?? '',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setDialogState(() => selectedRepo = repoItem['full_name']);
                  },
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.cyanAccent, size: 16)
                      : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: selectedRepo == null
                  ? null
                  : () {
                      final selected = repos.firstWhere((r) => r['full_name'] == selectedRepo);
                      Navigator.pop(context, selected);
                    },
              child: const Text('IMPORT'),
            ),
          ],
        ),
      ),
    );

    if (repo != null) {
      _addLog('🔄 Cloning ${repo['full_name']}...');
      
      final String home = Platform.environment['HOME'] ?? '/tmp';
      final projectPath = p.join(home, 'syncstack', repo['full_name']);
      
      // Check if already exists
      if (await Directory(projectPath).exists()) {
        final res = await _projectManager.openProject(projectPath);
        if (res['success']) {
          setState(() {
            _fileTree = res['fileTree'];
            _projectType = res['projectType'];
          });
          _addLog('✓ Opened existing project');
          await _autoOpenMainFile();
        }
      } else {
        // Clone the repo
        final res = await GHService().syncRepo(
          projectPath,
          repo['full_name'],
          repo['clone_url'],
          auth.token!,
          'pull',
        );
        
        if (res['success']) {
          final openRes = await _projectManager.openProject(projectPath);
          if (openRes['success']) {
            setState(() {
              _fileTree = openRes['fileTree'];
              _projectType = openRes['projectType'];
            });
            _addLog('✓ Repository cloned and opened');
            await _autoOpenMainFile();
          }
        } else {
          _addLog('✗ Failed to clone: ${res['message']}');
        }
      }
    }
  }

  Future<void> _createNewProject() async {
    final controller = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Project Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
    
    if (name != null && name.isNotEmpty) {
      final res = await _projectManager.createProject(name);
      if (res['success']) {
        setState(() {
          _fileTree = res['fileTree'];
          _projectType = 'static';
        });
        _addLog('✓ Project "$name" created');
        await _autoOpenMainFile();
      }
    }
  }

  Future<void> _autoOpenMainFile() async {
    // Look for index.html, main.js, app.js, etc.
    final mainFiles = ['index.html', 'main.js', 'app.js', 'index.js'];
    
    for (final fileName in mainFiles) {
      final filePath = '${_projectManager.currentProjectPath}/$fileName';
      if (await File(filePath).exists()) {
        await _openFile(filePath);
        break;
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    final res = await _projectManager.readFile(filePath);
    
    if (res['success']) {
      if (!_editors.containsKey(filePath)) {
        final language = _getLanguageFromPath(filePath);
        _editors[filePath] = CodeController(
          text: res['content'],
          language: language,
        );
        
        _editors[filePath]!.addListener(() {
          // Mark as dirty when content changes
          final index = _openTabs.indexWhere((t) => t.filePath == filePath);
          if (index != -1 && !_openTabs[index].isDirty) {
            setState(() {
              _openTabs[index] = _openTabs[index].copyWith(isDirty: true);
            });
          }
        });
        
        setState(() {
          _openTabs.add(EditorTab(
            filePath: filePath,
            fileName: filePath.split('/').last,
          ));
        });
      }
      
      setState(() => _activeTab = filePath);
    }
  }

  dynamic _getLanguageFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'html':
      case 'htm':
        return xml;
      case 'css':
        return css;
      case 'js':
      case 'jsx':
        return javascript;
      default:
        return null;
    }
  }

  void _closeTab(String filePath) {
    setState(() {
      _openTabs.removeWhere((t) => t.filePath == filePath);
      _editors.remove(filePath)?.dispose();
      if (_activeTab == filePath) {
        _activeTab = _openTabs.isNotEmpty ? _openTabs.last.filePath : null;
      }
    });
  }

  Future<void> _createNewFile(String targetDir) async {
    final controller = TextEditingController();
    
    final filename = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'File Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
    
    if (filename != null && filename.isNotEmpty) {
      final res = await _projectManager.createFile(filename, targetDir: targetDir);
      if (res['success']) {
        setState(() => _fileTree = res['fileTree']);
        await _openFile(res['path']);
      }
    }
  }

  Future<void> _toggleServer() async {
    if (_isServerRunning) {
      await _processRunner.stop();
      setState(() => _isServerRunning = false);
    } else {
      if (_projectManager.currentProjectPath == null) {
        _addLog('✗ No project loaded');
        return;
      }
      
      if (_projectType == null) {
        _addLog('✗ Unknown project type');
        return;
      }
      
      final res = await _processRunner.startDevServer(
        _projectManager.currentProjectPath!,
        _projectType!,
      );
      
      if (res['success']) {
        setState(() => _isServerRunning = true);
        
        // Load in preview
        if (_processRunner.serverUrl != null && _webController != null) {
          await _webController!.loadRequest(Uri.parse(_processRunner.serverUrl!));
        }
      } else {
        _addLog('✗ Failed to start server: ${res['message']}');
      }
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.cyanAccent),
        ),
        title: const Text('Sandbox Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workspace Path:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_projectManager.currentProjectPath ?? 'None', style: const TextStyle(color: AppTheme.cyanAccent)),
            const SizedBox(height: 16),
            const Text('Server Port:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            const Text('8080', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _publishToGitHub() async {
    if (_projectManager.currentProjectPath == null) {
      _addLog('✗ No project to publish');
      return;
    }
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || auth.token == null) {
      _addLog('✗ Please login first');
      return;
    }

    final projectName = p.basename(_projectManager.currentProjectPath!);
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Text('Publish to GitHub'),
        content: Text('Do you want to publish "$projectName" as a new repository?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PUBLISH', style: TextStyle(color: AppTheme.cyanAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _addLog('🚀 Publishing to GitHub...');
    final res = await _ghService.createRepo(auth.token!, projectName, 'Project exported from SyncStack');
    
    if (res['success']) {
      _addLog('✓ Repository created: ${res['repo']['html_url']}');
      _addLog('📦 Pushing initial files...');
      // Note: Full push logic requires git init, remote add, and push
      // This scaffold assumes the repo exists and we just created it via API
    } else {
      _addLog('✗ Publish failed: ${res['message']}');
    }
  }

  Future<void> _openInBrowser() async {
    final res = await _ghService.exportSandbox(
      _editors['index.html']?.text ?? '',
      _editors['style.css']?.text ?? '',
      _editors['app.js']?.text ?? '',
    );

    if (res['success'] && res['path'] != null) {
      _addLog('🌐 Opening in external browser...');
      // In a real app, use url_launcher
      // For now, we log the path
      _addLog('Path: ${res['path']}');
    } else {
      _addLog('✗ Failed to export sandbox: ${res['message']}');
    }
  }

  void _addLog(String message) {
    setState(() => _consoleLogs.add(message));
  }
}
