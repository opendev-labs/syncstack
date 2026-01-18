import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_indicator.dart';
import '../widgets/premium_button.dart';

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
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
    if (error != null) return Center(child: Text('Error: $error', style: const TextStyle(color: AppTheme.errorRed)));
    if (repos == null || repos!.isEmpty) return const Center(child: Text('No repositories found.'));

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: repos!.length,
      itemBuilder: (context, index) {
        final repo = repos![index];
        return Container(
          decoration: AppTheme.mattBox(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_outlined, color: AppTheme.neonGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      repo['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                repo['description'] ?? 'No description',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusIndicator(status: SyncStatus.idle, message: 'READY'),
                  IconButton(
                    icon: const Icon(Icons.sync_rounded),
                    onPressed: () => onSync(index),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          Icon(icon, color: AppTheme.neonGreen, size: 32),
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
            _buildActionTile('Workspace Root', '/home/cube/Gh-sync', Icons.folder_open, () {}),
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
        Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.neonGreen, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
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
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.neonGreen),
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
        activeColor: AppTheme.neonGreen,
      ),
      trailing: Text('${value.round()}m', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.errorRed : AppTheme.neonGreen),
      title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.errorRed : Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
      onTap: onTap,
    );
  }
}
