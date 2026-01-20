import 'package:flutter/material.dart';

class SyncActivity {
  final String repoName;
  final String status;
  final double progress;
  final bool isCompleted;
  final bool isFailed;
  final DateTime timestamp;

  SyncActivity({
    required this.repoName,
    required this.status,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isFailed = false,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();
}

class SyncProvider extends ChangeNotifier {
  final Map<String, SyncActivity> _activeSyncs = {};
  final List<SyncActivity> _history = [];

  List<SyncActivity> get activeSyncList => _activeSyncs.values.toList();
  List<SyncActivity> get history => _history;

  void startSync(String repoName) {
    _activeSyncs[repoName] = SyncActivity(
      repoName: repoName,
      status: 'Initializing...',
      progress: 0.1,
    );
    notifyListeners();
  }

  void updateProgress(String repoName, String status, double progress) {
    if (_activeSyncs.containsKey(repoName)) {
      _activeSyncs[repoName] = SyncActivity(
        repoName: repoName,
        status: status,
        progress: progress,
      );
      notifyListeners();
    }
  }

  void completeSync(String repoName, bool success, {String? message}) {
    if (_activeSyncs.containsKey(repoName)) {
      final activity = SyncActivity(
        repoName: repoName,
        status: success ? 'Completed' : (message ?? 'Failed'),
        progress: 1.0,
        isCompleted: true,
        isFailed: !success,
      );
      _activeSyncs.remove(repoName);
      _history.insert(0, activity);
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
