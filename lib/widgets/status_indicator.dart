import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SyncStatus { idle, syncing, success, error }

class StatusIndicator extends StatefulWidget {
  final SyncStatus status;
  final String? message;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.message,
    this.size = 12,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.status == SyncStatus.syncing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.status == SyncStatus.syncing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.status) {
      case SyncStatus.idle:
        return AppTheme.textGrey;
      case SyncStatus.syncing:
        return AppTheme.infoBlue;
      case SyncStatus.success:
        return AppTheme.neonGreen;
      case SyncStatus.error:
        return AppTheme.errorRed;
    }
    return AppTheme.textGrey;
  }

  IconData _getIcon() {
    switch (widget.status) {
      case SyncStatus.idle:
        return Icons.circle_outlined;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
    }
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _getColor().withOpacity(
                  widget.status == SyncStatus.syncing
                      ? _pulseAnimation.value * 0.3
                      : 0.15,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getColor().withOpacity(
                    widget.status == SyncStatus.syncing
                        ? _pulseAnimation.value
                        : 1.0,
                  ),
                  width: 2,
                ),
              ),
              child: widget.status == SyncStatus.syncing
                  ? Center(
                      child: SizedBox(
                        width: widget.size * 0.6,
                        height: widget.size * 0.6,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _getColor(),
                        ),
                      ),
                    )
                  : null,
            ),
            if (widget.message != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.message!,
                style: TextStyle(
                  color: _getColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
