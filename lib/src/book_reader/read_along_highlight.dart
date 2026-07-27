part of '../book_reader_widget.dart';

/// 跟读（听书）高亮能力。
///
/// 在指定章正文里顺序定位当前朗读句，记录其章 + 章内 `[start,end)` 区间供
/// [ReaderReadingScope] 渲染高亮，并把视图翻到该句所在页。抽成 mixin 让朗读
/// 定位的游标与缓存不再散落在主 [State] 里。
mixin _ReadAlongHighlight on State<BookReader> {
  // 由宿主 State 提供内部翻页控制器。
  ReadingController? get _controller;

  /// 当前朗读句所在章 + 章内 `[start,end)` 区间；-1 表示无高亮。
  int _readCh = -1;
  int _readStart = -1;
  int _readEnd = -1;

  /// 跟读定位游标（同章内顺序搜索，避免重复句定位到开头）与章内正文缓存。
  int _readCursorCh = -1;
  int _readCursor = 0;
  int _readTextCh = -1;
  String _readText = '';

  /// 跟读：在第 [ci] 章正文里顺序定位 [sentence]，高亮并翻到其所在页。
  void _markReading(int ci, String sentence) {
    final ReadingController? c = _controller;
    final String s = sentence.trim();
    if (c == null || s.isEmpty) return;
    final List<ReaderPage>? pages = c.pagesFor(ci);
    if (pages == null || pages.isEmpty) return;

    // 本章「块长度空间」全文（缓存，避免每句重建大字符串）。
    if (ci != _readTextCh) {
      final StringBuffer buf = StringBuffer();
      for (final ReaderPage page in pages) {
        for (final ReaderBlock b in page) {
          buf.write(b.text);
        }
      }
      _readText = buf.toString();
      _readTextCh = ci;
    }
    final String text = _readText;
    final int from =
        ci == _readCursorCh ? _readCursor.clamp(0, text.length) : 0;
    int idx = text.indexOf(s, from);
    if (idx < 0) idx = text.indexOf(s); // 回退从头找（如新的一章 / 循环）
    if (idx < 0) return;
    final int start = idx;
    final int end = idx + s.length;
    _readCursorCh = ci;
    _readCursor = end;

    // 定位到 start 所在页；跨章则加载该章。
    int target = 0;
    for (int p = 0; p < pages.length; p++) {
      final int ps = c.startOffsetOfPageIn(pages, p);
      final int pe =
          p + 1 < pages.length ? c.startOffsetOfPageIn(pages, p + 1) : 1 << 30;
      if (start >= ps && start < pe) {
        target = p;
        break;
      }
    }
    if (ci != c.chapterIndex) {
      c.loadChapter(ci, charOffset: start);
    } else if (target != c.pageIndex) {
      c.goToPage(target);
    }
    setState(() {
      _readCh = ci;
      _readStart = start;
      _readEnd = end;
    });
  }

  /// 清除跟读高亮与定位游标。
  void _clearReadingMark() {
    _readCursorCh = -1;
    _readCursor = 0;
    if (_readCh == -1 && _readStart == -1) return;
    setState(() {
      _readCh = -1;
      _readStart = -1;
      _readEnd = -1;
    });
  }
}
