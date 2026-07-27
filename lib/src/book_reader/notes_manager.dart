part of '../book_reader_widget.dart';

/// 笔记数据能力：书签 / 划线 / 评论的会话内权威副本与增删，变更后写回对应 store。
///
/// 三类数据各持有一份不可变副本，改动即整体替换并触发 [setState]，供
/// [ReaderUnderlineScope] / [ReaderSegmentScope] 等重建子树。抽成 mixin 让主
/// [State] 不再夹带持久化细节。
mixin _ReaderNotesManager on State<BookReader> {
  // 由宿主 State 提供内部翻页控制器。
  ReadingController? get _controller;

  /// 当前书籍的书签（变更后写回 [BookReader.bookmarkStore]）。
  List<Bookmark> _bookmarks = <Bookmark>[];

  /// 当前书籍的划线（不可变引用整体替换，供 [ReaderUnderlineScope] 刷新子树）。
  List<Underline> _underlines = const <Underline>[];

  /// 当前书籍的评论（变更后写回 [BookReader.commentStore]）。
  List<Comment> _comments = const <Comment>[];

  // —— 书签 ——

  /// 当前页（起始偏移落在本页区间内）已有的书签；没有则为 null。
  Bookmark? _bookmarkOnCurrentPage() {
    final ReadingController? c = _controller;
    if (c == null || c.pages.isEmpty) return null;
    final int start = c.startOffsetOfPage(c.pageIndex);
    final int end = c.pageIndex + 1 < c.pages.length
        ? c.startOffsetOfPage(c.pageIndex + 1)
        : 1 << 30;
    for (final Bookmark b in _bookmarks) {
      if (b.chapterIndex == c.chapterIndex &&
          b.charOffset >= start &&
          b.charOffset < end) {
        return b;
      }
    }
    return null;
  }

  bool get _isBookmarked => _bookmarkOnCurrentPage() != null;

  /// 加入 / 移除当前页书签（已存在则移除，否则新增），并写回存储。
  void _toggleBookmark() {
    final ReadingController c = _controller!;
    final Bookmark? existing = _bookmarkOnCurrentPage();
    final List<Bookmark> next = List<Bookmark>.of(_bookmarks);
    if (existing != null) {
      next.removeWhere((Bookmark b) => b.key == existing.key);
    } else {
      next.add(Bookmark(
        chapterIndex: c.chapterIndex,
        charOffset: c.startOffsetOfPage(c.pageIndex),
        chapterTitle: c.currentChapterTitle,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    setState(() => _bookmarks = next);
    widget.bookmarkStore.save(c.manifest.id, next);
    // 书签状态变了，通知控制器让宿主自定义 UI 同步。
    widget.controller?.notifyPositionChanged();
  }

  /// 删除一条书签，并写回存储。
  void _deleteBookmark(Bookmark b) {
    final ReadingController c = _controller!;
    final List<Bookmark> next = List<Bookmark>.of(_bookmarks)
      ..removeWhere((Bookmark e) => e.key == b.key);
    setState(() => _bookmarks = next);
    widget.bookmarkStore.save(c.manifest.id, next);
  }

  // —— 划线 ——

  /// 新增一条划线（去重同区间），补全标题/时间后写回存储。
  void _addUnderline(int chapterIndex, int start, int end, String text) {
    final ReadingController c = _controller!;
    final Underline u = Underline(
      chapterIndex: chapterIndex,
      start: start,
      end: end,
      text: text,
      chapterTitle: c.chapterTitleAt(chapterIndex),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final List<Underline> next = List<Underline>.of(_underlines)
      ..removeWhere((Underline e) => e.key == u.key)
      ..add(u);
    setState(() => _underlines = List<Underline>.unmodifiable(next));
    widget.underlineStore.save(c.manifest.id, next);
  }

  /// 删除若干条划线，并写回存储。
  void _removeUnderlines(List<Underline> targets) {
    if (targets.isEmpty) return;
    final ReadingController c = _controller!;
    final Set<String> keys = targets.map((Underline u) => u.key).toSet();
    final List<Underline> next = List<Underline>.of(_underlines)
      ..removeWhere((Underline e) => keys.contains(e.key));
    setState(() => _underlines = List<Underline>.unmodifiable(next));
    widget.underlineStore.save(c.manifest.id, next);
  }

  // —— 评论 ——

  /// 删除若干条评论，并写回存储。
  void _removeComments(List<Comment> targets) {
    if (targets.isEmpty) return;
    final ReadingController c = _controller!;
    final Set<String> keys = targets.map((Comment e) => e.key).toSet();
    final List<Comment> next = List<Comment>.of(_comments)
      ..removeWhere((Comment e) => keys.contains(e.key));
    setState(() => _comments = List<Comment>.unmodifiable(next));
    widget.commentStore.save(c.manifest.id, next);
  }

  /// 业务方在外部改动评论后触发 [BookReader.commentsRefresh]，据此重新拉取评论，
  /// 刷新段尾角标与笔记列表数据。
  Future<void> _reloadComments() async {
    final ReadingController? c = _controller;
    if (c == null) return;
    try {
      final List<Comment> latest =
          await widget.commentStore.load(c.manifest.id);
      if (mounted) {
        setState(() => _comments = List<Comment>.unmodifiable(latest));
      }
    } catch (_) {
      // 读取失败保持现有内存副本
    }
  }
}
