import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// VSCode-style file tree explorer
class FileTreeView extends StatefulWidget {
  final Map<String, dynamic> fileTree;
  final String? selectedFile;
  final Function(String) onFileSelected;
  final Function(String)? onFileDelete;
  final Function(String)? onNewFile;

  const FileTreeView({
    super.key,
    required this.fileTree,
    this.selectedFile,
    required this.onFileSelected,
    this.onFileDelete,
    this.onNewFile,
  });

  @override
  State<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends State<FileTreeView> {
  final Set<String> _expandedDirs = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(color: AppTheme.borderGlow, height: 1),
          Expanded(
            child: widget.fileTree.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    child: _buildTreeNode(widget.fileTree, 0),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 16, color: AppTheme.cyanAccent),
          const SizedBox(width: 8),
          const Text(
            'EXPLORER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppTheme.textGrey,
            ),
          ),
          const Spacer(),
          if (widget.onNewFile != null)
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => widget.onNewFile?.call(widget.fileTree['path'] ?? ''),
              tooltip: 'New File',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: AppTheme.textDimmed.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No files',
              style: TextStyle(color: AppTheme.textDimmed.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeNode(Map<String, dynamic> node, int depth) {
    final isDirectory = node['type'] == 'directory';
    final name = node['name'] as String;
    final path = node['path'] as String;
    final children = node['children'] as List<dynamic>? ?? [];

    if (isDirectory) {
      final isExpanded = _expandedDirs.contains(path);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDirs.remove(path);
                } else {
                  _expandedDirs.add(path);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(
                left: (depth * 16.0) + 8,
                right: 8,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 16,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 16,
                    color: AppTheme.cyanAccent.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ...children.map((child) => _buildTreeNode(child, depth + 1)),
        ],
      );
    } else {
      final isSelected = widget.selectedFile == path;
      final extension = node['extension'] as String? ?? '';
      
      return InkWell(
        onTap: () => widget.onFileSelected(path),
        child: Container(
          padding: EdgeInsets.only(
            left: (depth * 16.0) + 28,
            right: 8,
            top: 6,
            bottom: 6,
          ),
          color: isSelected ? AppTheme.elevatedSurface : null,
          child: Row(
            children: [
              Icon(
                _getFileIcon(extension),
                size: 16,
                color: isSelected ? AppTheme.cyanAccent : _getFileColor(extension),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.textGrey,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.html':
      case '.htm':
        return Icons.language;
      case '.css':
      case '.scss':
      case '.sass':
      case '.less':
        return Icons.style;
      case '.js':
      case '.jsx':
      case '.ts':
      case '.tsx':
        return Icons.javascript;
      case '.json':
        return Icons.data_object;
      case '.md':
      case '.markdown':
        return Icons.article;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
      case '.webp':
        return Icons.image;
      case '.py':
        return Icons.code;
      case '.dart':
        return Icons.flutter_dash;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case '.html':
      case '.htm':
        return const Color(0xFFE34C26);
      case '.css':
      case '.scss':
      case '.sass':
        return const Color(0xFF264DE4);
      case '.js':
      case '.jsx':
        return const Color(0xFFF0DB4F);
      case '.ts':
      case '.tsx':
        return const Color(0xFF007ACC);
      case '.json':
        return AppTheme.cyanAccent;
      case '.md':
        return Colors.grey;
      case '.py':
        return const Color(0xFF3776AB);
      case '.dart':
        return const Color(0xFF0175C2);
      default:
        return AppTheme.textDimmed;
    }
  }
}
