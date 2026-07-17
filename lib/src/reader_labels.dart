import 'package:flutter/widgets.dart';

/// 阅读器所有对外文案的集合，支持本地化 / 白标定制。
///
/// 业务方可传入自定义实例（如英文版），未提供时使用中文默认值。
/// 组件内部通过 [ReaderLabels.of] 就近读取，避免逐层透传。
@immutable
class ReaderLabels {
  const ReaderLabels({
    this.loading = '加载中…',
    this.loadFailed = '加载失败',
    this.retry = '重试',
    this.prevChapter = '上一章',
    this.nextChapter = '下一章',
    this.catalog = '目录',
    this.themeMenu = '主题',
    this.dayMode = '日间',
    this.nightMode = '夜间',
    this.settingsMenu = '设置',
    this.fontSize = '字号',
    this.lineSpacing = '行距',
    this.flipMode = '翻页',
    this.background = '背景 / 主题',
    this.bookEnd = '—— 全书完 ——',
    this.loadingNext = '正在载入下一章…',
    this.more = '更多',
    this.back = '返回',
  });

  final String loading;
  final String loadFailed;
  final String retry;
  final String prevChapter;
  final String nextChapter;
  final String catalog;
  final String themeMenu;
  final String dayMode;
  final String nightMode;
  final String settingsMenu;
  final String fontSize;
  final String lineSpacing;
  final String flipMode;
  final String background;
  final String bookEnd;
  final String loadingNext;
  final String more;
  final String back;

  /// “第 x/N 章”
  String chapterProgress(int index, int count) => '第 ${index + 1}/$count 章';

  /// “共 N 章”
  String chapterTotal(int count) => '共 $count 章';

  static const ReaderLabels fallback = ReaderLabels();

  static ReaderLabels of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderLabelsScope>()?.labels ??
      fallback;
}

/// 向子树提供 [ReaderLabels]。
class ReaderLabelsScope extends InheritedWidget {
  const ReaderLabelsScope({
    super.key,
    required this.labels,
    required super.child,
  });

  final ReaderLabels labels;

  @override
  bool updateShouldNotify(ReaderLabelsScope oldWidget) =>
      labels != oldWidget.labels;
}
