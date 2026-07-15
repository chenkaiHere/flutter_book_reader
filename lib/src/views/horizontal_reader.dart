import 'package:flutter/material.dart';

import '../paginator.dart';
import '../widgets/loading_page.dart';
import '../widgets/page_frame.dart';
import 'reader_mode_view.dart';

/// 横向滑动翻页视图。
///
/// 页序：[上一章末页?] + 本章各页 + [下一章首页?]。边界页直接渲染相邻章的
/// 真实页面，滑过去内容即目标章，切章在后台完成、前后画面一致，因此无跳动。
class HorizontalReader extends ReaderModeView {
  const HorizontalReader({super.key, required super.controller});

  @override
  State<HorizontalReader> createState() => _HorizontalReaderState();
}

class _HorizontalReaderState extends ReaderModeViewState<HorizontalReader> {
  late PageController _pageController;
  late int _builtChapter;

  @override
  void initState() {
    super.initState();
    _builtChapter = controller.chapterIndex;
    _pageController = PageController(
      initialPage: controller.leading + controller.pageIndex,
    );
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
    final int target = controller.leading + controller.pageIndex;
    if (controller.chapterIndex != _builtChapter) {
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
    final int itemCount =
        controller.leading + controller.pages.length + trailing;

    return PageView.builder(
      key: ValueKey<int>(controller.chapterIndex),
      controller: _pageController,
      itemCount: itemCount,
      onPageChanged: (int v) {
        final int real = v - controller.leading;
        if (real < 0) {
          _deferCross(controller.chapterIndex - 1, atEnd: true);
        } else if (real >= controller.pages.length) {
          _deferCross(controller.chapterIndex + 1);
        } else {
          controller.goToPage(real);
        }
      },
      itemBuilder: (BuildContext context, int v) {
        final int real = v - controller.leading;
        if (real < 0) {
          return _boundaryFrame(controller.chapterIndex - 1, atEnd: true);
        }
        if (real >= controller.pages.length) {
          return _boundaryFrame(controller.chapterIndex + 1, atEnd: false);
        }
        return _frame(controller.chapterIndex, controller.pages, real);
      },
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
    final int pageIdx = atEnd ? (pages.isEmpty ? 0 : pages.length - 1) : 0;
    return _frame(chapterIdx, pages, pageIdx);
  }

  Widget _frame(int chapterIdx, List<ReaderPage> pages, int pageIdx) {
    final ReaderPage pageContent = (pageIdx >= 0 && pageIdx < pages.length)
        ? pages[pageIdx]
        : const <ReaderBlock>[];
    return ReaderPageFrame(
      theme: theme,
      config: config,
      chapterTitle: controller.chapterTitleAt(chapterIdx),
      page: pageContent,
      chapterIndex: chapterIdx,
      chapterCount: controller.chapterCount,
      pageIndex: pageIdx,
      pageCount: pages.length,
      progress: controller.progressFor(chapterIdx, pages, pageIdx),
      padding: pagePadding,
    );
  }
}
