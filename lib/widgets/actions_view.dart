import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';
import '../providers/auth_provider.dart';

class ActionsView extends StatefulWidget {
  final String repoFullName;

  const ActionsView({super.key, required this.repoFullName});

  @override
  State<ActionsView> createState() => _ActionsViewState();
}

class _ActionsViewState extends State<ActionsView> {
  final GHService _ghService = GHService();
  List<dynamic>? _workflows;
  List<dynamic>? _runs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);

    try {
      final workflowsRes = await _ghService.getWorkflows(auth.token!, widget.repoFullName);
      final runsRes = await _ghService.getWorkflowRuns(auth.token!, widget.repoFullName);

      if (mounted) {
        setState(() {
          _workflows = workflowsRes['success'] ? workflowsRes['workflows'] : [];
          _runs = runsRes['success'] ? runsRes['runs'] : [];
          _error = (!workflowsRes['success'] || !runsRes['success']) ? 'Failed to fetch actions' : null;
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

  Future<void> _triggerWorkflow(String workflowId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Triggering workflow...'), backgroundColor: AppTheme.infoBlue),
    );

    try {
      final res = await _ghService.triggerWorkflow(auth.token!, widget.repoFullName, workflowId);
      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workflow triggered successfully'), backgroundColor: AppTheme.cyanAccent),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${res['message']}'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text('Actions Error', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('RETRY')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkflowList(),
          const SizedBox(height: 32),
          _buildRecentRuns(),
        ],
      ),
    );
  }

  Widget _buildWorkflowList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.play_circle_outline, color: AppTheme.cyanAccent, size: 18),
            SizedBox(width: 12),
            Text('AVAILABLE WORKFLOWS', style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.mattBox(),
          child: Column(
            children: (_workflows ?? []).map<Widget>((w) => ListTile(
              title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(w['path'], style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.cyanAccent),
                onPressed: () => _triggerWorkflow(w['id'].toString()),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRuns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: AppTheme.cyanAccent, size: 18),
            const SizedBox(width: 12),
            const Text('WORKFLOW RUNS', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.white)),
            const Spacer(),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('REFRESH', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlack,
            border: Border.all(color: AppTheme.borderGlow),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: (_runs ?? []).isEmpty 
              ? [const Padding(padding: EdgeInsets.all(20), child: Text('No workflow runs found.', style: TextStyle(color: AppTheme.textGrey)))]
              : (_runs ?? []).map<Widget>((run) => _buildRunItem(run)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRunItem(Map<String, dynamic> run) {
    final status = run['status'];
    final conclusion = run['conclusion'];
    
    Color statusColor = AppTheme.textGrey;
    IconData statusIcon = Icons.radio_button_unchecked;
    bool isSpinning = false;

    if (status == 'completed') {
      if (conclusion == 'success') {
        statusColor = AppTheme.cyanAccent;
        statusIcon = Icons.check_circle;
      } else if (conclusion == 'failure') {
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel;
      } else if (conclusion == 'cancelled') {
        statusColor = AppTheme.textGrey;
        statusIcon = Icons.block;
      }
    } else if (status == 'in_progress' || status == 'queued') {
      statusColor = AppTheme.warningOrange;
      statusIcon = Icons.autorenew;
      isSpinning = true;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderGlow))),
      child: Row(
        children: [
          isSpinning 
            ? const Icon(Icons.sync, color: AppTheme.warningOrange, size: 20).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.seconds)
            : Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run['display_title'] ?? run['name'], 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${run['name']} #${run['run_number']}: ',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                    ),
                    Text(
                      '${run['head_branch']}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.infoBlue, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ' by ${run['actor']['login']}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimeRelative(run['created_at']), 
                style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)
              ),
              const SizedBox(height: 6),
              if (status == 'completed')
                InkWell(
                  onTap: () => _showLogs(run['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      border: Border.all(color: AppTheme.borderGlow),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt, size: 12, color: AppTheme.textGrey),
                        SizedBox(width: 6),
                        Text('DETAILS', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeRelative(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _showLogs(int runId) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _JobsDialog(
          runId: runId.toString(),
          repoFullName: widget.repoFullName,
          token: auth.token!,
          ghService: _ghService,
        );
      },
    );
  }

  String _formatTime(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _JobsDialog extends StatefulWidget {
  final String runId;
  final String repoFullName;
  final String token;
  final GHService ghService;

  const _JobsDialog({
    required this.runId,
    required this.repoFullName,
    required this.token,
    required this.ghService,
  });

  @override
  State<_JobsDialog> createState() => _JobsDialogState();
}

class _JobsDialogState extends State<_JobsDialog> {
  List<dynamic>? _jobs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final res = await widget.ghService.getRunJobs(widget.token, widget.repoFullName, widget.runId);
      if (mounted) {
        setState(() {
          _jobs = res['success'] ? res['jobs'] : [];
          _error = !res['success'] ? res['message'] : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppTheme.cyanAccent)),
      title: const Text('WORKFLOW JOBS', style: TextStyle(letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent))
          : _error != null 
            ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorRed)))
            : ListView.builder(
                itemCount: _jobs?.length ?? 0,
                itemBuilder: (context, index) {
                  final job = _jobs![index];
                  return ListTile(
                    leading: Icon(
                      job['conclusion'] == 'success' ? Icons.check_circle : Icons.error,
                      color: job['conclusion'] == 'success' ? AppTheme.cyanAccent : AppTheme.errorRed,
                    ),
                    title: Text(job['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Status: ${job['status']} • ${job['conclusion'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                    onTap: () {
                      // In a real app with more time, we'd fetch the actual log text via another API call
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing logs for ${job['name']}...'), backgroundColor: AppTheme.infoBlue),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CLOSE')),
      ],
    );
  }
}
