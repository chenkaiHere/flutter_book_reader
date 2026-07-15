import 'chapter_content_mixin.dart';
import 'reader_controller_base.dart';

/// 纵向连续滚动的章节流能力（上下滚动模式使用）。
mixin VerticalFlowMixin on ReaderControllerBase, ChapterContentMixin {
  /// 临近底部时接上下一章，返回是否发生追加。
  bool appendNextFlowChapter() {
    final int last = flowChapters.last;
    if (last < chapterCount - 1 && !flowChapters.contains(last + 1)) {
      flowChapters.add(last + 1);
      ensureLoaded(last + 1);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 临近顶部时接上上一章（返回被插入的章序号，无则 null）；位置补偿由视图完成。
  int? prependPrevFlowChapter() {
    final int first = flowChapters.first;
    if (first > 0 && !flowChapters.contains(first - 1)) {
      final int inserted = first - 1;
      flowChapters.insert(0, inserted);
      ensureLoaded(inserted);
      notifyListeners();
      return inserted;
    }
    return null;
  }

  /// 纵向滚动时根据视口所处章节更新“当前章”。
  void setCurrentChapter(int index) {
    if (index != chapterIndex) {
      chapterIndex = index;
      signature = ''; // 切回横向模式时按当前章重新分页
      prefetchAround(index);
      notifyListeners();
    }
  }
}
