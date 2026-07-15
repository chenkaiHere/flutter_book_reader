import 'package:flutter/material.dart';

import '../reader_labels.dart';
import '../reader_theme.dart';

/// 章节加载中 / 加载失败的占位页（主题自适应，失败时可重试）。
class ReaderStatusPage extends StatelessWidget {
  const ReaderStatusPage({
    super.key,
    required this.theme,
    this.error = false,
    this.onRetry,
  });

  final ReaderTheme theme;
  final bool error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    if (error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: theme.subTextColor, size: 28),
            const SizedBox(height: 12),
            Text(
              labels.loadFailed,
              style: TextStyle(fontSize: 14, color: theme.subTextColor),
            ),
            const SizedBox(height: 12),
            if (onRetry != null)
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.accentColor,
                  side: BorderSide(color: theme.accentColor),
                ),
                child: Text(labels.retry),
              ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.subTextColor),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            labels.loading,
            style: TextStyle(fontSize: 13, color: theme.subTextColor),
          ),
        ],
      ),
    );
  }
}
