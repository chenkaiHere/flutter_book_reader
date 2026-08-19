import 'package:flutter/widgets.dart';

import 'reader_theme.dart';

/// 构建「章末自定义组件」——排在每章正文之后的一块宿主内容。
///
/// 典型用途:本章讨论入口、给作者送礼物、章末广告位、下一章预告。样式与点击行为
/// **完全由业务方定义**;阅读器只负责把它排在该章最后一页的正文下方,并在分页时
/// 为它预留高度(见 `BookReader.chapterEndReserve`),因此正文不会被它挤掉或裁切。
typedef ReaderChapterEndBuilder = Widget Function(
  BuildContext context,
  ReaderTheme theme,
  ReaderChapterEndInfo info,
);

/// 传给 [ReaderChapterEndBuilder] 的章节信息。
@immutable
class ReaderChapterEndInfo {
  const ReaderChapterEndInfo({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.isLastChapter,
  });

  /// 章节下标(从 0 起)。
  final int chapterIndex;

  /// 章节标题。
  final String chapterTitle;

  /// 是否为全书最后一章(可据此换成「全书完」之类的收尾内容)。
  final bool isLastChapter;

  @override
  bool operator ==(Object other) =>
      other is ReaderChapterEndInfo &&
      other.chapterIndex == chapterIndex &&
      other.chapterTitle == chapterTitle &&
      other.isLastChapter == isLastChapter;

  @override
  int get hashCode => Object.hash(chapterIndex, chapterTitle, isLastChapter);
}
