import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';

class GitGraphWidget extends StatefulWidget {
  final List<dynamic> commits;
  final String branch;
  final int ahead;
  final int behind;
  final String? repoPath;

  const GitGraphWidget({
    super.key,
    required this.commits,
    required this.branch,
    required this.ahead,
    required this.behind,
    this.repoPath,
  });

  @override
  State<GitGraphWidget> createState() => _GitGraphWidgetState();
}

class _GitGraphWidgetState extends State<GitGraphWidget> {
  final GHService _ghService = GHService();
  List<dynamic>? _graphData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.repoPath != null) {
      _loadGraphData();
    }
  }

  Future<void> _loadGraphData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _ghService.getGitGraph(widget.repoPath!);
      if (mounted) {
        setState(() {
          _graphData = res['success'] ? res['results'] : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent, strokeWidth: 2)),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.commits.length,
        itemBuilder: (context, index) {
          final commit = widget.commits[index];
          return _buildCommitNode(commit, index);
        },
      ),
    );
  }

  Widget _buildCommitNode(Map<String, dynamic> commit, int index) {
    final isHead = index == 0;
    
    return Container(
      width: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Line
          if (index < widget.commits.length - 1)
            Positioned(
              left: 60,
              top: 50,
              right: -60,
              child: Container(
                height: 2,
                color: AppTheme.cyanAccent.withOpacity(0.2),
              ),
            ),
          
          // Node
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (isHead)
                   const Text('HEAD', style: TextStyle(color: AppTheme.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))
                       .animate().fadeIn().scale(),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showCommitDetails(commit),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cyanAccent, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.cyanAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.surfaceBlack,
                      child: Text(
                        commit['hash'].substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  commit['hash'],
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    commit['message'],
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(commit['timestamp']),
                  style: const TextStyle(color: AppTheme.textDimmed, fontSize: 9),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ts.toString()) * 1000);
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showCommitDetails(Map<String, dynamic> commit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppTheme.cyanAccent)),
        title: Row(
          children: [
            const Icon(Icons.commit, color: AppTheme.cyanAccent),
            const SizedBox(width: 12),
            Text('COMMIT DETAILS', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 14, letterSpacing: 2)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('HASH', commit['hash']),
            _detailRow('AUTHOR', commit['author']),
            _detailRow('EMAIL', commit['email']),
            _detailRow('MESSAGE', commit['message']),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('DISMISS')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textGrey, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textWhite)),
        ],
      ),
    );
  }
}
