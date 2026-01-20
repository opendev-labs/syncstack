import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';
import '../widgets/github_logo_painter.dart';
import '../widgets/dashboard_views.dart';
import '../widgets/sync_status_view.dart';
import '../widgets/actions_view.dart';
import 'sandbox_screen.dart';
import '../providers/sync_provider.dart';
import 'git_status_screen.dart';
import '../widgets/project_wizard.dart';
import '../widgets/local_scan_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GHService _ghService = GHService();
  List<dynamic>? _repos;
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null || auth.token!.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _ghService.getUserRepos(auth.token!);
      if (result['success'] == true) {
        if (mounted) setState(() => _repos = result['repos']);
      } else {
        if (mounted) setState(() => _error = result['message']);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Row(
        children: [
          // Premium Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceBlack,
              border: Border(
                right: BorderSide(
                  color: AppTheme.borderGlow,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderGlow,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/logo.svg',
                            height: 32,
                            width: 32,
                            colorFilter: const ColorFilter.mode(AppTheme.cyanAccent, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'SYNCSTACK',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildStatusBadge(),
                    ],
                  ),
                ),

                // Navigation
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionHeader('NAVIGATION'),
                      _buildNavItem(Icons.grid_view_rounded, 'Repositories', 0),
                      _buildNavItem(Icons.sync_rounded, 'Sync Status', 1),
                      _buildNavItem(Icons.account_tree_outlined, 'Git Status', 2),
                      _buildNavItem(Icons.play_circle_outline, 'GitHub Actions', 3),
                      _buildNavItem(Icons.auto_awesome_rounded, 'Web Editor', 4),
                      _buildNavItem(Icons.analytics_outlined, 'Analytics', 5),
                      const SizedBox(height: 24),
                      _buildSectionHeader('SYSTEM'),
                      _buildNavItem(Icons.settings_outlined, 'Settings', 6),
                    ],
                  ),
                ),

                // User Profile Footer
                _buildUserFooter(auth),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: AppTheme.deepBlack,
              child: Column(
                children: [
                  if (_selectedIndex != 4) _buildTopBar(),
                  Expanded(
                    child: _buildCurrentView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.cyanAccent, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 1.seconds).fadeIn(duration: 1.seconds),
          const SizedBox(width: 8),
          const Text('UPLINK ACTIVE', style: TextStyle(color: AppTheme.cyanAccent, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppTheme.textDimmed, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isActive ? AppTheme.mattBox(color: AppTheme.elevatedSurface) : null,
          child: Row(
            children: [
              Icon(icon, color: isActive ? AppTheme.cyanAccent : AppTheme.textGrey, size: 18),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: isActive ? Colors.white : AppTheme.textGrey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserFooter(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderGlow))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.elevatedSurface,
            backgroundImage: auth.userProfile?['avatar_url'] != null ? NetworkImage(auth.userProfile!['avatar_url']) : null,
            child: auth.userProfile?['avatar_url'] == null ? const Icon(Icons.person, color: AppTheme.cyanAccent, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.username ?? 'Uplink', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Pro Tier', style: TextStyle(fontSize: 10, color: AppTheme.cyanAccent.withOpacity(0.6))),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 18), onPressed: () => auth.logout()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    String title = 'Repositories';
    if (_selectedIndex == 1) title = 'Sync Status';
    if (_selectedIndex == 2) title = 'Git Status';
    if (_selectedIndex == 3) title = 'GitHub Actions';
    if (_selectedIndex == 4) title = 'Web Editor';
    if (_selectedIndex == 5) title = 'Analytics';
    if (_selectedIndex == 6) title = 'Settings';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(bottom: BorderSide(color: AppTheme.borderGlow)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          Row(
            children: [
              if (_selectedIndex == 0) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('CREATE REPO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ProjectWizard(onProjectCreated: _loadRepos),
                    );
                  },
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('SCAN LOCAL'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => LocalScanDialog(onRefresh: _loadRepos),
                    );
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('REFRESH'),
                  onPressed: _loadRepos,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return RepositoriesView(
          repos: _repos,
          isLoading: _isLoading,
          error: _error,
          onRefresh: _loadRepos,
          onSync: (index) => _handleSync(context, _repos![index]),
        );
      case 1:
        return const SyncStatusView();
      case 2:
        // Git Status - use first repo as example, or allow selection
        final repoPath = _repos != null && _repos!.isNotEmpty
            ? '/home/cube/syncstack/${_repos![0]['full_name']}'
            : null;
        final repoName = _repos != null && _repos!.isNotEmpty
            ? _repos![0]['full_name']
            : null;
        return GitStatusScreen(
          repoPath: repoPath,
          repoName: repoName,
        );
      case 3:
        final repoName = _repos != null && _repos!.isNotEmpty
            ? _repos![0]['full_name']
            : 'opendev-labs/syncstack-desk'; // Fallback
        return ActionsView(repoFullName: repoName);
      case 4:
        return const WebEditorScreen();
      case 5:
        return const AnalyticsView();
      case 6:
        return const SettingsView();
      default:
        return const Center(child: Text('Coming Soon', style: TextStyle(color: AppTheme.textGrey)));
    }
  }

  Future<void> _handleSync(BuildContext context, Map<String, dynamic> repo) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    
    // Default sync path
    String syncPath = '/home/cube/syncstack/${repo['full_name']}';
    
    try {
      // Check if we should ask for a path (e.g. if it doesn't exist yet)
      final bool exists = await Directory(syncPath).exists();
      
      if (!exists) {
        final String? selectedPath = await _pickDirectory(context, repo['name']);
        if (selectedPath == null) return;
        syncPath = selectedPath;
      }

      syncProvider.startSync(repo['full_name']);
      
      final result = await _ghService.syncRepo(
        syncPath,
        repo['full_name'],
        repo['clone_url'],
        auth.token!,
        'pull',
      );

      if (mounted) {
        syncProvider.completeSync(
          repo['full_name'],
          result['success'],
          message: result['message'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] ? 'Sync successful' : 'Sync failed: ${result['message']}'),
            backgroundColor: result['success'] ? AppTheme.cyanAccent : AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        syncProvider.completeSync(repo['full_name'], false, message: e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<String?> _pickDirectory(BuildContext context, String repoName) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: AppTheme.cyanAccent)),
        title: Text('SYNC DESTINATION: $repoName', style: const TextStyle(fontSize: 14, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose where to link this repository locally.', style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            const SizedBox(height: 16),
            Text('Default Path:', style: TextStyle(fontSize: 10, color: AppTheme.cyanAccent.withOpacity(0.7))),
            Text('/home/cube/syncstack/$repoName', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, '/home/cube/syncstack/$repoName'),
            child: const Text('PROCEED WITH DEFAULT'),
          ),
        ],
      ),
    );
  }
}

class _RepoCard extends StatefulWidget {
  final Map<String, dynamic> repo;
  final GHService ghService;
  final String token;
  final int index;

  const _RepoCard({
    required this.repo,
    required this.ghService,
    required this.token,
    required this.index,
  });

  @override
  State<_RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends State<_RepoCard> {
  bool _isSyncing = false;
  String _statusMessage = 'READY';
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.elevatedSurface
              : AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isHovered
                ? AppTheme.cyanAccent
                : AppTheme.borderGlow,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.elevatedSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: AppTheme.cyanAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.repo['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.repo['private'] == true)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.warningOrange.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'PRIVATE',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 0.5,
                                color: AppTheme.warningOrange,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  widget.repo['description'] ?? 'No description available',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetaChip(
                    Icons.star_border,
                    widget.repo['stargazers_count'].toString(),
                  ),
                  const SizedBox(width: 8),
                  if (widget.repo['language'] != null)
                    _buildMetaChip(
                      Icons.code,
                      widget.repo['language'],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: _statusMessage == 'SUCCESS'
                          ? AppTheme.cyanAccent
                          : AppTheme.textDimmed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSyncing ? null : _syncRepo,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.elevatedSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.2)),
                        ),
                        child: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.cyanAccent,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                size: 16,
                                color: AppTheme.cyanAccent,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: (widget.index * 50).ms)
          .slideY(begin: 0.2, end: 0, delay: (widget.index * 50).ms),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textGrey),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Future<void> _syncRepo() async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    final String syncPath = '/home/cube/syncstack/${widget.repo['full_name']}';
    syncProvider.startSync(widget.repo['full_name']);

    try {
      final result = await widget.ghService.syncRepo(
        syncPath,
        widget.repo['full_name'],
        widget.repo['clone_url'],
        widget.token,
        'pull',
      );

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _statusMessage = result['success'] ? 'SUCCESS' : 'FAILED';
        });

        syncProvider.completeSync(
          widget.repo['full_name'],
          result['success'],
          message: result['message'],
        );

        if (!result['success'] && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Sync failed'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'ERROR';
        });
      }
    }
  }
}
