import '../paginator.dart';
import 'chapter_content_mixin.dart';
import 'pagination_mixin.dart';
import 'reader_controller_base.dart';

/// 翻页与切章能力（横向/无动画模式使用）。
mixin ChapterNavigationMixin
    on ReaderControllerBase, ChapterContentMixin, PaginationMixin {
  /// 加载某章。[atEnd] 为 true 时定位到该章最后一页（向前翻入）。
  /// 返回横向 PageView 应使用的初始页索引（含 leading 偏移）。
  int loadChapter(int index, {bool atEnd = false}) {
    final int clamped = index.clamp(0, chapterCount - 1);
    final int leadingOf = clamped > 0 ? 1 : 0;
    int start = 0;
    if (atEnd) {
      final List<ReaderPage>? p = pagesFor(clamped);
      if (p != null && p.isNotEmpty) start = p.length - 1;
    }
    chapterIndex = clamped;
    charOffset = 0;
    pendingAtEnd = atEnd;
    signature = '';
    pageIndex = start;
    flowChapters = <int>[clamped];
    prefetchAround(clamped);
    notifyListeners();
    return leadingOf + start;
  }

  /// 定位到本章某页（点按/滑动跨页）。
  void goToPage(int index) {
    pageIndex = index.clamp(0, pages.isEmpty ? 0 : pages.length - 1);
    charOffset = startOffsetOfPage(pageIndex);
    notifyListeners();
  }

  void nextPage() {
    if (pageIndex < pages.length - 1) {
      goToPage(pageIndex + 1);
    } else if (hasNext) {
      loadChapter(chapterIndex + 1);
    }
  }

  void prevPage() {
    if (pageIndex > 0) {
      goToPage(pageIndex - 1);
    } else if (hasPrev) {
      loadChapter(chapterIndex - 1, atEnd: true);
    }
  }

  double get globalProgress => progressFor(chapterIndex, pages, pageIndex);
}
