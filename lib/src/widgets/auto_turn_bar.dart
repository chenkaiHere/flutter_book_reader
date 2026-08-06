import 'package:flutter/material.dart';

import '../reader_theme.dart';

/// 自动翻页时屏幕右侧的「本页倒计时」竖线进度条（竖屏显示）。
///
/// 一条较浅的竖直轨道，其中的填充随本页计时从上到下增长；翻页时归零重新开始，
/// 直观提示「还有多久翻到下一页」。非交互（[IgnorePointer]）。
///
/// 用显式 [Positioned] 给轨道定高、按 `进度 × 高度` 从顶部填充，避免松约束下高度
/// 坍缩导致看不见。
class AutoTurnProgressBar extends StatelessWidget {
  const AutoTurnProgressBar({
    super.key,
    required this.progress,
    required this.theme,
  });

  /// 0~1 的本页计时进度（由自动翻页的计时动画驱动）。
  final Animation<double> progress;
  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    final Color track = theme.subTextColor.withValues(alpha: 0.16);
    final Color fill = theme.accentColor.withValues(alpha: 0.6);
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints cons) {
                final double h = cons.maxHeight;
                return AnimatedBuilder(
                  animation: progress,
                  builder: (BuildContext context, _) {
                    final double v = progress.value.clamp(0.0, 1.0);
                    return Stack(
                      children: <Widget>[
                        // 轨道底色。
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: track,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // 填充：从顶部按进度增长。
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: h * v,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
