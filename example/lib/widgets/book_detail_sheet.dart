import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../data/db/app_database.dart';
import '../l10n/app_localizations.dart';
import '../theme/warm_theme.dart';
import 'book_cover.dart';

/// 从详情弹窗返回的「去阅读」意图；[startChapter] 为空表示从上次位置/开头读起。
class ReadIntent {
  const ReadIntent(this.startChapter);
  final int? startChapter;
}

/// 书籍详情弹窗（详情 / 目录 / 书签），遵循「暖纸」设计。
///
/// 数据来自 drift 的轻量 [BookRow]（不含正文）；目录标题通过 [source] 懒加载，
/// 不把整本书装进内存。交互对齐阅读器目录抽屉：可拖拽下拉关闭、标签可滑动切换。
class BookDetailSheet extends StatefulWidget {
  const BookDetailSheet({
    super.key,
    required this.book,
    required this.source,
    required this.progress,
    required this.position,
    required this.bookmarkStore,
    required this.scrollController,
  });

  final BookRow book;
  final BookSource source;
  final double progress;
  final ReadingPosition? position;
  final ReaderBookmarkStore bookmarkStore;
  final ScrollController scrollController;

  static Future<ReadIntent?> show(
    BuildContext context, {
    required BookRow book,
    required BookSource source,
    required double progress,
    required ReadingPosition? position,
    required ReaderBookmarkStore bookmarkStore,
  }) {
    return showModalBottomSheet<ReadIntent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (BuildContext ctx, ScrollController controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: ColoredBox(
            color: Warm.sheet,
            child: BookDetailSheet(
              book: book,
              source: source,
              progress: progress,
              position: position,
              bookmarkStore: bookmarkStore,
              scrollController: controller,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<BookDetailSheet>
    with SingleTickerProviderStateMixin {
  static const double _chapterExtent = 56;

  late final TabController _tab = TabController(length: 3, vsync: this)
    ..addListener(_onTab);

  final ScrollController _detailCtrl = ScrollController();
  final ScrollController _markCtrl = ScrollController();

  bool _asc = true;

  /// 章节标题（懒加载），null 表示尚未加载完成。
  List<String>? _titles;

  List<Bookmark> _bookmarks = const <Bookmark>[];
  bool _marksLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTitles();
    _loadMarks();
  }

  @override
  void dispose() {
    _tab.dispose();
    _detailCtrl.dispose();
    _markCtrl.dispose();
    super.dispose();
  }

  void _onTab() {
    if (!_tab.indexIsChanging && _tab.index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
    }
    setState(() {});
  }

  Future<void> _loadTitles() async {
    List<String> titles = const <String>[];
    try {
      titles = (await widget.source.loadManifest()).chapterTitles;
    } catch (_) {
      // 忽略，按空目录处理
    }
    if (!mounted) return;
    setState(() => _titles = titles);
    if (_tab.index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
    }
  }

  Future<void> _loadMarks() async {
    List<Bookmark> m = const <Bookmark>[];
    try {
      m = await widget.bookmarkStore.load(widget.book.id);
    } catch (_) {
      // 读取失败按「无书签」处理
    }
    if (!mounted) return;
    setState(() {
      _bookmarks = List<Bookmark>.of(m)
        ..sort((Bookmark a, Bookmark b) => b.createdAt.compareTo(a.createdAt));
      _marksLoaded = true;
    });
  }

  AppLocalizations get _l => AppLocalizations.of(context);

  int? get _curChapter => widget.position?.chapterIndex;

  void _jumpToCurrent() {
    final int? cur = _curChapter;
    final List<String>? titles = _titles;
    if (cur == null || titles == null || !widget.scrollController.hasClients) {
      return;
    }
    final int pos = _asc ? cur : titles.length - 1 - cur;
    final double target = (pos * _chapterExtent - 200).clamp(
      0.0,
      widget.scrollController.position.maxScrollExtent,
    );
    widget.scrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _grabber(),
          _headerRow(),
          _tabBar(),
          const Divider(height: 1, color: Color(0x1F785A3C)),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: <Widget>[_detail(), _toc(), _marks()],
            ),
          ),
          _readBar(),
        ],
      ),
    );
  }

  Widget _grabber() => Padding(
    padding: const EdgeInsets.only(top: 11, bottom: 4),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0x40785A3C),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  Widget _headerRow() {
    final BookRow b = widget.book;
    final String status = b.imported
        ? _l.statusLocalImported
        : _l.statusBuiltin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
      child: Row(
        children: <Widget>[
          BookCover(
            title: b.title,
            color: Color(b.coverColor),
            width: 56,
            height: 78,
            fontSize: 12,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  b.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Warm.serif(size: 22, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${b.author} · $status',
                  style: Warm.sans(size: 13, color: Warm.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0x1A785A3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF8A7C6A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    final TextStyle label = Warm.serif(size: 16, weight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Warm.accent,
        unselectedLabelColor: Warm.muted2,
        indicatorColor: Warm.accent,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelStyle: label,
        unselectedLabelStyle: label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: <Widget>[
          Tab(text: _l.tabDetail),
          Tab(text: _l.tabToc),
          Tab(text: _l.tabBookmarks),
        ],
      ),
    );
  }

  // ————————————————————— 详情 —————————————————————

  Widget _detail() {
    final BookRow b = widget.book;
    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Warm.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: Warm.serif(
                size: 18,
                weight: FontWeight.w700,
                color: Warm.accent,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: Warm.sans(size: 11, color: Warm.muted)),
          ],
        ),
      ),
    );

    return ListView(
      controller: _detailCtrl,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            stat('${b.chapterCount}', _l.statChapters),
            const SizedBox(width: 10),
            stat(b.imported ? _l.sourceLocal : _l.sourceBuiltin, _l.statSource),
            const SizedBox(width: 10),
            stat('${(widget.progress * 100).round()}%', _l.statProgress),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          _l.introHeading,
          style: Warm.serif(size: 15, weight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        Text(
          b.intro.isEmpty ? _l.noIntro : b.intro,
          style: Warm.sans(
            size: 15,
            height: 1.95,
            color: const Color(0xFF4A4038),
          ),
        ),
      ],
    );
  }

  // ————————————————————— 目录 —————————————————————

  Widget _toc() {
    final List<String>? all = _titles;
    if (all == null) {
      return const Center(child: CircularProgressIndicator(color: Warm.accent));
    }
    final List<int> order = List<int>.generate(all.length, (int i) => i);
    if (!_asc) order.setAll(0, order.reversed.toList());
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _l.chapterCountLabel(all.length),
                style: Warm.sans(size: 13, color: Warm.muted),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _asc = !_asc);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _jumpToCurrent(),
                  );
                },
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.swap_vert, size: 15, color: Warm.accent),
                    const SizedBox(width: 5),
                    Text(
                      _asc ? _l.orderAsc : _l.orderDesc,
                      style: Warm.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Warm.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: order.length,
            itemExtent: _chapterExtent,
            itemBuilder: (BuildContext _, int i) {
              final int index = order[i];
              final bool active = index == _curChapter;
              return InkWell(
                onTap: () => Navigator.of(context).pop(ReadIntent(index)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          all[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Warm.sans(
                            size: 15,
                            height: 1.4,
                            weight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? Warm.accent : Warm.ink,
                          ),
                        ),
                      ),
                      if (active) ...<Widget>[
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: Warm.accent,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ————————————————————— 书签 —————————————————————

  Widget _marks() {
    if (!_marksLoaded) {
      return const Center(child: CircularProgressIndicator(color: Warm.accent));
    }
    if (_bookmarks.isEmpty) {
      return ListView(
        controller: _markCtrl,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 30),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.bookmark_border,
                  size: 46,
                  color: Color(0xFFCDBCA5),
                ),
                const SizedBox(height: 16),
                Text(
                  _l.noBookmarks,
                  style: Warm.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: Warm.muted2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _l.noBookmarksHint,
                  textAlign: TextAlign.center,
                  style: Warm.sans(
                    size: 12.5,
                    height: 1.6,
                    color: const Color(0xFFB5A894),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      controller: _markCtrl,
      itemCount: _bookmarks.length,
      itemBuilder: (BuildContext _, int i) {
        final Bookmark m = _bookmarks[i];
        return InkWell(
          onTap: () => Navigator.of(context).pop(ReadIntent(m.chapterIndex)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x17785A3C))),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.bookmark, size: 18, color: Warm.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _l.bookmarkEntry(m.chapterIndex + 1, m.chapterTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Warm.sans(size: 14.5, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(m.createdAt),
                        style: Warm.sans(size: 12, color: Warm.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Warm.muted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _readBar() {
    final bool started = widget.progress > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      color: Warm.sheet,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(ReadIntent(_curChapter)),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: Warm.btnGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFA94E26).withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                started ? _l.continueReading : _l.startReading,
                style: Warm.sans(
                  size: 16,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int ms) {
    if (ms <= 0) return '';
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
