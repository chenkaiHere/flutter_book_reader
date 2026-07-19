import 'package:flutter/widgets.dart';

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
