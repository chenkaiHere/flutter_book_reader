import 'package:flutter/widgets.dart';

import 'reader_theme.dart';

/// 判定某章是否为「未解锁的付费章」。
///
/// 返回 true 时，该章只展示第一页正文、底部叠加 [ReaderChapterLockBuilder] 提供的
/// 解锁块，且未解锁状态下向后翻页会直接跳到下一章（跳过本章其余内容）。
typedef ReaderChapterLockPredicate = bool Function(int chapterIndex);

/// 构建付费章首页底部的「解锁块」（如“订阅本章”按钮）。
///
/// 样式与点击行为**完全由业务方定义**：阅读器只负责把它叠在首页底部、并在其上方
/// 加一层纸张色渐变蒙层让正文自然淡出。业务方解锁成功后更新自己的锁定状态并触发
/// `BookReader.lockRefresh` 即可，阅读器会重新判定并展开整章。
typedef ReaderChapterLockBuilder = Widget Function(
  BuildContext context,
  ReaderTheme theme,
  ReaderLockInfo info,
);

/// 传给 [ReaderChapterLockBuilder] 的章节信息，便于业务方渲染“订阅本章 / 3143字”等。
@immutable
class ReaderLockInfo {
  const ReaderLockInfo({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.wordCount,
    this.isScrollMode = false,
  });

  /// 章节下标（从 0 起）。
  final int chapterIndex;

  /// 章节标题。
  final String chapterTitle;

  /// 本章正文字符数（业务方可据此显示“字数”）。
  final int wordCount;

  /// 当前是否为「上下滚动」连续模式（分页模式为 false）。
  ///
  /// 连续模式没有整页概念，解锁块直接跟在预览正文后面；业务方可据此调整留白 ——
  /// 分页模式常把按钮顶到页面底部（大留白），连续模式则应紧凑显示。
  final bool isScrollMode;
}
