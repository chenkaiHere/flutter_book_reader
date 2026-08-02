import 'package:flutter/material.dart';

import '../paginator.dart';
import '../reader_config.dart';
import '../widgets/loading_page.dart';
import '../widgets/locked_page.dart';
import '../widgets/page_frame.dart';
import 'reader_mode_view.dart';

/// 横向分页翻页视图（平滑 / 覆盖 / 仿真共用同一个 PageView，仅视觉变换不同）。
///
/// 页序：[上一章末页?] + 本章各页 + [下一章首页?]。边界页直接渲染相邻章的
/// 真实页面，滑过去内容即目标章，切章在后台完成、前后画面一致，因此无跳动。
class HorizontalReader extends ReaderModeView {
  const HorizontalReader({
    super.key,
    required super.controller,
    this.style = FlipType.slideHorizontal,
  });

  /// 翻页视觉样式：slideHorizontal（平滑）、cover（覆盖）、simulation（仿真）。
  final FlipType style;

  @override
  State<HorizontalReader> createState() => _HorizontalReaderState();
}

class _HorizontalReaderState extends ReaderModeViewState<HorizontalReader> {
  late PageController _pageController;
  late int _builtChapter;

  /// 第 0 章且配置了扉页时，正文各页之前多出的扉页页数（1）。
  bool get _hasTitle =>
      controller.hasTitlePage && controller.chapterIndex == 0;
  int get _titleLead => _hasTitle ? 1 : 0;

  /// 本章正文首页在 PageView 里的视图下标（含上一章边界页 + 扉页）。
  int get _front => controller.leading + _titleLead;

  /// 目标视图下标：在扉页则 0，否则正文页对应下标。
  int get _targetIndex =>
      controller.onTitlePage ? 0 : _front + controller.pageIndex;

