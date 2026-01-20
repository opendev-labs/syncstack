import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/git_graph_widget.dart';
import '../widgets/file_changes_list.dart';
import '../widgets/premium_button.dart';

class GitStatusScreen extends StatefulWidget {
  final String? repoPath;
  final String? repoName;
  
  const GitStatusScreen({
    super.key,
    this.repoPath,
    this.repoName,
  });

  @override
  State<GitStatusScreen> createState() => _GitStatusScreenState();
}

class _GitStatusScreenState extends State<GitStatusScreen> {
  final GHService _ghService = GHService();
  Map<String, dynamic>? _status;
  bool _isLoading = true;
  String? _error;
  String _selectedStrategy = 'pull';
  bool _autoSync = false;

  @override
  void initState() {
    super.initState();
    if (widget.repoPath != null) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);

    try {
      final result = await _ghService.getDetailedStatus(widget.repoPath!);
      if (mounted) {
        setState(() {
          _status = result['success'] == true ? result : null;
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

  Future<void> _syncNow() async {
    if (widget.repoPath == null || widget.repoName == null) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);

    try {
      // Get repo details first (you may need to store this)
      final cloneUrl = _status?['clone_url'] ?? '';
      
      final result = await _ghService.syncRepo(
        widget.repoPath!,
        widget.repoName!,
        cloneUrl,
        auth.token!,
        _selectedStrategy,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sync completed'),
            backgroundColor: result['success'] == true
                ? AppTheme.cyanAccent
                : AppTheme.errorRed,
          ),
        );
        
        if (result['success'] == true) {
          await _loadStatus();
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _compareRemote() async {
    if (widget.repoPath == null) return;
    final branch = _status?['branch'] ?? 'main';
    
    showDialog(
      context: context,
      builder: (context) => _RemoteCompareDialog(
        repoPath: widget.repoPath!,
        branch: branch,
        ghService: _ghService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repoPath == null) {
      return const Center(
        child: Text(
          'No repository selected',
          style: TextStyle(color: AppTheme.textGrey),
        ),
      );
    }

    if (_isLoading && _status == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.cyanAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading status',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatus,
      color: AppTheme.cyanAccent,
      backgroundColor: AppTheme.surfaceBlack,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildGitGraphSection(),
            const SizedBox(height: 24),
            _buildFileChangesSection(),
            const SizedBox(height: 24),
            _buildSyncSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final branch = _status?['branch'] ?? 'main';
    final ahead = _status?['ahead'] ?? 0;
    final behind = _status?['behind'] ?? 0;
    final isDirty = _status?['is_dirty'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.mattBox(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.elevatedSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: AppTheme.cyanAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      branch,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isDirty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.warningOrange.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'UNCOMMITTED',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            color: AppTheme.warningOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _status?['human_status'] ?? 'Up to date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
                if (_status?['risk_reason'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _status?['risk_reason'],
                      style: TextStyle(
                        fontSize: 10,
                        color: _status?['risk'] == 'high' ? AppTheme.errorRed : AppTheme.textDimmed,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (ahead > 0)
            _buildStatusBadge('↑ $ahead AHEAD', AppTheme.cyanAccent),
          if (ahead > 0 && behind > 0) const SizedBox(width: 8),
          if (behind > 0)
            _buildStatusBadge('↓ $behind BEHIND', AppTheme.infoBlue),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGitGraphSection() {
    return Container(
      decoration: AppTheme.mattBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.timeline, color: AppTheme.cyanAccent, size: 18),
                const SizedBox(width: 12),
                const Text(
                  'BRANCH TIMELINE & HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ahead: ${_status?['ahead'] ?? 0}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.cyanAccent.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Behind: ${_status?['behind'] ?? 0}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.infoBlue.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.borderGlow, height: 1),
          GitGraphWidget(
            commits: _status?['commits'] ?? [],
            branch: _status?['branch'] ?? 'main',
            ahead: _status?['ahead'] ?? 0,
            behind: _status?['behind'] ?? 0,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildFileChangesSection() {
    final changes = _status?['changes'] as List<dynamic>? ?? [];

    return Container(
      decoration: AppTheme.mattBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, color: AppTheme.cyanAccent, size: 18),
                const SizedBox(width: 12),
                const Text(
                  'FILE CHANGES - STAGING AREA',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${changes.length} files',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.borderGlow, height: 1),
          FileChangesList(
            changes: changes,
            repoPath: widget.repoPath ?? '',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSyncSection() {
    final risk = _status?['risk'] ?? 'low';
    final riskColor = risk == 'high'
        ? AppTheme.errorRed
        : risk == 'medium'
            ? AppTheme.warningOrange
            : AppTheme.cyanAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.mattBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppTheme.cyanAccent, size: 18),
              SizedBox(width: 12),
              Text(
                'SYNC SETTINGS & ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'SYNC STRATEGY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildStrategyChip('PULL', 'pull'),
              _buildStrategyChip('REBASE', 'rebase'),
              _buildStrategyChip('FORCE PUSH', 'force'),
              _buildStrategyChip('RESET', 'reset'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  onPressed: _isLoading ? null : _syncNow,
                  isLoading: _isLoading,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync_rounded, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _isLoading ? 'SYNCING...' : 'SYNC NOW',
                        style: const TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _compareRemote,
                icon: const Icon(Icons.compare_arrows, size: 16),
                label: const Text('COMPARE REMOTELY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: riskColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'CONFLICT RISK: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      risk.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      risk == 'high' ? Icons.warning : Icons.check_circle,
                      color: riskColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Text(
                    'AUTO-SYNC',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGrey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _autoSync,
                    onChanged: (v) => setState(() => _autoSync = v),
                    activeColor: AppTheme.cyanAccent,
                  ),
                  if (_autoSync)
                    const Text(
                      'Enabled',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.cyanAccent,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStrategyChip(String label, String value) {
    final isSelected = _selectedStrategy == value;
    return InkWell(
      onTap: () => setState(() => _selectedStrategy = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.cyanAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.cyanAccent
                : AppTheme.textGrey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.cyanAccent : AppTheme.textGrey,
          ),
        ),
      ),
    );
  }
}

class _RemoteCompareDialog extends StatefulWidget {
  final String repoPath;
  final String branch;
  final GHService ghService;

  const _RemoteCompareDialog({
    required this.repoPath,
    required this.branch,
    required this.ghService,
  });

  @override
  State<_RemoteCompareDialog> createState() => _RemoteCompareDialogState();
}

class _RemoteCompareDialogState extends State<_RemoteCompareDialog> {
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
      final res = await widget.ghService.getRemoteDiff(widget.repoPath, widget.branch);
      if (mounted) {
        setState(() {
          _diff = res['success'] ? res['diff'] : null;
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
    return Dialog(
      backgroundColor: AppTheme.surfaceBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppTheme.cyanAccent)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppTheme.cyanAccent),
                const SizedBox(width: 16),
                Text('LOCAL VS REMOTE [origin/${widget.branch}]', style: const TextStyle(letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const Divider(color: AppTheme.borderGlow, height: 32),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent))
                : _error != null 
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorRed)))
                  : _diff == null || _diff!.isEmpty
                    ? const Center(child: Text('Local and remote are identical.', style: TextStyle(color: AppTheme.cyanAccent)))
                    // Reuse some of the logic from DiffViewer if possible, or just simple text for now
                    : SingleChildScrollView(
                        child: Text(_diff!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textGrey)),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
