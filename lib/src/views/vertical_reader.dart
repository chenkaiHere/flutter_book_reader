import 'package:flutter/material.dart';

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

class _VerticalReaderState extends ReaderModeViewState<VerticalReader> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _sectionKeys = <int, GlobalKey>{};

  @override
  void dispose() {
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTapToggleMenu,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        // builder 惰性构建，滚出视口的章节会被回收，避免 RenderObject 无限驻留
        child: ListView.builder(
          key: _listKey,
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          itemCount: count + 1,
          itemBuilder: (BuildContext context, int i) => i < count
              ? _section(controller.flowChapters[i], labels)
              : _footer(labels),
        ),
      ),
    );
  }

  Widget _section(int idx, ReaderLabels labels) {
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
        _sectionBody(idx, body, labels),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionBody(int idx, String? body, ReaderLabels labels) {
    if (body != null) {
      return ReaderProse(page: controller.chapterBlocks(body), config: config);
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
