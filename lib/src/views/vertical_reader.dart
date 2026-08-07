import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../paginator.dart';
import '../reader_labels.dart';
import '../widgets/page_frame.dart';
import 'reader_mode_view.dart';

/// 上下滚动模式：多章连续流式滚动。
///
/// 临近底部自动接上下一章、临近顶部自动接上上一章（并补偿滚动位置），无需按钮；
/// 顶部标题 / 进度依据视口所处章节实时更新。
class VerticalReader extends ReaderModeView {
  const VerticalReader({
    super.key,
    required super.controller,
    required this.onTapToggleMenu,
  });

  final VoidCallback onTapToggleMenu;

  @override
  State<VerticalReader> createState() => _VerticalReaderState();
}

class _VerticalReaderState extends ReaderModeViewState<VerticalReader>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _sectionKeys = <int, GlobalKey>{};

  /// 自动阅读：按速度平滑向下滚（约「一屏 / autoTurnInterval」）。
  late final Ticker _autoTicker = createTicker(_onAutoTick);
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    controller.addListener(_syncAutoScroll);
    _syncAutoScroll();
  }

  /// 依据自动阅读开关启停滚动 ticker。
  void _syncAutoScroll() {
    if (controller.autoTurning) {
      if (!_autoTicker.isActive) {
        _lastTick = Duration.zero;
        _autoTicker.start();
      }
    } else if (_autoTicker.isActive) {
      _autoTicker.stop();
    }
  }

  void _onAutoTick(Duration elapsed) {
    if (!_scrollController.hasClients) return;
    final double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0) return;
    final ScrollPosition pos = _scrollController.position;
    final double secs = controller.autoTurnInterval.inMilliseconds / 1000.0;
    // 速度：约「一屏 / 间隔」像素每秒。
    final double speed =
        secs > 0 ? pos.viewportDimension / secs : pos.viewportDimension;
    final double next = pos.pixels + speed * dt;
    if (next >= pos.maxScrollExtent) {
      _scrollController.jumpTo(pos.maxScrollExtent);
      // 到底且已是最后一章：停止自动阅读；否则 _onScroll 会自动接入下一章继续。
      if (controller.flowChapters.last >= controller.chapterCount - 1) {
        controller.setAutoTurning(false);
      }
    } else {
      _scrollController.jumpTo(next);
    }
  }

  @override
  void dispose() {
    _autoTicker.dispose();
    controller.removeListener(_syncAutoScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final ScrollMetrics m = n.metrics;
    if (m.pixels >= m.maxScrollExtent - 800) {
      controller.appendNextFlowChapter();
    }
    if (m.pixels <= 400) {
      final int? inserted = controller.prependPrevFlowChapter();
      if (inserted != null) _compensateForPrepend(inserted, m.pixels);
    }
    _updateCurrentChapter();
    return false;
  }

  /// 头部插入章节后，把滚动位置整体下移其高度，保持原本阅读处不动。
  void _compensateForPrepend(int idx, double before) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final RenderBox? box =
          _sectionKeys[idx]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      _scrollController.jumpTo(before + box.size.height);
    });
  }

  /// 依据视口顶部落在哪一章的区块，更新“当前章”。
  void _updateCurrentChapter() {
    final RenderBox? listBox =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final double viewportTop = listBox.localToGlobal(Offset.zero).dy;

    int current = controller.flowChapters.first;
    for (final int idx in controller.flowChapters) {
      final RenderBox? box =
          _sectionKeys[idx]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy <= viewportTop + 8) {
        current = idx;
      } else {
        break;
      }
    }
    controller.setCurrentChapter(current);
  }

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    final int count = controller.flowChapters.length;
    // 全书开头（第 0 章在流首）时，顶部插入扉页，随内容一起滚动。
    final bool showTitle =
        controller.hasTitlePage && controller.flowChapters.first == 0;
    final int lead = showTitle ? 1 : 0;
    // 连续滚动模式：顶部当前章节信息、底部章节进度为固定信息栏（中间列表滚动）。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTapToggleMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: pagePadding.left,
              right: pagePadding.right,
              top: pagePadding.top,
            ),
            child: ReaderHeaderBar(
              title: controller.currentChapterTitle,
              theme: theme,
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              // builder 惰性构建，滚出视口的章节会被回收，避免 RenderObject 无限驻留
              child: ListView.builder(
                key: _listKey,
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: pagePadding.left,
                  right: pagePadding.right,
                ),
                itemCount: count + 1 + lead,
                itemBuilder: (BuildContext context, int i) {
                  if (showTitle && i == 0) return _titleSection(context);
                  final int j = i - lead;
                  return j < count
                      ? _section(context, controller.flowChapters[j], labels)
                      : _footer(labels);
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: pagePadding.left,
              right: pagePadding.right,
              bottom: pagePadding.bottom,
            ),
            child: ReaderFooterBar(
              theme: theme,
              chapterIndex: controller.chapterIndex,
              chapterCount: controller.chapterCount,
              pageIndex: 0,
              pageCount: 0, // 连续滚动无页码，仅显示章号与进度
              progress: controller.globalProgress,
            ),
          ),
        ],
      ),
    );
  }

  /// 竖滚模式下的扉页：约占一屏高，随内容向上滚出。
  Widget _titleSection(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: controller.titlePageBuilder!(context, theme),
    );
  }

  Widget _section(BuildContext context, int idx, ReaderLabels labels) {
    final bool isFirst = idx == controller.flowChapters.first;
    final String? body = controller.bodyOf(idx);
    return Column(
      key: _sectionKeys.putIfAbsent(idx, () => GlobalKey()),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!isFirst) ...<Widget>[
          const SizedBox(height: 8),
          Divider(color: theme.subTextColor.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
        ],
        Text(
          controller.chapterTitleAt(idx),
          style: TextStyle(
            fontSize: config.fontSize + 4,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 16),
        _sectionBody(context, idx, body, labels),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 付费章预览取多少字（连续滚动无分页，用定长预览近似「第一页」）。
  static const int _lockPreviewChars = 500;

  /// 取章节开头约 [_lockPreviewChars] 字作为付费章预览内容。
  ReaderPage _lockedPreview(ReaderPage page) {
    final List<ReaderBlock> out = <ReaderBlock>[];
    int chars = 0;
    for (final ReaderBlock b in page) {
      out.add(b);
      chars += b.length;
      if (chars >= _lockPreviewChars) break;
    }
    return out;
  }

  Widget _sectionBody(
      BuildContext context, int idx, String? body, ReaderLabels labels) {
    // 未解锁付费章：显示开头一段预览 + 解锁块（连续滚动无“页”，取定长预览作“部分内容”）。
    if (controller.chapterLocked(idx) && controller.chapterLockBuilder != null) {
      final Widget lockBlock = controller.chapterLockBuilder!(
        context,
        theme,
        controller.lockInfoFor(idx),
      );
      if (body == null) return lockBlock; // 正文未加载：仅显示解锁块
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReaderProse(
            page: _lockedPreview(controller.chapterBlocks(body)),
            config: config,
            chapterIndex: idx,
            chapterTitle: controller.chapterTitleAt(idx),
          ),
          lockBlock,
        ],
      );
    }
    if (body != null) {
      return ReaderProse(
        page: controller.chapterBlocks(body),
        config: config,
        chapterIndex: idx,
        chapterTitle: controller.chapterTitleAt(idx),
      );
    }
    if (controller.hasError(idx)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: <Widget>[
            Text(
              labels.loadFailed,
              style: TextStyle(fontSize: 13, color: theme.subTextColor),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => controller.retry(idx),
              style: TextButton.styleFrom(foregroundColor: theme.accentColor),
              child: Text(labels.retry),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        labels.loading,
        style: TextStyle(fontSize: 13, color: theme.subTextColor),
      ),
    );
  }

  Widget _footer(ReaderLabels labels) {
    final bool isLast =
        controller.flowChapters.last >= controller.chapterCount - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          isLast ? labels.bookEnd : labels.loadingNext,
          style: TextStyle(fontSize: 13, color: theme.subTextColor),
        ),
      ),
    );
  }
}
