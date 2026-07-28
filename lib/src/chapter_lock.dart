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
  });

  /// 章节下标（从 0 起）。
  final int chapterIndex;

  /// 章节标题。
  final String chapterTitle;

  /// 本章正文字符数（业务方可据此显示“字数”）。
  final int wordCount;
}
