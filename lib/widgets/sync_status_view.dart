import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sync_provider.dart';

class SyncStatusView extends StatelessWidget {
  const SyncStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = Provider.of<SyncProvider>(context);
    final activeSyncs = syncProvider.activeSyncList;
    final history = syncProvider.history;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real-Time Sync Monitor',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitor all repository synchronization activities',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (history.isNotEmpty)
                TextButton.icon(
                  onPressed: () => syncProvider.clearHistory(),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('CLEAR HISTORY'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Active Syncs
          if (activeSyncs.isNotEmpty) ...[
            _buildSectionHeader(context, 'ACTIVE SYNCS', Icons.sync_rounded),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.mattBox(),
              child: Column(
                children: activeSyncs.map((sync) => _buildSyncCard(
                  sync.repoName,
                  sync.status,
                  sync.progress,
                  AppTheme.cyanAccent,
                  isActive: true,
                )).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ] else if (history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    Icon(Icons.sync_disabled, size: 48, color: AppTheme.textDimmed.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text('NO ACTIVE SYNCS', style: TextStyle(color: AppTheme.textDimmed, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          
          // Recent Activity
          if (history.isNotEmpty) ...[
            _buildSectionHeader(context, 'RECENT ACTIVITY', Icons.history),
            const SizedBox(height: 16),
            Container(
              decoration: AppTheme.mattBox(),
              child: Column(
                children: history.map((activity) => _buildActivityItem(
                  activity.repoName,
                  activity.status,
                  _formatTimestamp(activity.timestamp),
                  !activity.isFailed,
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${ts.day}/${ts.month}';
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.cyanAccent, size: 18),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncCard(
    String repo,
    String status,
    double progress,
    Color color, {
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderGlow)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(0),
                  child: Icon(
                    isActive ? Icons.sync_rounded : Icons.check_circle,
                    color: color,
                    size: 20,
                  ),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.elevatedSurface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildActivityItem(
    String repo,
    String message,
    String time,
    bool success,
  ) {
    final color = success ? AppTheme.cyanAccent : AppTheme.errorRed;
    final icon = success ? Icons.check_circle : Icons.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderGlow),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textGrey.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
