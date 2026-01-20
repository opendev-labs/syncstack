import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/local_scan_dialog.dart';
import '../widgets/status_indicator.dart';
import '../widgets/premium_button.dart';
import '../widgets/project_wizard.dart'; // Added import for ProjectWizard

// --- Repositories View ---
class RepositoriesView extends StatelessWidget {
  final List<dynamic>? repos;
  final bool isLoading;
  final String? error;
  final Function(int) onSync;
  final VoidCallback onRefresh;

  const RepositoriesView({
    super.key,
    required this.repos,
    required this.isLoading,
    this.error,
    required this.onSync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext  context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent));
    if (error != null) return Center(child: Text('Error: $error', style: const TextStyle(color: AppTheme.errorRed)));
    if (repos == null || repos!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No repositories found.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'Access and manage your cloud-hosted repositories',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the row of buttons
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => LocalScanDialog(onRefresh: onRefresh),
                    );
                  },
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('SCAN LOCAL'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ProjectWizard(onProjectCreated: onRefresh),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('CREATE REPOSITORY'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: repos!.length,
      itemBuilder: (context, index) {
        final repo = repos![index];
        return _EnhancedRepoCard(
          repo: repo,
          onSync: () => onSync(index),
        );
      },
    );
  }
}

class _EnhancedRepoCard extends StatefulWidget {
  final Map<String, dynamic> repo;
  final VoidCallback onSync;

  const _EnhancedRepoCard({required this.repo, required this.onSync});

  @override
  State<_EnhancedRepoCard> createState() => _EnhancedRepoCardState();
}

class _EnhancedRepoCardState extends State<_EnhancedRepoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.elevatedSurface : AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isHovered ? AppTheme.cyanAccent : AppTheme.borderGlow,
            width: 1,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: AppTheme.cyanAccent.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : [],
        ),
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
                  ),
                  child: const Icon(Icons.folder_outlined, color: AppTheme.cyanAccent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.repo['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.repo['private'] == true)
                        Text(
                          'PRIVATE REPO',
                          style: TextStyle(fontSize: 9, color: AppTheme.warningOrange.withOpacity(0.7), letterSpacing: 0.5),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                widget.repo['description'] ?? 'No description provided.',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.repo['language'] != null) ...[
                  Icon(Icons.code, size: 12, color: AppTheme.textDimmed),
                  const SizedBox(width: 4),
                  Text(widget.repo['language'], style: const TextStyle(fontSize: 11, color: AppTheme.textDimmed)),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.star_outline, size: 12, color: AppTheme.textDimmed),
                const SizedBox(width: 4),
                Text('${widget.repo['stargazers_count']}', style: const TextStyle(fontSize: 11, color: AppTheme.textDimmed)),
              ],
            ),
            const Divider(color: AppTheme.borderGlow, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StatusIndicator(status: SyncStatus.idle, message: 'READY'),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSync,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sync_rounded, color: AppTheme.cyanAccent, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Analytics View ---
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Overview', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildStatCard('Total Commits', '1,234', Icons.commit),
                _buildStatCard('Sync Success Rate', '99.8%', Icons.check_circle_outline),
                _buildStatCard('Disk Usage', '45.2 GB', Icons.storage),
                _buildStatCard('Active Repos', '12', Icons.folder_shared),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: AppTheme.mattBox(),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.cyanAccent, size: 32),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- Settings View ---
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoSync = true;
  double _syncInterval = 30;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Preferences', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 32),
          _buildSettingSection('General', [
            _buildSwitchTile('Automatic Synchronization', 'Keep your repositories updated in background', _autoSync, (v) => setState(() => _autoSync = v)),
            _buildSliderTile('Sync Interval (minutes)', _syncInterval, 5, 120, (v) => setState(() => _syncInterval = v)),
          ]),
          const SizedBox(height: 24),
          _buildSettingSection('Git Configuration', [
            _buildActionTile('Workspace Root', '/home/cube/syncstack', Icons.folder_open, () {}),
            _buildActionTile('Conflict Strategy', 'Pull (Rebase)', Icons.call_merge, () {}),
          ]),
          const SizedBox(height: 24),
          _buildSettingSection('Danger Zone', [
            _buildActionTile('Clear All Local Cache', 'Remove synced data', Icons.delete_forever, () {}, isDestructive: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.mattBox(),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.cyanAccent),
    );
  }

  Widget _buildSliderTile(String title, double value, double min, double max, ValueChanged<double> onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: 23,
        label: value.round().toString(),
        onChanged: onChanged,
        activeColor: AppTheme.cyanAccent,
      ),
      trailing: Text('${value.round()}m', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.errorRed : AppTheme.cyanAccent),
      title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.errorRed : Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
      onTap: onTap,
    );
  }
}
