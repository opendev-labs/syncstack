import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';

class DiffViewer extends StatefulWidget {
  final String filePath;
  final String repoPath;

  const DiffViewer({
    super.key,
    required this.filePath,
    required this.repoPath,
  });

  @override
  State<DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends State<DiffViewer> {
  final GHService _ghService = GHService();
  String? _diff;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    try {
      final result = await _ghService.getFileDiff(
        widget.repoPath,
        widget.filePath,
      );

      if (mounted) {
        setState(() {
          _diff = result['success'] == true ? result['diff'] : null;
          _error = result['success'] != true ? result['message'] : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.deepBlack,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: AppTheme.borderGlow, height: 1),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.difference_outlined,
            color: AppTheme.cyanAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.filePath,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'FILE DIFF',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.cyanAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load diff',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_diff == null || _diff!.isEmpty) {
      return const Center(
        child: Text(
          'No changes to display',
          style: TextStyle(color: AppTheme.textGrey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildDiffLines(),
    );
  }

  Widget _buildDiffLines() {
    final lines = _diff!.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _buildDiffLine(line)).toList(),
    );
  }

  Widget _buildDiffLine(String line) {
    Color? backgroundColor;
    Color? textColor = Colors.white;

    if (line.startsWith('+')) {
      backgroundColor = AppTheme.cyanAccent.withOpacity(0.1);
      textColor = AppTheme.cyanAccent;
    } else if (line.startsWith('-')) {
      backgroundColor = AppTheme.errorRed.withOpacity(0.1);
      textColor = AppTheme.errorRed;
    } else if (line.startsWith('@@')) {
      backgroundColor = AppTheme.infoBlue.withOpacity(0.1);
      textColor = AppTheme.infoBlue;
    } else if (line.startsWith('diff') || line.startsWith('index')) {
      textColor = AppTheme.textGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              line.isEmpty ? ' ' : line,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
