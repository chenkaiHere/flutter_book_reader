import 'package:flutter/material.dart';

import '../reader_theme.dart';

/// 付费章首页的呈现：正文照常渲染，底部叠加业务方提供的解锁块（[lockBlock]）。
///
/// 解锁块外面包一层纸张色渐变（从上「全透明」到下「完全不透明」），让正文越靠近
/// 解锁块越淡、最终融进背景。渐隐范围随 [lockBlock] 自身高度而定（业务方通过其
/// 内边距 / 高度控制留出多长的渐隐区）。
class ReaderLockedPage extends StatelessWidget {
  const ReaderLockedPage({
    super.key,
    required this.theme,
    required this.child,
    required this.lockBlock,
  });

  final ReaderTheme theme;

  /// 正常渲染的首页内容（整页）。
  final Widget child;

  /// 业务方提供的解锁块（按钮等）。
  final Widget lockBlock;

  @override
  Widget build(BuildContext context) {
    final Color paper = theme.paperColor;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // 从上到下由「全透明」逐步过渡到「完全不透明的纸张色」，把正文渐隐住。
                colors: <Color>[
                  paper.withValues(alpha: 0),
                  paper.withValues(alpha: 0.85),
                  paper,
                ],
                stops: const <double>[0.0, 0.3, 1.0],
              ),
            ),
            child: lockBlock,
          ),
        ),
      ],
    );
  }
}
