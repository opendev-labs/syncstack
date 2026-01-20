import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Editor tab data
class EditorTab {
  final String filePath;
  final String fileName;
  final bool isDirty;

  EditorTab({
    required this.filePath,
    required this.fileName,
    this.isDirty = false,
  });

  EditorTab copyWith({bool? isDirty}) {
    return EditorTab(
      filePath: filePath,
      fileName: fileName,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Multi-file editor tabs component
class EditorTabs extends StatelessWidget {
  final List<EditorTab> tabs;
  final String? activeTab;
  final Function(String) onTabSelected;
  final Function(String) onTabClosed;

  const EditorTabs({
    super.key,
    required this.tabs,
    this.activeTab,
    required this.onTabSelected,
    required this.onTabClosed,
  });

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return Container(
        height: 40,
        color: AppTheme.elevatedSurface,
        child: Center(
          child: Text(
            'No files open',
            style: TextStyle(
              color: AppTheme.textDimmed.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      color: AppTheme.elevatedSurface,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = tab.filePath == activeTab;
                
                return _buildTab(tab, isActive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(EditorTab tab, bool isActive) {
    return InkWell(
      onTap: () => onTabSelected(tab.filePath),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.surfaceBlack : AppTheme.elevatedSurface,
          border: Border(
            right: const BorderSide(color: AppTheme.borderGlow, width: 1),
            bottom: BorderSide(
              color: isActive ? AppTheme.cyanAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                _getFileIcon(tab.fileName),
                size: 14,
                color: isActive ? AppTheme.cyanAccent : AppTheme.textGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tab.fileName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isActive ? Colors.white : AppTheme.textGrey,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tab.isDirty) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                onTap: () => onTabClosed(tab.filePath),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isActive ? AppTheme.textGrey : AppTheme.textDimmed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'html':
      case 'htm':
        return Icons.language;
      case 'css':
      case 'scss':
        return Icons.style;
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return Icons.javascript;
      case 'json':
        return Icons.data_object;
      case 'md':
        return Icons.article;
      case 'dart':
        return Icons.flutter_dash;
      default:
        return Icons.insert_drive_file;
    }
  }
}
