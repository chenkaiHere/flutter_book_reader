import 'package:flutter/widgets.dart';

import 'comment/reader_comment_store.dart';
import 'underline/reader_underline_store.dart';

/// 阅读页长按选中文字后，操作工具条上的动作类型。
///
/// 除 [highlight]（划线）由阅读器内部渲染 / 持久化外，其余动作（复制 / 评论 / 查询 /
/// 分享）都不在插件内做任何副作用，只通过 [ReaderTextActionCallback] 回调给业务方，
/// 由业务方决定如何处理（写剪贴板、弹自定义评论框、跳转词典、调起分享…）。
enum ReaderTextAction {
  /// 复制：插件不写剪贴板，仅回调（业务方自行复制 / 提示）。
  copy,

  /// 划线 / 高亮：由阅读器内部渲染并持久化（不走回调）。
  highlight,

  /// 评论 / 想法：插件仅回调，业务方自行弹出输入界面并保存。
  comment,

  /// 查询 / 词典：交给业务方。
  query,

  /// 分享：交给业务方。
  share,
}

/// 一次选中的详情：章号 + 章标题 + 章内 [start,end) 区间 + 文字快照。
///
/// [start] / [end] 为「块长度空间」偏移（与书签 / 划线 / 评论同一套锚点，换字号后仍
/// 精确），业务方可据此构造并持久化一条 [Comment]；无法解析区间时为 -1。
@immutable
class ReaderSelection {
  const ReaderSelection({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.start,
    required this.end,
    required this.text,
  });

  final int chapterIndex;
  final String chapterTitle;
  final int start;
  final int end;
  final String text;
}

/// 用户点击选中工具条上某个动作时回调；[selection] 携带选中详情。
typedef ReaderTextActionCallback = void Function(
    ReaderTextAction action, ReaderSelection selection);

/// 向阅读子树提供「长按选中文字」的开关与回调。为空 / disabled 时不启用选择。
class ReaderSelectionScope extends InheritedWidget {
  const ReaderSelectionScope({
    super.key,
    required this.enabled,
    required this.onAction,
    required super.child,
  });

  final bool enabled;
  final ReaderTextActionCallback? onAction;

  static ReaderSelectionScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderSelectionScope>();

  @override
  bool updateShouldNotify(ReaderSelectionScope old) =>
      enabled != old.enabled || onAction != old.onAction;
}

/// 向阅读子树提供「划线」的当前数据与增删回调。
/// [ReaderProse] 据此渲染已存在的划线，并在选中工具条上新增 / 删除划线。
class ReaderUnderlineScope extends InheritedWidget {
  const ReaderUnderlineScope({
    super.key,
    required this.underlines,
    required this.onAdd,
    required this.onRemove,
    required super.child,
  });

  /// 全书划线（[ReaderProse] 自行按当前章过滤）。
  final List<Underline> underlines;

  /// 新增一条划线：给出章号 + 章内 [start,end) + 文字快照，由外层补全标题/时间并持久化。
  final void Function(int chapterIndex, int start, int end, String text) onAdd;

  /// 删除若干条已存在的划线。
  final void Function(List<Underline> targets) onRemove;

  static ReaderUnderlineScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderUnderlineScope>();

  @override
  bool updateShouldNotify(ReaderUnderlineScope old) =>
      !identical(underlines, old.underlines) ||
      onAdd != old.onAdd ||
      onRemove != old.onRemove;
}

/// 点击某段落尾部「段评」数字角标时回调的载荷：定位到某章的段落区间 [start,end)，
/// 以及该段当前评论数 [count]。业务方据此筛选自己的评论数据并弹出评论列表。
@immutable
class ReaderSegmentTap {
  const ReaderSegmentTap({
    required this.chapterIndex,
    required this.start,
    required this.end,
    required this.count,
  });

  final int chapterIndex;

  /// 段落在本章「块长度空间」的起止（与 [Comment.start] 同坐标）。
  final int start;
  final int end;

  /// 该段落当前评论数（角标显示的数字）。
  final int count;

  /// 该段落是否包含某条评论（按评论锚点 start 落在 [start,end) 判定）。
  bool contains(Comment c) =>
      c.chapterIndex == chapterIndex && c.start >= start && c.start < end;
}

typedef ReaderSegmentTapCallback = void Function(ReaderSegmentTap segment);

/// 向阅读子树提供「段评」数据与点击回调。
///
/// [ReaderProse] 据 [comments] 统计每个段落的评论数，在段尾渲染数字角标；点击角标时
/// 只通过 [onTap] 把段落信息抛给业务方（插件不弹列表），由业务方自行弹出评论列表。
class ReaderSegmentScope extends InheritedWidget {
  const ReaderSegmentScope({
    super.key,
    required this.comments,
    required this.onTap,
    required super.child,
  });

  /// 全书评论（[ReaderProse] 自行按当前章 + 段落区间过滤计数）。
  final List<Comment> comments;

  /// 点击段尾角标的回调；为空时不显示角标。
  final ReaderSegmentTapCallback? onTap;

  static ReaderSegmentScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderSegmentScope>();

  @override
  bool updateShouldNotify(ReaderSegmentScope old) =>
      !identical(comments, old.comments) || onTap != old.onTap;
}

/// 向阅读子树提供「当前朗读位置」的高亮区间（听书跟读用）。[chapterIndex] 为该区间所属
/// 章；[start,end) 为章内「块长度空间」偏移；区间无效（start<0 / end<=start）时不高亮。
class ReaderReadingScope extends InheritedWidget {
  const ReaderReadingScope({
    super.key,
    required this.chapterIndex,
    required this.start,
    required this.end,
    required super.child,
  });

  final int chapterIndex;
  final int start;
  final int end;

  static ReaderReadingScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderReadingScope>();

  @override
  bool updateShouldNotify(ReaderReadingScope old) =>
      chapterIndex != old.chapterIndex || start != old.start || end != old.end;
}
