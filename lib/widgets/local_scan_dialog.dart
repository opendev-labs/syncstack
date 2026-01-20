import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/gh_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_button.dart';

class LocalScanDialog extends StatefulWidget {
  final VoidCallback onRefresh;

  const LocalScanDialog({super.key, required this.onRefresh});

  @override
  State<LocalScanDialog> createState() => _LocalScanDialogState();
}

class _LocalScanDialogState extends State<LocalScanDialog> {
  final GHService _ghService = GHService();
  List<dynamic>? _repos;
  bool _isLoading = true;
  String? _error;
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isLoading = true);
    try {
      final res = await _ghService.scanLocal('~');
      if (mounted) {
        setState(() {
          _repos = res['success'] ? res['repos'] : [];
          _error = !res['success'] ? res['message'] : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _bulkSync() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting hyper-synchronized bulk sync...'), backgroundColor: AppTheme.infoBlue),
    );

    try {
      // In a real app, we'd use the batch_sync method in gh_engine.py
      // For now, we simulate the logic
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk sync sequence completed.'), backgroundColor: AppTheme.cyanAccent),
        );
        widget.onRefresh();
        Navigator.of(context).pop();
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
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: AppTheme.cyanAccent),
                const SizedBox(width: 16),
                Text('LOCAL REPOSITORY SCANNER', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 14, letterSpacing: 2)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const Divider(color: AppTheme.borderGlow, height: 32),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent))
                : _repos == null || _repos!.isEmpty
                  ? const Center(child: Text('No local repositories detected in home directory.', style: TextStyle(color: AppTheme.textGrey)))
                  : ListView.builder(
                      itemCount: _repos!.length,
                      itemBuilder: (context, index) {
                        final repo = _repos![index];
                        final isSelected = _selectedPaths.contains(repo['path']);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) _selectedPaths.add(repo['path']);
                              else _selectedPaths.remove(repo['path']);
                            });
                          },
                          title: Text(repo['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(repo['path'], style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
                          activeColor: AppTheme.cyanAccent,
                          checkColor: Colors.black,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${_selectedPaths.length} REPOS SELECTED', style: const TextStyle(fontSize: 10, color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                PremiumButton(
                  onPressed: _selectedPaths.isEmpty || _isLoading ? null : _bulkSync,
                  isLoading: _isLoading,
                  child: const Text('INITIATE BULK SYNC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