  @override
  void initState() {
    super.initState();
    _builtChapter = controller.chapterIndex;
    _pageController = PageController(initialPage: _targetIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 父层在控制器变更时重建本组件，这里据最新状态调和 PageController。
  @override
  void didUpdateWidget(covariant HorizontalReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int target = _targetIndex;
    if (controller.chapterIndex != _builtChapter) {
      // 切章后本章正文可能仍在加载（pages 为空），此时 pageIndex 尚未据 charOffset
      // 解析出目标页，PageController 会以第 0 页初始化。等正文就绪、目标页确定后再
      // 重建控制器——否则书签/跳转跨章到未缓存章时会落回第一页。
      if (controller.pages.isEmpty) return;
      _builtChapter = controller.chapterIndex;
      _pageController.dispose();
      _pageController = PageController(initialPage: target);
    } else if (_pageController.hasClients) {
      final int current = (_pageController.page ?? target.toDouble()).round();
      if (current != target) {
        _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _deferCross(int index, {bool atEnd = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadChapter(index, atEnd: atEnd);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 当前章正文尚未就绪：整页加载态 / 失败可重试
    if (controller.pages.isEmpty) {
      final int idx = controller.chapterIndex;
      return ReaderStatusPage(
        theme: theme,
        error: controller.hasError(idx),
        onRetry: () => controller.retry(idx),
      );
    }

    final int trailing = controller.hasNext ? 1 : 0;
    // 未解锁付费章只放行首页，故本章可见页数用 visiblePageCount 而非全部页数。
    final int visible = controller.visiblePageCount;
    final int itemCount = _front + visible + trailing;

    return PageView.builder(
      key: ValueKey<int>(controller.chapterIndex),
      controller: _pageController,
      itemCount: itemCount,
      onPageChanged: (int v) {
        if (_hasTitle && v == 0) {
          controller.showTitlePage();
          return;
        }
        final int real = v - _front;
        if (real < 0) {
          _deferCross(controller.chapterIndex - 1, atEnd: true);
        } else if (real >= visible) {
          _deferCross(controller.chapterIndex + 1);
        } else {
          controller.goToPage(real);
        }
      },
      itemBuilder: (BuildContext context, int v) {
        final Widget page;
        if (_hasTitle && v == 0) {
          page = _titlePage();
        } else {
          final int real = v - _front;
          if (real < 0) {
            page = _boundaryFrame(controller.chapterIndex - 1, atEnd: true);
          } else if (real >= visible) {
            page = _boundaryFrame(controller.chapterIndex + 1, atEnd: false);
          } else {
            page = _frame(controller.chapterIndex, controller.pages, real);
          }
        }
        // 每页带不透明纸张底色：覆盖翻页时新页才能真正盖住下层，而非透视穿透。
        return _styled(v, ColoredBox(color: theme.paperColor, child: page));
      },
    );
  }

  Widget _titlePage() => controller.titlePageBuilder!(context, theme);

  /// 覆盖样式给每页叠加变换：当前及更早的页固定在原位（被盖住），
  /// 后一页从右侧自然滑入并投下左缘阴影。平滑样式则原样返回。
  Widget _styled(int viewIndex, Widget page) {
    if (widget.style != FlipType.cover) return page;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _pageController,
          child: page,
          builder: (BuildContext context, Widget? child) {
            final double current =
                _pageController.hasClients && _pageController.page != null
                    ? _pageController.page!
                    : _targetIndex.toDouble();
            final double delta = viewIndex - current;
            if (delta <= 0) {
              return Transform.translate(
                offset: Offset(-delta * w, 0),
                child: child,
              );
            }
            return _withLeftEdgeShadow(child!, (1 - delta).clamp(0.0, 1.0));
          },
        );
      },
    );
  }

  Widget _withLeftEdgeShadow(Widget child, double intensity) {
    if (intensity <= 0.01) return child;
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 18,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.22 * intensity),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 相邻章边界页；正文未就绪时显示加载态 / 失败可重试。
  Widget _boundaryFrame(int chapterIdx, {required bool atEnd}) {
    final List<ReaderPage>? pages = controller.pagesFor(chapterIdx);
    if (pages == null) {
      return ReaderStatusPage(
        theme: theme,
        error: controller.hasError(chapterIdx),
        onRetry: () => controller.retry(chapterIdx),
      );
    }
    // 付费章只展示首页：边界预览也固定首页，避免露出被隐藏的付费正文。
    final int pageIdx = (!controller.chapterLocked(chapterIdx) && atEnd)
        ? (pages.isEmpty ? 0 : pages.length - 1)
        : 0;
    return _frame(chapterIdx, pages, pageIdx);
  }

  Widget _frame(int chapterIdx, List<ReaderPage> pages, int pageIdx) {
    final ReaderPage pageContent = (pageIdx >= 0 && pageIdx < pages.length)
        ? pages[pageIdx]
        : const <ReaderBlock>[];
    final Widget content = ReaderPageContent(
      theme: theme,
      config: config,
      bookTitle: controller.manifest.title,
      chapterTitle: controller.chapterTitleAt(chapterIdx),
      page: pageContent,
      isChapterHead: pageIdx == 0,
      chapterIndex: chapterIdx,
      chapterCount: controller.chapterCount,
      pageIndex: pageIdx,
      pageCount: pages.length,
      progress: controller.progressFor(chapterIdx, pages, pageIdx),
      pageStartOffset: controller.startOffsetOfPageIn(pages, pageIdx),
      leadingParagraphStart:
          controller.leadingParagraphStartIn(pages, pageIdx),
    );
    return _maybeLock(chapterIdx, pageIdx, content);
  }

  /// 付费章首页（pageIdx==0）叠加解锁块；其余原样返回。
  Widget _maybeLock(int chapterIdx, int pageIdx, Widget content) {
    if (pageIdx != 0 ||
        !controller.chapterLocked(chapterIdx) ||
        controller.chapterLockBuilder == null) {
      return content;
    }
    return ReaderLockedPage(
      theme: theme,
      lockBlock: controller.chapterLockBuilder!(
        context,
        theme,
        controller.lockInfoFor(chapterIdx),
      ),
      child: content,
    );
  }
}
