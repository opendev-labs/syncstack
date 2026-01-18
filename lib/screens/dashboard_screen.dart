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
                            colorFilter: const ColorFilter.mode(AppTheme.neonGreen, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'GH SYNC',
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
                      _buildNavItem(Icons.analytics_outlined, 'Analytics', 2),
                      const SizedBox(height: 24),
                      _buildSectionHeader('SYSTEM'),
                      _buildNavItem(Icons.settings_outlined, 'Settings', 3),
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
                  _buildTopBar(),
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
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 1.seconds).fadeIn(duration: 1.seconds),
          const SizedBox(width: 8),
          const Text('UPLINK ACTIVE', style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
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
              Icon(icon, color: isActive ? AppTheme.neonGreen : AppTheme.textGrey, size: 18),
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
            child: auth.userProfile?['avatar_url'] == null ? const Icon(Icons.person, color: AppTheme.neonGreen, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.username ?? 'Uplink', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Pro Tier', style: TextStyle(fontSize: 10, color: AppTheme.neonGreen.withOpacity(0.6))),
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
    if (_selectedIndex == 2) title = 'Analytics';
    if (_selectedIndex == 3) title = 'Settings';

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
          if (_selectedIndex == 0)
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('REFRESH'),
              onPressed: _loadRepos,
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
          onSync: (i) {}, // TODO: Implement sync logic
        );
      case 2:
        return const AnalyticsView();
      case 3:
        return const SettingsView();
      default:
        return const Center(child: Text('Coming Soon', style: TextStyle(color: AppTheme.textGrey)));
    }
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
                ? AppTheme.neonGreen
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
                      border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: AppTheme.neonGreen,
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
                          ? AppTheme.neonGreen
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
                          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
                        ),
                        child: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.neonGreen,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                size: 16,
                                color: AppTheme.neonGreen,
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
    setState(() {
      _isSyncing = true;
      _statusMessage = 'SYNCING...';
    });

    final syncPath = '/home/cube/Gh-sync/${widget.repo['full_name']}';

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
