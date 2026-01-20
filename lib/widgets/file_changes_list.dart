import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'diff_viewer.dart';

class FileChangesList extends StatefulWidget {
  final List<dynamic> changes;
  final String repoPath;

  const FileChangesList({
    super.key,
    required this.changes,
    required this.repoPath,
  });

  @override
  State<FileChangesList> createState() => _FileChangesListState();
}

class _FileChangesListState extends State<FileChangesList> {
  final Set<int> _selectedIndices = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.changes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.cyanAccent.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'No changes detected',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Working directory clean',
                style: TextStyle(
                  color: AppTheme.textGrey.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.elevatedSurface,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderGlow.withOpacity(0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (value) {
                  setState(() {
                    _selectAll = value ?? false;
                    if (_selectAll) {
                      _selectedIndices.addAll(
                        List.generate(widget.changes.length, (i) => i),
                      );
                    } else {
                      _selectedIndices.clear();
                    }
                  });
                },
                activeColor: AppTheme.cyanAccent,
                checkColor: AppTheme.deepBlack,
              ),
              const SizedBox(width: 8),
              const Expanded(
                flex: 3,
                child: Text(
                  'FILE PATH',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: Text(
                  'TYPE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
              const SizedBox(
                width: 100,
                child: Text(
                  'ACTIONS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
        // File rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.changes.length,
          itemBuilder: (context, index) {
            return _buildFileRow(index, widget.changes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFileRow(int index, Map<String, dynamic> change) {
    final file = change['file'] as String? ?? '';
    final status = change['status'] as String? ?? 'M';
    final additions = change['additions'] as int? ?? 0;
    final deletions = change['deletions'] as int? ?? 0;
    final isSelected = _selectedIndices.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.cyanAccent.withOpacity(0.05)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGlow.withOpacity(0.3),
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIndices.add(index);
                    } else {
                      _selectedIndices.remove(index);
                    }
                  });
                },
                activeColor: AppTheme.cyanAccent,
                checkColor: AppTheme.deepBlack,
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (additions > 0 || deletions > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (additions > 0) ...[
                              Text(
                                '+$additions',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (deletions > 0)
                              Text(
                                '-$deletions',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  _getFileType(file),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: OutlinedButton.icon(
                  onPressed: () => _showDiff(file),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text(
                    'DIFF',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cyanAccent,
                    side: BorderSide(
                      color: AppTheme.cyanAccent.withOpacity(0.5),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'A':
        color = AppTheme.cyanAccent;
        label = 'A';
        break;
      case 'M':
        color = AppTheme.warningOrange;
        label = 'M';
        break;
      case 'D':
        color = AppTheme.errorRed;
        label = 'D';
        break;
      case '?':
        color = AppTheme.infoBlue;
        label = '?';
        break;
      default:
        color = AppTheme.textGrey;
        label = status;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  String _getFileType(String file) {
    final ext = file.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return 'Dart';
      case 'js':
        return 'JavaScript';
      case 'ts':
        return 'TypeScript';
      case 'py':
        return 'Python';
      case 'css':
        return 'Stylesheet';
      case 'html':
        return 'HTML';
      case 'json':
        return 'JSON';
      case 'yaml':
      case 'yml':
        return 'YAML';
      case 'md':
        return 'Markdown';
      default:
        return 'File';
    }
  }

  void _showDiff(String file) {
    showDialog(
      context: context,
      builder: (context) => DiffViewer(
        filePath: file,
        repoPath: widget.repoPath,
      ),
    );
  }
}
