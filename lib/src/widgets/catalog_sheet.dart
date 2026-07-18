import 'package:flutter/material.dart';

import '../bookmark/reader_bookmark_store.dart';
import '../progress/reader_progress_store.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';

/// 书籍信息抽屉：顶部为书籍信息区（封面 + 书名 + 作者），下方分「详情 / 目录 / 书签」
/// 三个可点击切换、也可左右滑动的标签页。详情页展示简介，目录页点击某章跳转，
/// 书签页点击某条书签跳转到其记录位置。
///
/// 点击章节或书签均通过 [Navigator.pop] 返回一个 [ReadingPosition]（章 + 偏移）。
class CatalogSheet extends StatefulWidget {
  const CatalogSheet({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.intro,
    required this.coverColor,
    required this.chapterTitles,
    required this.currentIndex,
    required this.theme,
    this.bookmarks = const <Bookmark>[],
    this.scrollController,
  });

  final String bookTitle;
  final String author;
  final String intro;
  final Color coverColor;
  final List<String> chapterTitles;
  final int currentIndex;
  final ReaderTheme theme;

  /// 书签列表（展示于「书签」标签页）
  final List<Bookmark> bookmarks;

  /// 外部滚动控制器（如 [DraggableScrollableSheet] 提供的）；为空时内部自建。
  /// 会绑定到「目录」列表，使列表滚到顶部后继续下拉可关闭整个面板。
  final ScrollController? scrollController;

  @override
  State<CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<CatalogSheet>
    with SingleTickerProviderStateMixin {
  static const double _itemExtent = 52;

  late final TabController _tab = TabController(
    length: 3,
    initialIndex: 1, // 默认落在「目录」（入口即目录按钮）
    vsync: this,
  );

  /// 仅在未外部提供控制器时创建，负责其生命周期。
  ScrollController? _own;
  ScrollController get _listController => widget.scrollController ?? _own!;

  /// 是否倒序展示（true 时列表从末章到首章）。
  bool _descending = false;

  int get _count => widget.chapterTitles.length;

  int _displayPos(int chapterIndex) =>
      _descending ? _count - 1 - chapterIndex : chapterIndex;

  int _chapterAt(int displayPos) =>
      _descending ? _count - 1 - displayPos : displayPos;

  double _offsetFor(int displayPos) =>
      (displayPos * _itemExtent - 200).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    final double target = _offsetFor(_displayPos(widget.currentIndex));
    if (widget.scrollController == null) {
      _own = ScrollController(initialScrollOffset: target);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
    }
  }

  void _jumpToCurrent() {
    if (!mounted || !_listController.hasClients) return;
    final double target = _offsetFor(_displayPos(widget.currentIndex));
    _listController.jumpTo(
      target.clamp(0, _listController.position.maxScrollExtent),
    );
  }

  void _toggleOrder() {
    setState(() => _descending = !_descending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  @override
  void dispose() {
    _tab.dispose();
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    final Color text = widget.theme.textColor;
    final Color sub = widget.theme.subTextColor;
    final Color accent = widget.theme.accentColor;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(text, sub),
          _buildTabBar(labels, sub, accent),
          Divider(height: 1, color: text.withValues(alpha: 0.08)),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: <Widget>[
                _buildDetail(labels, text, sub),
                _buildCatalog(labels, text, sub, accent),
                _buildBookmarks(labels, text, sub, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 顶部：封面 + 书名 + 作者
  Widget _buildHeader(Color text, Color sub) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCover(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(
                  widget.bookTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: text,
                  ),
                ),
                if (widget.author.isNotEmpty)
                  Text(
                    widget.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: sub),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return Container(
      width: 54,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            widget.coverColor,
            widget.coverColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Text(
        widget.bookTitle,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  // 详情 / 目录 标签栏（左对齐，可点击；配合 TabBarView 支持左右滑动切换）
  Widget _buildTabBar(ReaderLabels labels, Color sub, Color accent) {
    return TabBar(
      controller: _tab,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: accent,
      unselectedLabelColor: sub,
      indicatorColor: accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      tabs: <Widget>[
        Tab(text: labels.detail),
        Tab(text: labels.catalog),
        Tab(text: labels.bookmarkTab),
      ],
    );
  }

  // 详情：书籍简介
  Widget _buildDetail(ReaderLabels labels, Color text, Color sub) {
    final String intro = widget.intro.trim();
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Text(
        intro.isEmpty ? labels.noIntro : intro,
        style: TextStyle(
          fontSize: 15,
          height: 1.7,
          color: intro.isEmpty ? sub : text.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  // 目录：章节数 + 正序/倒序切换 + 章节列表
  Widget _buildCatalog(
    ReaderLabels labels,
    Color text,
    Color sub,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildOrderBar(labels, sub, accent),
        Expanded(child: _buildList(text, accent)),
      ],
    );
  }

  Widget _buildOrderBar(ReaderLabels labels, Color sub, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            labels.chapterTotal(_count),
            style: TextStyle(fontSize: 13, color: sub),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _toggleOrder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.swap_vert, size: 18, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    _descending ? labels.orderDesc : labels.orderAsc,
                    style: TextStyle(
                      fontSize: 13,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color text, Color accent) {
    return ListView.builder(
      controller: _listController,
      itemCount: _count,
      itemExtent: _itemExtent,
      itemBuilder: (BuildContext context, int pos) {
        final int index = _chapterAt(pos);
        final bool active = index == widget.currentIndex;
        return InkWell(
          onTap: () =>
              Navigator.of(context).pop(ReadingPosition(chapterIndex: index)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.chapterTitles[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: active ? accent : text.withValues(alpha: 0.85),
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (active)
                  Icon(Icons.play_arrow_rounded, size: 18, color: accent),
              ],
            ),
          ),
        );
      },
    );
  }

  // 书签：记录的章 + 章节名 + 记录时间；点击跳转到记录位置。按记录时间倒序（最近在前）。
  Widget _buildBookmarks(
    ReaderLabels labels,
    Color text,
    Color sub,
    Color accent,
  ) {
    if (widget.bookmarks.isEmpty) {
      return Center(
        child: Text(
          labels.noBookmarks,
          style: TextStyle(fontSize: 14, color: sub),
        ),
      );
    }
    final List<Bookmark> items = List<Bookmark>.of(widget.bookmarks)
      ..sort((Bookmark a, Bookmark b) => b.createdAt.compareTo(a.createdAt));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: text.withValues(alpha: 0.06)),
      itemBuilder: (BuildContext context, int i) {
        final Bookmark b = items[i];
        return InkWell(
          onTap: () => Navigator.of(context).pop(
            ReadingPosition(
              chapterIndex: b.chapterIndex,
              charOffset: b.charOffset,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(Icons.bookmark, size: 18, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '第 ${b.chapterIndex + 1} 章 · ${b.chapterTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: text.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(b.createdAt),
                        style: TextStyle(fontSize: 12, color: sub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 时间戳（毫秒）格式化为 “yyyy-MM-dd HH:mm”。
  static String _formatTime(int ms) {
    if (ms <= 0) return '';
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}
